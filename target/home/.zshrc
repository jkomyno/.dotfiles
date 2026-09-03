#!/usr/bin/env zsh

# Deduplicate PATH-like arrays automatically (zsh keeps path/PATH in sync)
typeset -gU path fpath manpath

# ----------------------------------------------------------------------------
# Environment & PATH (all static — no subprocess calls, costs ~0ms)
# ----------------------------------------------------------------------------

if [[ "$OSTYPE" == darwin* ]]; then
  # nanobrew is the macOS package prefix for tools that mise does not own.
  export MANPATH="/opt/nanobrew/prefix/share/man${MANPATH+:$MANPATH}:"
  export INFOPATH="/opt/nanobrew/prefix/share/info:${INFOPATH:-}"
  export PNPM_HOME="$HOME/Library/pnpm"
  export BUN_CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  _nanobrew_path=(/opt/nanobrew/prefix/bin(N-/))
else
  export PNPM_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/pnpm"
  _nanobrew_path=()
fi
export BUN_INSTALL="$HOME/.bun"
export COMPOSIO_INSTALL_DIR="$HOME/.composio"

# (N-/) drops entries that don't exist, so this stays portable.
path=(
  $COMPOSIO_INSTALL_DIR(N-/)
  $HOME/.local/bin
  $BUN_INSTALL/bin(N-/)
  $PNPM_HOME(N-/)
  $_nanobrew_path
  $path
)
unset _nanobrew_path

# uv
if [ -r "$HOME/.local/bin/env" ]; then
  . "$HOME/.local/bin/env"
fi

# ----------------------------------------------------------------------------
# mise — version manager for node, python, rust, ...
# Activated eagerly and uncached: `mise activate` embeds the live PATH in its
# output, so caching it would freeze a stale PATH.
# ----------------------------------------------------------------------------
if [ -x "${HOME}/.local/bin/mise" ]; then
  eval "$("${HOME}/.local/bin/mise" activate zsh)"
elif command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# ----------------------------------------------------------------------------
# Cached evals — ONLY for commands whose output is static (prompt, hooks).
# Regenerates when the binary changes.
# ----------------------------------------------------------------------------
_cached_eval() {
  local name=$1 cmd=$2
  local cache="$HOME/.cache/zsh/${name}.zsh"
  local bin="${3:-$(whence -p $name)}"
  if [[ ! -f "$cache" || "$bin" -nt "$cache" ]]; then
    mkdir -p "$HOME/.cache/zsh"
    eval "$cmd" >| "$cache" 2>/dev/null
  fi
  source "$cache"
}

command -v starship >/dev/null 2>&1 && _cached_eval starship "starship init zsh --print-full-init"
command -v direnv >/dev/null 2>&1 && _cached_eval direnv "direnv hook zsh"
unfunction _cached_eval

# ----------------------------------------------------------------------------
# zinit plugin manager
# ----------------------------------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Completions — only rebuild the dump once per day, use the cache (-C) otherwise.
# Must run before plugin declarations so `compdef` exists when zinit replays it.
# The dump lives in the XDG cache dir; touch resets the daily clock because a
# full compinit does not rewrite an unchanged dump.
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p "${_zcompdump:h}"
autoload -Uz compinit
if [[ -n "$_zcompdump"(#qN.mh+24) || ! -f "$_zcompdump" ]]; then
  compinit -d "$_zcompdump"
  touch "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi
unset _zcompdump

source "$HOME/.config/zsh/plugins.zsh"

# ----------------------------------------------------------------------------
# History
# ----------------------------------------------------------------------------
HISTSIZE=999999999
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
SAVEHIST=$HISTSIZE
mkdir -p "${HISTFILE:h}"
# One-time migration from the legacy location
if [[ -f ~/.zsh_history && ! -f "$HISTFILE" ]]; then
  mv ~/.zsh_history "$HISTFILE"
fi
setopt extended_history
setopt inc_append_history
setopt appendhistory
setopt share_history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Honor `#` comments in interactive input, so pasted command blocks that carry
# trailing "# ..." notes don't treat the comment as arguments.
setopt interactivecomments

# ----------------------------------------------------------------------------
# Completion styling
# ----------------------------------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no

# Remove "/" from WORDCHARS so slash acts as a word break
WORDCHARS=${WORDCHARS//\/}

# Recover when a TUI exits without restoring terminal input modes. Focus
# reporting otherwise leaks ESC [ I/O on app focus changes, while enhanced
# keyboard reporting makes ordinary shell input arrive as CSI u sequences.
_restore_terminal_input_modes() {
  [[ -t 1 ]] || return 0
  builtin printf '\e[?1004l\e[<u\e[=0u'
}
typeset -ga precmd_functions
if (( ${precmd_functions[(I)_restore_terminal_input_modes]} == 0 )); then
  precmd_functions+=(_restore_terminal_input_modes)
fi

# Key bindings.
# Note: you can determine the escape sequence by applying the key binding
# while `cat -v` is running.
bindkey '^[[H' beginning-of-line # fn + left arrow
bindkey '^[[F' end-of-line       # fn + right arrow
bindkey '^[[3~' delete-char      # fn + delete
bindkey '^[b' backward-word      # option + left arrow
bindkey '^[f' forward-word       # option + right arrow

# Fuzzy finder: use ripgrep as the default search command (must be exported —
# fzf is a child process and cannot see unexported shell variables)
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow --glob "!.git/*"'

# ----------------------------------------------------------------------------
# Aliases & custom functions, one per file
# ----------------------------------------------------------------------------

# Aliases: every file in aliases.d is sourced at startup ((N) = skip if empty)
for _alias_file in "$HOME/.config/zsh/aliases.d"/*.zsh(N); do
  source "$_alias_file"
done
unset _alias_file

# Functions: one file per function, named after it, lazily autoloaded on
# first call (the zsh equivalent of fish's ~/.config/fish/functions/)
fpath=("$HOME/.config/zsh/functions" $fpath)
autoload -Uz gbda trash tempd

# Machine-local overrides, intentionally unmanaged
if [ -r "${HOME}/.zshrc.local" ]; then
  source "${HOME}/.zshrc.local"
fi

# Session integrations: optional behavior that may change terminal process
# lifetime, sourced last so local overrides can opt in.
for _session_file in "$HOME/.config/zsh/session.d"/*.zsh(N); do
  source "$_session_file"
done
unset _session_file
