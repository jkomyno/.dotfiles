#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

mode="run"
force_dotfiles="false"

setup_plan=(
  "task|install:common:ssh|home/.chezmoiscripts/common/run_once_before_01-generate-ssh-key.sh.tmpl|install/common/ssh.sh"
  "task|install:macos:command-line-tools|home/.chezmoiscripts/macos/run_once_before_01-install-command-line-tools.sh.tmpl|install/macos/common/command_line_tools.sh"
  "task|install:macos:homebrew|home/.chezmoiscripts/macos/run_once_before_02-install-homebrew.sh.tmpl|install/macos/common/homebrew.sh"
  "task|install:macos:nanobrew|home/.chezmoiscripts/macos/run_once_before_03-install-nanobrew.sh.tmpl|install/macos/common/nanobrew.sh"
  "task|install:macos:nanobrew-casks|home/.chezmoiscripts/macos/run_once_before_04-install-nanobrew-casks.sh.tmpl|install/macos/common/nanobrew-casks.sh"
  "task|install:macos:nanobrew-formulae|home/.chezmoiscripts/macos/run_once_before_05-install-nanobrew-formulae.sh.tmpl|install/macos/common/nanobrew-formulae.sh"
  "dotfiles|mise:dotfiles:apply|mise.toml|target/home"
  "task|install:common:mise|home/.chezmoiscripts/common/run_once_after_02-install-mise.sh.tmpl|install/common/mise.sh"
  "task|install:common:git|home/.chezmoiscripts/common/run_after_03-migrate-git-xdg.sh.tmpl|install/common/git.sh"
  "task|install:common:git-signing|install/common/git-signing.sh|install/common/git-signing.sh"
  "task|install:common:gh|home/.chezmoiscripts/common/run_after_04-setup-github.sh.tmpl|install/common/gh.sh"
  "task|install:common:ollama-models|home/.chezmoiscripts/common/run_onchange_after_05-pull-ollama-models.sh.tmpl|install/common/ollama-models.sh"
  "task|install:common:mlx|home/.chezmoiscripts/common/run_onchange_after_06-install-mlx.sh.tmpl|install/common/mlx.sh"
  "task|install:macos:defaults|home/.chezmoiscripts/macos/run_onchange_after_06-apply-macos-defaults.sh.tmpl|install/macos/common/defaults.sh"
)

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/mise-setup-staged.sh [options]

Run the staged mise setup sequence for this repository.

Options:
  --plan              Print the planned task order without running it.
  --check             Validate the staged setup plan without running it.
  --force-dotfiles    Pass --force to `mise dotfiles apply`.
  -h, --help          Show this help.

By default this script runs installers and applies dotfiles to the current HOME.
Use --plan or --check for non-mutating validation.
USAGE
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --plan)
        mode="plan"
        ;;
      --check)
        mode="check"
        ;;
      --force-dotfiles)
        force_dotfiles="true"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        error "unknown option: $1"
        usage >&2
        exit 2
        ;;
    esac
    shift
  done
}

run_repo_mise() {
  local mise_cmd
  mise_cmd="$(mise_bin)" || return 127

  env \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}/mise.toml:${DOTFILES_ROOT}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${mise_cmd}" -C "${DOTFILES_ROOT}" "$@"
}

run_repo_mise_dotfiles() {
  local args=(apply --yes)
  if [[ "${force_dotfiles}" == "true" ]]; then
    args+=(--force)
  fi

  MISE_EXPERIMENTAL=true run_repo_mise dotfiles "${args[@]}"
}

print_plan() {
  local index=1
  local kind name hook source

  printf '%-4s %-9s %-36s %s\n' "#" "kind" "name" "source/hook"
  for entry in "${setup_plan[@]}"; do
    IFS='|' read -r kind name hook source <<<"${entry}"
    printf '%-4s %-9s %-36s %s -> %s\n' "${index}" "${kind}" "${name}" "${hook}" "${source}"
    index=$((index + 1))
  done

}

registered_tasks() {
  run_repo_mise tasks ls --local --name-only
}

check_task_registered() {
  local task="$1"
  local actual_tasks="$2"

  if grep -Fxq "${task}" <<<"${actual_tasks}"; then
    info "mise task exists: ${task}"
  else
    error "missing mise task: ${task}"
    return 1
  fi
}

check_hook_mapping() {
  local hook="$1"
  local source="$2"
  local hook_path="${DOTFILES_ROOT}/${hook}"
  local include_path="../${source}"

  [[ -f "${hook_path}" ]] || {
    error "missing hook template: ${hook}"
    return 1
  }

  if grep -Fq "${include_path}" "${hook_path}"; then
    info "hook maps ${hook} to ${source}"
  elif [[ "${hook}" == "${source}" && -f "${hook_path}" ]]; then
    info "script maps ${hook}"
  else
    error "hook ${hook} does not include ${include_path}"
    return 1
  fi
}

check_plan() {
  local actual_tasks
  local kind name hook source

  actual_tasks="$(registered_tasks | sort)"
  check_task_registered "setup:staged" "${actual_tasks}"

  for entry in "${setup_plan[@]}"; do
    IFS='|' read -r kind name hook source <<<"${entry}"
    case "${kind}" in
      task)
        check_task_registered "${name}" "${actual_tasks}"
        check_hook_mapping "${hook}" "${source}"
        ;;
      dotfiles)
        [[ -f "${DOTFILES_ROOT}/${hook}" ]] || {
          error "missing mise dotfiles config: ${hook}"
          return 1
        }
        [[ -d "${DOTFILES_ROOT}/${source}" ]] || {
          error "missing mise dotfiles source tree: ${source}"
          return 1
        }
        info "dotfiles boundary exists: ${hook} -> ${source}"
        ;;
      *)
        error "unknown plan entry kind: ${kind}"
        return 1
        ;;
    esac
  done

  run_repo_mise tasks validate --local --errors-only
}

run_plan() {
  local kind name hook source

  for entry in "${setup_plan[@]}"; do
    IFS='|' read -r kind name hook source <<<"${entry}"
    case "${kind}" in
      task)
        log "Running ${name}"
        run_repo_mise run --skip-tools --skip-deps --raw "${name}"
        ;;
      dotfiles)
        log "Applying mise dotfiles"
        run_repo_mise_dotfiles
        ;;
      *)
        error "unknown plan entry kind: ${kind}"
        return 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  case "${mode}" in
    plan)
      print_plan
      ;;
    check)
      check_plan
      ;;
    run)
      run_plan
      ;;
    *)
      error "unknown mode: ${mode}"
      return 1
      ;;
  esac
}

main "$@"
