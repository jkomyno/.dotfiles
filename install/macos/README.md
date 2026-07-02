# macOS Install Scripts

This directory contains macOS provisioning scripts used by the staged mise tasks in `tasks/install/macos`.

The active target is Apple Silicon macOS. These macOS-specific scripts run in
this relative order within the full staged setup (see the complete step list in
`MIGRATION.md`):

1. Xcode Command Line Tools
2. Homebrew
3. nanobrew
4. nanobrew casks from `install/macos/common/nanobrew-casks.Brewfile`
5. nanobrew formulae from `install/macos/common/nanobrew-formulae.Brewfile`
6. macOS preferences from `install/macos/common/defaults.sh`

Note that `defaults.sh` is the **last** step of the whole staged setup: it runs
after the common mise, Git, GitHub, Ollama, and MLX tasks, not immediately after
the formulae bundle.

After `mise dotfiles apply` exposes the managed config as `~/.config/mise/config.toml`, the common mise task installs the configured development tools from `target/home/.config/mise/config.toml`. Later common tasks pull the Ollama models declared in `install/common/ollama-models.sh`, starting a temporary `ollama serve` if none is already running.

Tool ownership stays split by package class. mise owns language runtimes and command-line developer tools. nanobrew owns GUI apps and fonts through casks; its formula bundle should stay empty unless a required package has no practical mise backend.

Keep scripts standalone and idempotent. The task wrappers should only decide whether a script runs and in what order.

`defaults.sh` is wired through the `install:macos:defaults` task. Run it directly for manual reapplication:

```sh
install/macos/common/defaults.sh
```

The Dock is always configured to show only running applications (`static-only`), which hides pinned items without deleting them. Clearing the saved pinned-item lists and sudo-backed power/login settings are opt-in:

```sh
install/macos/common/defaults.sh --reset-dock
install/macos/common/defaults.sh --privileged
```

`--privileged` applies the login-window host-info setting, `nvram SystemAudioVolume=" "`, and power defaults: standby delay `86400`, hibernation mode `3`, and AC sleep `0`.

Machine identity is setup-only because it is per-device state. `setup.sh` sets it before the staged setup applies repeatable defaults.

```sh
DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro" ./setup.sh
DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro" \
  DOTFILES_LOCAL_HOSTNAME=albertos-macbook-pro \
  DOTFILES_HOST_NAME=albertos-macbook-pro.local \
  ./setup.sh
```

When no override is provided, `setup.sh` uses `Alberto's MacBook Pro`, derives `LocalHostName` as `albertos-macbook-pro`, and derives a 15-character SMB `NetBIOSName`. Set `DOTFILES_SKIP_COMPUTER_NAME=1` to leave machine identity untouched.
