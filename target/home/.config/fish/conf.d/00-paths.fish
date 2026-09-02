# Base user paths. This file is prefixed so fish loads it before mise.fish;
# mise activation can then place managed tool paths ahead of ad-hoc installs.
# --path updates this shell's PATH directly instead of persisting entries to
# universal variables, so this file stays the single source of truth.
if test (uname -s) = Darwin
    set --global --export PNPM_HOME "$HOME/Library/pnpm"
    set --global --export BUN_CHROME_PATH "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
else
    set -q XDG_DATA_HOME; or set --global --export XDG_DATA_HOME "$HOME/.local/share"
    set --global --export PNPM_HOME "$XDG_DATA_HOME/pnpm"
end
set --global --export BUN_INSTALL "$HOME/.bun"

if test (uname -s) = Darwin
    fish_add_path --path --move \
        "$HOME/.local/bin" \
        "$BUN_INSTALL/bin" \
        "$PNPM_HOME" \
        /opt/nanobrew/prefix/bin \
        "$HOME/.cargo/bin"
else
    fish_add_path --path --move \
        "$HOME/.local/bin" \
        "$BUN_INSTALL/bin" \
        "$PNPM_HOME" \
        "$HOME/.cargo/bin"
end
