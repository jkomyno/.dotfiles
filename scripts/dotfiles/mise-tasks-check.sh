#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

expected_tasks=(
  "install:common:gh"
  "install:common:git"
  "install:common:mise"
  "install:common:mlx"
  "install:common:ollama-models"
  "install:macos:command-line-tools"
  "install:macos:defaults"
  "install:macos:homebrew"
  "install:macos:nanobrew"
  "install:macos:nanobrew-casks"
  "install:macos:nanobrew-formulae"
  "migration:dotfiles-capabilities"
  "migration:dotfiles-check"
  "migration:dotfiles-spike"
)

task_install_targets=(
  "install/common/gh.sh"
  "install/common/git.sh"
  "install/common/mise.sh"
  "install/common/mlx.sh"
  "install/common/ollama-models.sh"
  "install/macos/common/command_line_tools.sh"
  "install/macos/common/defaults.sh"
  "install/macos/common/homebrew.sh"
  "install/macos/common/nanobrew.sh"
  "install/macos/common/nanobrew-casks.sh"
  "install/macos/common/nanobrew-formulae.sh"
)

run_repo_mise() {
  local mise_cmd
  mise_cmd="$(mise_bin)" || return 127

  env \
    MISE_TRUSTED_CONFIG_PATHS="${DOTFILES_ROOT}${MISE_TRUSTED_CONFIG_PATHS:+:${MISE_TRUSTED_CONFIG_PATHS}}" \
    "${mise_cmd}" -C "${DOTFILES_ROOT}" "$@"
}

check_task_targets() {
  local target
  for target in "${task_install_targets[@]}"; do
    if [[ -f "${DOTFILES_ROOT}/${target}" ]]; then
      info "${target} exists"
    else
      error "${target} is missing"
      return 1
    fi
  done
}

check_mise_tasks() {
  local actual_tasks
  local expected_task
  actual_tasks="$(run_repo_mise tasks ls --local --name-only | sort)"

  for expected_task in "${expected_tasks[@]}"; do
    if grep -Fxq "${expected_task}" <<<"${actual_tasks}"; then
      info "mise task exists: ${expected_task}"
    else
      error "missing mise task: ${expected_task}"
      return 1
    fi
  done

  run_repo_mise tasks validate --local --errors-only
}

main() {
  check_task_targets
  check_mise_tasks
}

main "$@"
