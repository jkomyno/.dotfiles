# macOS Install Scripts

This directory contains macOS provisioning scripts used by the chezmoi hooks in `home/.chezmoiscripts/macos`.

The active target is Apple Silicon macOS. The current first-run order is:

1. Xcode Command Line Tools
2. Homebrew
3. nanobrew
4. nanobrew casks from `install/macos/common/nanobrew-casks.Brewfile`
5. nanobrew formulae from `install/macos/common/nanobrew-formulae.Brewfile`
6. macOS preferences from `install/macos/common/defaults.sh`

After chezmoi applies managed files, the common mise hook installs the pinned standalone mise binary and globally configured development tools from `home/dot_mise/config.toml`, exposed as `~/.config/mise/config.toml`.

Tool ownership stays split by package class. mise owns language runtimes and command-line developer tools. nanobrew owns GUI apps and fonts through casks; its formula bundle should stay empty unless a required package has no practical mise backend.

Keep scripts standalone and idempotent. The hook templates should only decide whether a script runs and in what order.

`defaults.sh` is wired through a `run_onchange_after` chezmoi hook, so it runs on first apply and when the managed preference script changes. Run it directly for manual reapplication:

```sh
install/macos/common/defaults.sh
```

The Dock is always configured to show only running applications (`static-only`), which hides pinned items without deleting them. Clearing the saved pinned-item lists and sudo-backed power/login settings are opt-in:

```sh
install/macos/common/defaults.sh --reset-dock
install/macos/common/defaults.sh --privileged
```

`--privileged` applies the login-window host-info setting, `nvram SystemAudioVolume=" "`, and power defaults: standby delay `86400`, hibernation mode `3`, and AC sleep `0`.

Machine identity is setup-only because it is per-device state. `setup.sh` sets it before `chezmoi apply`; the repeatable defaults hook does not rename the Mac.

```sh
DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro" ./setup.sh
DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro" \
  DOTFILES_LOCAL_HOSTNAME=albertos-macbook-pro \
  DOTFILES_HOST_NAME=albertos-macbook-pro.local \
  ./setup.sh
```

When no override is provided, `setup.sh` uses `Alberto's MacBook Pro`, derives `LocalHostName` as `albertos-macbook-pro`, and derives a 15-character SMB `NetBIOSName`. Set `DOTFILES_SKIP_COMPUTER_NAME=1` to leave machine identity untouched.
