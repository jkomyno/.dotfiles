# macOS Install Scripts

This directory contains macOS provisioning scripts used by the chezmoi hooks in `home/.chezmoiscripts/macos`.

The active target is Apple Silicon macOS. The current first-run order is:

1. Xcode Command Line Tools
2. Homebrew
3. nanobrew
4. nanobrew casks from `install/macos/common/nanobrew-casks.Brewfile`
5. nanobrew formulae from `install/macos/common/nanobrew-formulae.Brewfile`

After chezmoi applies managed files, the common mise hook installs the pinned standalone mise binary and globally configured development tools from `home/dot_mise/config.toml`, exposed as `~/.config/mise/config.toml`.

Tool ownership stays split by package class. mise owns language runtimes and command-line developer tools. nanobrew owns GUI apps and fonts through casks; its formula bundle should stay empty unless a required package has no practical mise backend.

Keep scripts standalone and idempotent. The hook templates should only decide whether a script runs and in what order.
