#!/usr/bin/env bash
# update.sh — one command to update every managed layer of these dotfiles.
#
# Components:
#   mise      Upgrade mise-managed CLIs/runtimes and refresh the source lockfile.
#   casks     Converge and upgrade nanobrew GUI apps and fonts (macOS).
#   formulae  Converge and upgrade nanobrew exceptional formulae (macOS).
#   plugins   Register/update managed coding-agent marketplaces and plugins.
#   vscode    Install managed VS Code extensions that are missing.
#   skills    Report vendored agent-skill drift vs upstream (apply via /sync-skills).
#   codex     Upgrade just the Codex CLI via mise (subset of `mise`).
#   pi        Upgrade just the pi coding agent via mise (subset of `mise`).
#   agentmemory Upgrade just the agentmemory CLI via mise (subset of `mise`).
#   self      Pull, re-apply mise bootstrap dotfiles, then restore agent adapters.
#   all       Everything above in a safe order (default).
#
# Each component mutates its own store, not just tracked files: `mise` upgrades
# installed tools and refreshes the source lockfile, `casks`/`formulae` update
# installed apps, `plugins` updates managed agent plugin state under $HOME,
# `skills` only reports. Only `self` re-applies managed dotfiles to $HOME (via
# `mise bootstrap dotfiles apply`, which won't overwrite whole-file targets without --force).
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
UPDATE_FAILURES=0

CODEX_MISE_TOOL="npm:@openai/codex"
PI_MISE_TOOL="npm:@earendil-works/pi-coding-agent"
AGENTMEMORY_MISE_TOOL="npm:@agentmemory/agentmemory"

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/update.sh [--check] [COMPONENT ...]

Update every managed layer of these dotfiles with one interface.

Components: all (default) mise casks formulae plugins vscode skills codex pi agentmemory self

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
    all | mise | casks | formulae | plugins | vscode | skills | codex | pi | agentmemory | self)
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

record_failure() {
  warn "$1"
  UPDATE_FAILURES=$((UPDATE_FAILURES + 1))
}

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
update_agentmemory() { update_mise "${AGENTMEMORY_MISE_TOOL}"; }

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

  # Export the nanobrew bin in this function's own scope so later nb calls
  # resolve — a command-substitution helper would lose the PATH change to its
  # subshell.
  export PATH="${NANOBREW_BIN_DIR:-/opt/nanobrew/prefix/bin}:${PATH}"
  if ! have nb; then
    warn "${title}: nanobrew (nb) is not available; run install/macos/common/nanobrew.sh"
    return 0
  fi

  local -a names=()
  while IFS= read -r n; do [[ -n "${n}" ]] && names+=("${n}"); done \
    < <(bundle_package_names "${bundle}" "${kind}")

  if [[ "${CHECK_ONLY}" == true ]]; then
    log "${title}: outdated report via nb"
    nb outdated 2>/dev/null || info "${title}: nanobrew has no outdated report; would converge bundle"
    return 0
  fi

  log "${title}: converging bundle via nb"
  local rc=0
  # Converge the (component-scoped) bundle, then upgrade only its packages.
  # A bare `nb upgrade` would upgrade the whole nanobrew prefix, so a
  # cask-only run must not touch formulae and vice versa.
  nb bundle install "${bundle}" || { warn "${title}: nanobrew bundle did not converge"; rc=1; }
  if [[ ${#names[@]} -gt 0 ]]; then
    nb upgrade ${names[@]+"${names[@]}"} 2>/dev/null \
      || info "${title}: nanobrew per-package upgrade unavailable; bundle converged only"
  fi
  # Non-zero when the managed bundle did not converge, so `just update casks`
  # signals failure; `all` still tolerates it via `update_casks || warn`.
  return "${rc}"
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
    log "plugins: reporting configured vs installed agent plugins"
    bash "${agents}" --check
  else
    log "plugins: registering marketplaces and updating enabled agent plugins"
    bash "${agents}" --update
  fi
}

update_vscode() {
  local installer="${DOTFILES_ROOT}/install/common/vscode-extensions.sh"
  [[ -f "${installer}" ]] || {
    warn "vscode: installer not found: ${installer#"${DOTFILES_ROOT}"/}"
    return 0
  }
  if [[ "${CHECK_ONLY}" == true ]]; then
    log "vscode: reporting missing managed VS Code extensions"
    bash "${installer}" --check
  else
    log "vscode: installing missing managed VS Code extensions"
    bash "${installer}"
  fi
}

update_skills() {
  local sync="${DOTFILES_ROOT}/target/home/.agents/skills/sync-skills/scripts/sync.sh"
  [[ -f "${sync}" ]] || {
    warn "skills: sync-skills not found"
    return 0
  }
  # No --keep-upstream: this is a report; the interactive /sync-skills workflow
  # is what retains upstream clones for inspection. Keeping them here would leak
  # temp clones on every (including non-mutating) run.
  log "skills: analysing vendored skills vs upstream (read-only)"
  bash "${sync}" || warn "skills: sync analysis reported issues"
  info "skills: apply non-trivial merges with the /sync-skills agent workflow"
}

# self is two phases so `all` can pull BEFORE updating tools/plugins (so they
# install from the freshest manifests) and apply AFTER (so refreshed lockfiles
# and configs are deployed). The standalone `self` component runs both.
self_pull() {
  if [[ -n "$(git -C "${DOTFILES_ROOT}" status --porcelain 2>/dev/null)" ]]; then
    warn "self: working tree is dirty; skipping 'git pull' to avoid clobbering changes"
    return 0
  fi
  if [[ "${CHECK_ONLY}" == true ]]; then
    info "self: would run 'git pull --ff-only'"
    git -C "${DOTFILES_ROOT}" fetch --dry-run 2>&1 | sed 's/^/  /' || true
    return 0
  fi
  if ! git -C "${DOTFILES_ROOT}" pull --ff-only; then
    warn "self: git pull --ff-only failed"
    return 1
  fi
}

self_apply() {
  local mise_cmd
  mise_cmd="$(mise_bin)" || {
    warn "self: mise not available; cannot apply dotfiles"
    return 1
  }
  local -a apply=(bootstrap dotfiles apply)
  if [[ "${CHECK_ONLY}" == true ]]; then apply+=(--dry-run); else apply+=(--yes); fi
  # A non-zero exit here is informational, not fatal: `--dry-run` returns non-zero
  # when there are pending changes, and apply refuses to overwrite existing
  # whole-file targets. Warn and continue rather than abort so the other managed
  # layers still update.
  if ! MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}/mise.toml${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${mise_cmd}" -C "${DOTFILES_ROOT}" "${apply[@]}"; then
    warn "self: mise bootstrap dotfiles reported pending changes or refused existing whole-file targets; inspect 'mise bootstrap dotfiles status', preserve live-only content, and force only reviewed targets"
    return 1
  fi
}

restore_agent_adapters() {
  # Codex appends marketplace/plugin state to its copy-mode config, so every
  # standalone dotfiles re-apply must restore agent adapters afterward. The
  # all-components path instead performs its full plugin update last.
  local agents="${DOTFILES_ROOT}/install/common/agents.sh"
  local -a agent_args=()
  [[ "${CHECK_ONLY}" == true ]] && agent_args+=(--check)
  if ! bash "${agents}" ${agent_args[@]+"${agent_args[@]}"}; then
    warn "self: agent adapters did not fully converge after dotfiles apply"
    return 1
  fi
}

update_self() {
  local rc=0
  log "self: updating the checkout, re-applying dotfiles, and restoring agent adapters"
  self_pull || rc=1
  self_apply || rc=1
  restore_agent_adapters || rc=1
  return "${rc}"
}

run_component() {
  case "$1" in
    mise) update_mise ;;
    codex) update_codex ;;
    pi) update_pi ;;
    agentmemory) update_agentmemory ;;
    casks) update_casks ;;
    formulae) update_formulae ;;
    plugins) update_plugins ;;
    vscode) update_vscode ;;
    skills) update_skills ;;
    self) update_self ;;
    all)
      # Pull the checkout first so every layer uses the freshest manifests, then
      # update tools/packages, report skill drift, and apply managed files. Agent
      # plugins converge last because Codex stores marketplace/plugin state in
      # ~/.codex/config.toml and the copy-mode dotfiles apply replaces that file.
      # Each step is fault-tolerant: one failure warns and the rest still run.
      self_pull || record_failure "update: self (pull) reported issues"
      update_mise || record_failure "update: mise component reported issues"
      update_casks || record_failure "update: casks component reported issues"
      update_formulae || record_failure "update: formulae component reported issues"
      update_vscode || record_failure "update: vscode component reported issues"
      update_skills || record_failure "update: skills component reported issues"
      self_apply || record_failure "update: self (apply) reported issues"
      update_plugins || record_failure "update: plugins component reported issues"
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
    run_component "${component}" || record_failure "update: ${component} component reported issues"
  done
  if [[ "${UPDATE_FAILURES}" -gt 0 ]]; then
    warn "update completed with ${UPDATE_FAILURES} failed component(s)"
    return 1
  fi
  log "update complete"
}

main "$@"
