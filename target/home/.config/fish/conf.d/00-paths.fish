# Base user paths. This file is prefixed so fish loads it before mise.fish;
# mise activation can then place managed tool paths ahead of ad-hoc installs.
# --path updates this shell's PATH directly instead of persisting entries to
# universal variables, so this file stays the single source of truth.
set --global --export PNPM_HOME "$HOME/Library/pnpm"
set --global --export BUN_INSTALL "$HOME/.bun"

fish_add_path --path --move \
    "$HOME/.local/bin" \
    "$BUN_INSTALL/bin" \
    "$PNPM_HOME" \
    /opt/nanobrew/prefix/bin \
    "$HOME/.cargo/bin"
