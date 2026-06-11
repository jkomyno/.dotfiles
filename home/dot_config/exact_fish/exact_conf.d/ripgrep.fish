# ripgrep only reads a config file when this variable points at one.
# The managed ~/.config/ripgrep/config enables hidden files and excludes .git,
# so no rg alias/wrapper is needed.
set --global --export RIPGREP_CONFIG_PATH "$HOME/.config/ripgrep/config"
