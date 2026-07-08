#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

expected_tasks=(
  "install:common:amp"
  "install:common:gh"
  "install:common:git"
  "install:common:git-signing"
  "install:common:mise"
  "install:common:mlx"
  "install:common:ollama-models"
  "install:common:paseo"
  "install:common:ssh"
  "install:macos:command-line-tools"
  "install:macos:defaults"
  "install:macos:ghostty-terminfo"
  "install:macos:nanobrew"
  "install:macos:nanobrew-casks"
  "install:macos:nanobrew-formulae"
  "install:macos:screen-sharing"
  "install:macos:tailscale"
  "check:dotfiles-check"
  "setup:staged"
)

task_install_targets=(
  "install/common/amp.sh"
  "install/common/gh.sh"
  "install/common/git.sh"
  "install/common/git-signing.sh"
  "install/common/mise.sh"
  "install/common/mlx.sh"
  "install/common/ollama-models.sh"
  "install/common/paseo.sh"
  "install/common/ssh.sh"
  "install/macos/common/command_line_tools.sh"
  "install/macos/common/defaults.sh"
  "install/macos/common/ghostty-terminfo.sh"
  "install/macos/common/nanobrew.sh"
  "install/macos/common/nanobrew-casks.sh"
  "install/macos/common/nanobrew-formulae.sh"
  "install/macos/common/screen-sharing.sh"
  "install/macos/common/tailscale.sh"
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

check_mise_installer_env() {
  local output
  local tmp
  tmp="$(mktemp -d)"

  if output="$(
    env \
      HOME="${tmp}/home" \
      MISE_BOOTSTRAP_VERSION="v0.0.0-test" \
      MISE_INSTALL_PATH="${tmp}/bin/mise" \
      DOTFILES_ROOT="${DOTFILES_ROOT}" \
      bash -c '
set -Eeuo pipefail

curl() {
  case " $* " in
    *" https://github.com/jdx/mise/releases/download/v0.0.0-test/install.sh "*) ;;
    *)
      printf "unexpected mise installer URL: %s\n" "$*" >&2
      return 1
      ;;
  esac

  printf "%s\n" \
    "#!/bin/sh" \
    "set -eu" \
    ": \"\${MISE_VERSION:?}\"" \
    ": \"\${MISE_INSTALL_PATH:?}\""
}

source "${DOTFILES_ROOT}/install/common/mise.sh"
install_mise
'
  )"; then
    rm -rf "${tmp}"
    info "mise installer accepts readonly MISE_INSTALL_PATH"
  else
    rm -rf "${tmp}"
    printf '%s\n' "${output}" >&2
    error "mise installer cannot pass MISE_INSTALL_PATH to child installer"
    return 1
  fi
}

main() {
  check_task_targets
  check_mise_tasks
  check_mise_installer_env
  "${SCRIPT_DIR}/mise-setup-staged.sh" --check
  "${SCRIPT_DIR}/mise-setup-staged.sh" --check --only install:common:git-signing >/dev/null
  "${SCRIPT_DIR}/mise-setup-staged.sh" --plan --from install:common:mise --until install:common:git-signing >/dev/null
}

main "$@"
