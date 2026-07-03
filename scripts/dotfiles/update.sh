#!/usr/bin/env bash
# update.sh — one command to update every managed layer of these dotfiles.
#
# Components:
#   mise      Upgrade mise-managed CLIs/runtimes and refresh the source lockfile.
#   casks     Converge and upgrade nanobrew/Homebrew GUI apps and fonts (macOS).
#   formulae  Converge and upgrade nanobrew/Homebrew exceptional formulae (macOS).
#   plugins   Register/update Claude Code marketplaces and enabled plugins.
#   skills    Report vendored agent-skill drift vs upstream (apply via /sync-skills).
#   codex     Upgrade just the Codex CLI via mise (subset of `mise`).
#   pi        Upgrade just the pi coding agent via mise (subset of `mise`).
#   self      git pull --ff-only, then re-apply mise dotfiles to $HOME.
#   all       Everything above in a safe order (default).
#
# Each component mutates its own store, not just tracked files: `mise` upgrades
# installed tools and refreshes the source lockfile, `casks`/`formulae` update
# installed apps, `plugins` updates Claude's plugin state under $HOME, `skills`
# only reports. Only `self` re-applies managed dotfiles to $HOME (via
# `mise dotfiles apply`, which won't overwrite whole-file targets without --force).
#
# Usage:
#   scripts/dotfiles/update.sh [--check] [COMPONENT ...]
#   just update            # all
#   just update mise       # one component
#   just update-check      # non-mutating preview of all components

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

CHECK_ONLY=false
COMPONENTS=()

CODEX_MISE_TOOL="npm:@openai/codex"
PI_MISE_TOOL="npm:@earendil-works/pi-coding-agent"

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/update.sh [--check] [COMPONENT ...]

Update every managed layer of these dotfiles with one interface.

Components: all (default) mise casks formulae plugins skills codex pi self

Options:
  --check   Non-mutating preview: show what each component would change.
  -h|--help Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check | --dry-run)
      CHECK_ONLY=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    all | mise | casks | formulae | plugins | skills | codex | pi | self)
      COMPONENTS+=("$1")
      shift
      ;;
    *)
      error "unknown component or option: $1"
      usage >&2
      exit 2
      ;;
  esac
done

if [[ ${#COMPONENTS[@]} -eq 0 ]]; then
  COMPONENTS=(all)
fi

# --- helpers ---------------------------------------------------------------

versions_script() { printf '%s/versions.sh' "${SCRIPT_DIR}"; }

bundle_package_names() {
  # Print bare package names from a Brewfile for a given kind (brew|cask).
  local file="$1" kind="$2"
  [[ -r "${file}" ]] || return 0
  sed -nE "s/^[[:space:]]*${kind}[[:space:]]+\"([^\"]+)\".*/\1/p" "${file}"
}

# --- components ------------------------------------------------------------

update_mise() {
  # ${arr[@]+"${arr[@]}"} is the Bash-3.2-safe empty-array expansion the rest of
  # this repo uses: a bare "${tool_args[@]}" on an empty array aborts under set -u.
  local -a tool_args=("$@")
  if [[ "${CHECK_ONLY}" == true ]]; then
    log "mise: checking outdated tools and lock refresh"
    bash "$(versions_script)" --check ${tool_args[@]+"${tool_args[@]}"}
  else
    log "mise: upgrading tools and refreshing source lockfile"
    bash "$(versions_script)" --write ${tool_args[@]+"${tool_args[@]}"}
  fi
}

update_codex() { update_mise "${CODEX_MISE_TOOL}"; }
update_pi() { update_mise "${PI_MISE_TOOL}"; }

update_bundle() {
  # $1 = human title, $2 = Brewfile path, $3 = kind (cask|brew)
  local title="$1" bundle="$2" kind="$3"
  is_macos || {
    info "${title}: skipping on $(os_name) (macOS-only bundle)"
    return 0
  }
  [[ -r "${bundle}" ]] || {
    warn "${title}: bundle not found: ${bundle#"${DOTFILES_ROOT}"/}"
    return 0
  }

  # Prefer nanobrew; both read the same Brewfile. Export the nanobrew bin in this
  # function's own scope so later nb/brew calls resolve — a command-substitution
  # helper would lose the PATH change to its subshell.
  export PATH="${NANOBREW_BIN_DIR:-/opt/nanobrew/prefix/bin}:${PATH}"
  local pm=""
  if have nb; then
    pm="nb"
  elif have brew; then
    pm="brew"
  else
    warn "${title}: neither nanobrew (nb) nor Homebrew (brew) is available"
    return 0
  fi

  local -a names=()
  while IFS= read -r n; do [[ -n "${n}" ]] && names+=("${n}"); done \
    < <(bundle_package_names "${bundle}" "${kind}")

  if [[ "${CHECK_ONLY}" == true ]]; then
    log "${title}: outdated report via ${pm}"
    case "${pm}" in
      nb) nb outdated 2>/dev/null || info "${title}: nanobrew has no outdated report; would converge bundle" ;;
      brew)
        if [[ "${kind}" == "cask" ]]; then brew outdated --cask ${names[@]+"${names[@]}"} 2>/dev/null || true;
        else brew outdated --formula ${names[@]+"${names[@]}"} 2>/dev/null || true; fi
        ;;
    esac
    return 0
  fi

  log "${title}: converging bundle via ${pm}"
  case "${pm}" in
    nb)
      nb bundle install "${bundle}"
      nb upgrade 2>/dev/null || info "${title}: nanobrew upgrade unavailable; bundle converged only"
      ;;
    brew)
      brew bundle install --file="${bundle}" || warn "${title}: brew bundle reported issues"
      if [[ ${#names[@]} -gt 0 ]]; then
        log "${title}: upgrading ${#names[@]} package(s)"
        if [[ "${kind}" == "cask" ]]; then
          brew upgrade --cask "${names[@]}" 2>/dev/null || info "${title}: nothing to upgrade"
        else
          brew upgrade --formula "${names[@]}" 2>/dev/null || info "${title}: nothing to upgrade"
        fi
      fi
      ;;
  esac
}

update_casks() {
  update_bundle "casks" "${DOTFILES_ROOT}/install/macos/common/nanobrew-casks.Brewfile" "cask"
}

update_formulae() {
  update_bundle "formulae" "${DOTFILES_ROOT}/install/macos/common/nanobrew-formulae.Brewfile" "brew"
}

update_plugins() {
  local agents="${DOTFILES_ROOT}/install/common/agents.sh"
  [[ -f "${agents}" ]] || {
    warn "plugins: installer not found: ${agents#"${DOTFILES_ROOT}"/}"
    return 0
  }
  if [[ "${CHECK_ONLY}" == true ]]; then
    log "plugins: reporting configured vs installed Claude plugins"
    bash "${agents}" --check
  else
    log "plugins: registering marketplaces and updating enabled plugins"
    bash "${agents}" --update
  fi
}

update_skills() {
  local sync="${DOTFILES_ROOT}/target/home/.agents/skills/sync-skills/scripts/sync.sh"
  [[ -f "${sync}" ]] || {
    warn "skills: sync-skills not found"
    return 0
  }
  log "skills: analysing vendored skills vs upstream (read-only)"
  bash "${sync}" --keep-upstream || warn "skills: sync analysis reported issues"
  info "skills: apply non-trivial merges with the /sync-skills agent workflow"
}

update_self() {
  log "self: updating the dotfiles checkout and re-applying to \$HOME"
  if [[ -n "$(git -C "${DOTFILES_ROOT}" status --porcelain 2>/dev/null)" ]]; then
    warn "self: working tree is dirty; skipping 'git pull' to avoid clobbering changes"
  elif [[ "${CHECK_ONLY}" == true ]]; then
    info "self: would run 'git pull --ff-only' then 'mise dotfiles apply'"
    git -C "${DOTFILES_ROOT}" fetch --dry-run 2>&1 | sed 's/^/  /' || true
  else
    git -C "${DOTFILES_ROOT}" pull --ff-only || warn "self: git pull --ff-only failed"
  fi

  local mise_cmd
  mise_cmd="$(mise_bin)" || {
    warn "self: mise not available; cannot apply dotfiles"
    return 0
  }
  local -a apply=(dotfiles apply)
  if [[ "${CHECK_ONLY}" == true ]]; then apply+=(--dry-run); else apply+=(--yes); fi
  MISE_EXPERIMENTAL=true \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}/mise.toml${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${mise_cmd}" -C "${DOTFILES_ROOT}" "${apply[@]}"
}

run_component() {
  case "$1" in
    mise) update_mise ;;
    codex) update_codex ;;
    pi) update_pi ;;
    casks) update_casks ;;
    formulae) update_formulae ;;
    plugins) update_plugins ;;
    skills) update_skills ;;
    self) update_self ;;
    all)
      # Order: refresh the repo, then tools, packages, agent plugins, skill
      # report, and finally re-apply managed files to $HOME.
      update_self
      update_mise
      update_casks
      update_formulae
      update_plugins
      update_skills
      ;;
    *)
      error "unknown component: $1"
      return 2
      ;;
  esac
}

main() {
  local mode="apply"
  [[ "${CHECK_ONLY}" == true ]] && mode="check"
  log "update (${mode}): ${COMPONENTS[*]}"
  local component
  for component in "${COMPONENTS[@]}"; do
    run_component "${component}"
  done
  log "update complete"
}

main "$@"
