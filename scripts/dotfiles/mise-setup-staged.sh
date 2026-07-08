#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/dotfiles/lib.sh
source "${SCRIPT_DIR}/lib.sh"

mode="run"
force_dotfiles="false"
filter_from_index=1
filter_until_index=0
from_filter=""
until_filter=""
only_filters=()
skip_filters=()

setup_plan=(
  "task|install:common:ssh|install/common/ssh.sh|install/common/ssh.sh"
  "task|install:macos:sudoers-nopasswd|install/macos/common/sudoers-nopasswd.sh|install/macos/common/sudoers-nopasswd.sh"
  "task|install:macos:command-line-tools|install/macos/common/command_line_tools.sh|install/macos/common/command_line_tools.sh"
  "task|install:macos:nanobrew|install/macos/common/nanobrew.sh|install/macos/common/nanobrew.sh"
  "task|install:macos:nanobrew-casks|install/macos/common/nanobrew-casks.sh|install/macos/common/nanobrew-casks.sh"
  "task|install:macos:ghostty-terminfo|install/macos/common/ghostty-terminfo.sh|install/macos/common/ghostty-terminfo.sh"
  "task|install:macos:nanobrew-formulae|install/macos/common/nanobrew-formulae.sh|install/macos/common/nanobrew-formulae.sh"
  "task|install:macos:tailscale|install/macos/common/tailscale.sh|install/macos/common/tailscale.sh"
  "dotfiles|mise:dotfiles:apply|mise.toml|target/home"
  "task|install:common:mise|install/common/mise.sh|install/common/mise.sh"
  "task|install:common:paseo|install/common/paseo.sh|install/common/paseo.sh"
  "task|install:common:git|install/common/git.sh|install/common/git.sh"
  "task|install:common:git-signing|install/common/git-signing.sh|install/common/git-signing.sh"
  "task|install:common:gh|install/common/gh.sh|install/common/gh.sh"
  "task|install:common:claude|install/common/claude.sh|install/common/claude.sh"
  "task|install:common:agents|install/common/agents.sh|install/common/agents.sh"
  "task|install:common:amp|install/common/amp.sh|install/common/amp.sh"
  "task|install:common:ollama-models|install/common/ollama-models.sh|install/common/ollama-models.sh"
  "task|install:common:mlx|install/common/mlx.sh|install/common/mlx.sh"
  "task|install:macos:defaults|install/macos/common/defaults.sh|install/macos/common/defaults.sh"
)

# Steps allowed to fail without aborting the staged run. These fetch things over
# the network (the Claude Code installer, coding-agent plugins, local-LLM assets)
# or depend on host state a fresh/headless run may lack (sudo for the tailscaled
# daemon, a login GUI session for the paseo LaunchAgent), so a flaky download or
# a missing prerequisite must not block the remaining setup (notably macOS
# defaults, which runs after them). They can also be skipped outright via their
# own DOTFILES_SKIP_* env vars.
optional_steps=(
  "install:macos:sudoers-nopasswd"
  "install:macos:tailscale"
  "install:common:paseo"
  "install:common:claude"
  "install:common:agents"
  "install:common:amp"
  "install:common:ollama-models"
  "install:common:mlx"
)

step_is_optional() {
  local name="$1"
  local step
  for step in "${optional_steps[@]}"; do
    [[ "${step}" == "${name}" ]] && return 0
  done
  return 1
}

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/mise-setup-staged.sh [options]

Run the staged mise setup sequence for this repository.

Options:
  --plan              Print the planned task order without running it.
  --check             Validate the staged setup plan without running it.
  --force-dotfiles    Pass --force to `mise dotfiles apply`.
  --from STEP         Start at STEP, matched by step number or name.
  --until STEP        Stop after STEP, matched by step number or name.
  --only STEP         Run only STEP, matched by step number or name. Repeatable.
  --skip STEP         Skip STEP, matched by step number or name. Repeatable.
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
      --from)
        [[ $# -ge 2 ]] || {
          error "--from requires a step number or name"
          exit 2
        }
        from_filter="$2"
        shift
        ;;
      --until)
        [[ $# -ge 2 ]] || {
          error "--until requires a step number or name"
          exit 2
        }
        until_filter="$2"
        shift
        ;;
      --only)
        [[ $# -ge 2 ]] || {
          error "--only requires a step number or name"
          exit 2
        }
        only_filters+=("$2")
        shift
        ;;
      --skip)
        [[ $# -ge 2 ]] || {
          error "--skip requires a step number or name"
          exit 2
        }
        skip_filters+=("$2")
        shift
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

step_ref_matches() {
  local ref="$1"
  local index="$2"
  local name="$3"

  [[ "${ref}" == "${index}" || "${ref}" == "${name}" ]]
}

step_index_for_ref() {
  local ref="$1"
  local index=1
  local entry kind name hook source

  for entry in "${setup_plan[@]}"; do
    IFS='|' read -r kind name hook source <<<"${entry}"
    if step_ref_matches "${ref}" "${index}" "${name}"; then
      printf '%s\n' "${index}"
      return 0
    fi
    index=$((index + 1))
  done

  return 1
}

validate_step_ref() {
  local ref="$1"

  if step_index_for_ref "${ref}" >/dev/null; then
    return 0
  fi

  error "unknown setup step: ${ref}"
  return 1
}

configure_step_filters() {
  local ref

  filter_until_index="${#setup_plan[@]}"

  if [[ -n "${from_filter}" ]]; then
    filter_from_index="$(step_index_for_ref "${from_filter}")" || {
      error "unknown --from setup step: ${from_filter}"
      return 1
    }
  fi

  if [[ -n "${until_filter}" ]]; then
    filter_until_index="$(step_index_for_ref "${until_filter}")" || {
      error "unknown --until setup step: ${until_filter}"
      return 1
    }
  fi

  if ((filter_from_index > filter_until_index)); then
    error "--from step must not come after --until step"
    return 1
  fi

  # ${arr[@]+"${arr[@]}"} keeps these empty-by-default arrays from tripping
  # `set -u` on the stock macOS /bin/bash 3.2, where "${arr[@]}" on an empty
  # array aborts with "unbound variable".
  for ref in ${only_filters[@]+"${only_filters[@]}"}; do
    validate_step_ref "${ref}" || return 1
  done

  for ref in ${skip_filters[@]+"${skip_filters[@]}"}; do
    validate_step_ref "${ref}" || return 1
  done
}

matches_any_step_ref() {
  local index="$1"
  local name="$2"
  shift 2

  local ref
  for ref in "$@"; do
    if step_ref_matches "${ref}" "${index}" "${name}"; then
      return 0
    fi
  done

  return 1
}

step_selected() {
  local index="$1"
  local name="$2"

  ((index >= filter_from_index && index <= filter_until_index)) || return 1

  if ((${#only_filters[@]} > 0)) && ! matches_any_step_ref "${index}" "${name}" "${only_filters[@]}"; then
    return 1
  fi

  if ((${#skip_filters[@]} > 0)) && matches_any_step_ref "${index}" "${name}" "${skip_filters[@]}"; then
    return 1
  fi

  return 0
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
    if ! step_selected "${index}" "${name}"; then
      index=$((index + 1))
      continue
    fi
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
    error "missing setup script: ${hook}"
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
  local index=1
  local kind name hook source

  actual_tasks="$(registered_tasks | sort)"
  check_task_registered "setup:staged" "${actual_tasks}"

  for entry in "${setup_plan[@]}"; do
    IFS='|' read -r kind name hook source <<<"${entry}"
    if ! step_selected "${index}" "${name}"; then
      index=$((index + 1))
      continue
    fi
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
    index=$((index + 1))
  done

  run_repo_mise tasks validate --local --errors-only
}

run_plan() {
  local index=1
  local kind name hook source

  for entry in "${setup_plan[@]}"; do
    IFS='|' read -r kind name hook source <<<"${entry}"
    if ! step_selected "${index}" "${name}"; then
      index=$((index + 1))
      continue
    fi
    case "${kind}" in
      task)
        log "Running ${name}"
        if step_is_optional "${name}"; then
          run_repo_mise run --skip-tools --skip-deps --raw "${name}" ||
            warn "optional step failed: ${name} (continuing)"
        else
          run_repo_mise run --skip-tools --skip-deps --raw "${name}"
        fi
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
    index=$((index + 1))
  done
}

main() {
  parse_args "$@"
  configure_step_filters

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
