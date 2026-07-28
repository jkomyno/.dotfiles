# Keep .zshenv cheap; it runs for every zsh invocation.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ripgrep only reads a config file when this variable points at one.
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"

# Auto-checkpoint off. agent-checkpoint.sh runs `git add -A` before committing,
# so a turn that edits unrelated files sweeps them into a `chore(wip)` commit
# whose message describes something else. The machinery stays wired for all
# three harnesses (Claude Stop hook, Codex notify, pi autocheckpoint) — set this
# to 1, or unset it, to turn checkpointing back on.
export AGENT_CHECKPOINT=0

# Rust toolchain shims, for tools that expect ~/.cargo/bin on PATH.
if [ -r "${HOME}/.cargo/env" ]; then
  . "${HOME}/.cargo/env"
fi

if [ -r "${HOME}/.zshenv.local" ]; then
  source "${HOME}/.zshenv.local"
fi
