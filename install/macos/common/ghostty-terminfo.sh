#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

# Ghostty runs terminals as TERM=xterm-ghostty. A machine you SSH into needs
# that terminfo entry, or terminfo lookups (tput, zsh line-editor key bindings)
# fail with `unknown terminal "xterm-ghostty"` — which garbles backspace and
# prompt redraw. Ghostty ships the compiled entry inside its macOS app bundle;
# install it into the user terminfo database so this machine recognizes the
# terminal for any incoming SSH session, independent of the connecting client.
readonly GHOSTTY_APP="${GHOSTTY_APP:-/Applications/Ghostty.app}"
readonly GHOSTTY_TERMINFO_DIR="${GHOSTTY_TERMINFO_DIR:-${GHOSTTY_APP}/Contents/Resources/terminfo}"
readonly TERM_ENTRY="xterm-ghostty"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

has_terminfo_entry() {
  infocmp -x "${TERM_ENTRY}" >/dev/null 2>&1
}

install_ghostty_terminfo() {
  if has_terminfo_entry; then
    log "${TERM_ENTRY} terminfo already available"
    return 0
  fi

  if [[ ! -d "${GHOSTTY_TERMINFO_DIR}" ]]; then
    log "Ghostty terminfo source not found at ${GHOSTTY_TERMINFO_DIR}; skipping"
    return 0
  fi

  log "Installing ${TERM_ENTRY} terminfo from ${GHOSTTY_APP}"
  # Read the compiled entry from the app bundle and compile it into the user
  # terminfo database (~/.terminfo). `tic` prints a harmless "older tic versions"
  # note about the description field and may exit non-zero on it, so verify with
  # infocmp rather than trusting the pipeline's exit status.
  infocmp -A "${GHOSTTY_TERMINFO_DIR}" -x "${TERM_ENTRY}" | tic -x - || true

  has_terminfo_entry || die "${TERM_ENTRY} terminfo still unavailable after install"
}

main() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  command -v infocmp >/dev/null 2>&1 || die "infocmp is required to install terminfo"
  command -v tic >/dev/null 2>&1 || die "tic is required to install terminfo"
  install_ghostty_terminfo
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
