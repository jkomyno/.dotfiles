# jkomyno's dotfiles

Automated dotfiles management for my ([jkomyno](https://x.com/jkomyno)) personal development environment.

## Overview

These dotfiles:
- are managed by [`chezmoi`](https://www.chezmoi.io/)
- target MacOS (Apple Silicon)
- use [`nanobrew`](https://github.com/justrach/nanobrew), a faster Homebrew alternative, for package management
- include configurations for AI Agents, Fish shell, Git, Ghostty, and other essential development tools

The actual dotfiles exist under the [`home`](./home) directory specified in [`.chezmoiroot`](./.chezmoiroot).
See [.chezmoiroot - chezmoi](https://www.chezmoi.io/reference/special-files-and-directories/chezmoiroot/) for more detail on the setting.

## Bootstrap

[`setup.sh`](./setup.sh) is intentionally a thin entrypoint: it installs or finds `chezmoi`, initializes this repository, and runs `chezmoi apply`.

Machine provisioning lives in [`install`](./install) and is wired into chezmoi through `home/.chezmoiscripts`.
