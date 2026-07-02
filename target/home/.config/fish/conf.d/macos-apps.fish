# macOS GUI-app command-line entrypoints and OrbStack shell integration.
# Mirrors the zsh login-shell setup in ~/.zprofile so fish (the login shell on
# this machine) reaches the same tools. Every branch is existence-guarded, so
# this is a no-op on Linux or when an app is not installed.

# Command-line entrypoint shipped inside the VS Code app bundle (`code`).
if test -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    fish_add_path --path --append "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
end

# OrbStack command-line tools and shell integration (docker, orb, ...).
if test -r "$HOME/.orbstack/shell/init.fish"
    source "$HOME/.orbstack/shell/init.fish"
end
