#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

# Ollama models to keep pulled on this machine. Add one entry per model.
# Pulled idempotently after mise installs the ollama CLI; wired up via the
# staged setup task.
readonly OLLAMA_MODELS=(
  # https://ollama.com/library/nomic-embed-text-v2-moe - multilingual text embeddings (v2 MoE)
  "nomic-embed-text-v2-moe"
)

readonly MISE_BIN="${MISE_INSTALL_PATH:-${HOME}/.local/bin/mise}"
readonly OLLAMA_SERVE_WAIT_SECONDS="${OLLAMA_SERVE_WAIT_SECONDS:-30}"

# Set when this script starts its own `ollama serve`, so cleanup can stop it.
ollama_serve_pid=""

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${ollama_serve_pid}" ]]; then
    kill "${ollama_serve_pid}" 2>/dev/null || true
  fi
}

# Resolve how to invoke ollama: an activated shim if present, else `mise exec`,
# since setup tasks can run before shell activation on a fresh host.
resolve_ollama() {
  if command -v ollama >/dev/null 2>&1; then
    OLLAMA_RUN=(ollama)
  elif [[ -x "${MISE_BIN}" ]]; then
    OLLAMA_RUN=("${MISE_BIN}" exec -- ollama)
  else
    die "ollama not found; ensure mise installed it (install/common/mise.sh)"
  fi
}

ollama_server_up() {
  "${OLLAMA_RUN[@]}" list >/dev/null 2>&1
}

# `ollama pull` needs a running server; the CLI-only install has none until we
# start one. Start it in the background and wait for it to accept requests.
ensure_server() {
  if ollama_server_up; then
    return
  fi

  log "Starting ollama server"
  "${OLLAMA_RUN[@]}" serve >/dev/null 2>&1 &
  ollama_serve_pid=$!

  local waited=0
  until ollama_server_up; do
    sleep 1
    waited=$((waited + 1))
    if ((waited >= OLLAMA_SERVE_WAIT_SECONDS)); then
      die "ollama server did not become ready within ${OLLAMA_SERVE_WAIT_SECONDS}s"
    fi
  done
}

model_present() {
  local model="$1"
  # `ollama list` prints "<name>:<tag>" in the first column; a bare name pins to :latest.
  "${OLLAMA_RUN[@]}" list 2>/dev/null | awk 'NR>1 {print $1}' |
    grep -qxF -e "${model}" -e "${model}:latest"
}

pull_models() {
  local model
  for model in "${OLLAMA_MODELS[@]}"; do
    if model_present "${model}"; then
      log "ollama model already present: ${model}"
      continue
    fi
    log "Pulling ollama model: ${model}"
    "${OLLAMA_RUN[@]}" pull "${model}"
  done
}

main() {
  if [[ -n "${DOTFILES_SKIP_OLLAMA_MODELS:-}" ]]; then
    log "Skipping ollama model pulls (DOTFILES_SKIP_OLLAMA_MODELS is set)"
    return 0
  fi

  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"

  ((${#OLLAMA_MODELS[@]} > 0)) || return 0

  trap cleanup EXIT
  resolve_ollama
  ensure_server
  pull_models
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi
