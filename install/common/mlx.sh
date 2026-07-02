#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

# mlx-lm provides `mlx_lm.server`, an OpenAI-compatible (`/v1/chat/completions`) local LLM
# server built on Apple's MLX framework. It is the MLX-first generation runtime for the
# Slovo RAG web app (ADR-014): the fastest Apple-Silicon path for local answer synthesis,
# run as an isolated local process. Installed via `uv tool` (isolated venv + shims in
# ~/.local/bin) after mise provides uv, idempotently. MLX is Apple-Silicon-only, so this is
# a no-op on any other platform. Wired up via the staged setup task.

# Python packages providing console entry points to install as uv tools. mlx-lm ships
# `mlx_lm.server`, `mlx_lm.generate`, `mlx_lm.chat`, and friends.
readonly MLX_TOOLS=(
  # https://github.com/ml-explore/mlx-lm - run/serve LLMs locally on Apple Silicon via MLX
  "mlx-lm"
)

readonly MISE_BIN="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"
readonly UV_BIN_DIR="${UV_TOOL_BIN_DIR:-${XDG_BIN_HOME:-${HOME}/.local/bin}}"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

# Resolve how to invoke uv: an activated shim if present, else `mise exec`, since setup
# tasks can run before shell activation on a fresh host.
resolve_uv() {
  if command -v uv >/dev/null 2>&1; then
    UV_RUN=(uv)
  elif [[ -x "${MISE_BIN}" ]]; then
    UV_RUN=("${MISE_BIN}" exec -- uv)
  else
    die "uv not found; ensure mise installed it (install/common/mise.sh)"
  fi
}

tool_installed() {
  local tool="$1"
  "${UV_RUN[@]}" tool list 2>/dev/null | awk '{print $1}' | grep -qxF "${tool}"
}

install_tools() {
  local tool
  for tool in "${MLX_TOOLS[@]}"; do
    if tool_installed "${tool}"; then
      log "uv tool already installed: ${tool} (upgrade with: uv tool upgrade ${tool})"
      continue
    fi
    log "Installing uv tool: ${tool}"
    "${UV_RUN[@]}" tool install "${tool}"
  done
}

verify() {
  # `uv tool install mlx-lm` puts the server shim in uv's bin dir (~/.local/bin by
  # default). A freshly provisioned, non-activated shell may not have it on PATH yet.
  if command -v mlx_lm.server >/dev/null 2>&1 || [[ -x "${UV_BIN_DIR}/mlx_lm.server" ]]; then
    log "mlx_lm.server is available"
  else
    die "mlx-lm installed but the mlx_lm.server shim was not found in ${UV_BIN_DIR}"
  fi
}

main() {
  # MLX requires Apple Silicon; this is a no-op (not an error) anywhere else, so a future
  # Linux profile applies cleanly.
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || return 0

  ((${#MLX_TOOLS[@]} > 0)) || return 0

  resolve_uv
  install_tools
  verify
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
