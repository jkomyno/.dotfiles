# macOS Install Scripts

This directory contains macOS provisioning scripts used by the chezmoi hooks in `home/.chezmoiscripts/macos`.

The active target is Apple Silicon macOS. The current first-run order is:

1. Xcode Command Line Tools
2. Homebrew
3. nanobrew
4. nanobrew casks from `install/macos/common/nanobrew-casks.Brewfile`
5. nanobrew formulae from `install/macos/common/nanobrew-formulae.Brewfile`

Keep scripts standalone and idempotent. The hook templates should only decide whether a script runs and in what order.
