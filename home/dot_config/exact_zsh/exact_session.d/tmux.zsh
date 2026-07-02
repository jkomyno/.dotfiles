# Opt-in tmux auto-attach for terminal sessions.
#
# Enable with:
#   export DOTFILES_AUTO_TMUX=1
#
# Keep this conservative: do not hijack non-interactive shells, nested tmux,
# SSH sessions, editor terminals, dumb terminals, or CI command runners.
[[ -o interactive ]] || return
[[ "${DOTFILES_AUTO_TMUX:-}" == "1" ]] || return
[[ -z "${TMUX:-}" ]] || return
[[ -z "${SSH_CONNECTION:-}${SSH_TTY:-}" ]] || return
[[ -z "${CI:-}${CODESPACES:-}${GITHUB_ACTIONS:-}" ]] || return
[[ "${TERM:-}" != "dumb" ]] || return
[[ -z "${INSIDE_EMACS:-}${VSCODE_INJECTION:-}" ]] || return

case "${TERM_PROGRAM:-}" in
  vscode | VSCodium | Cursor)
    return
    ;;
esac

command -v tmux >/dev/null 2>&1 || return

if tmux has-session -t default 2>/dev/null; then
  exec tmux attach-session -t default
fi

exec tmux new-session -s default
