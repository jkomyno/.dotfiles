# jkomyno's dotfiles

Automated dotfiles management for my ([jkomyno](https://x.com/jkomyno)) personal development environment.

## Overview

These dotfiles:
- are managed by [`chezmoi`](https://www.chezmoi.io/)
- target macOS (Apple Silicon)
- use [`mise`](https://mise.jdx.dev/) for language runtimes and CLI developer tools
- use [`nanobrew`](https://github.com/justrach/nanobrew), a faster Homebrew alternative, for macOS apps, fonts, and exceptional formulae
- include configurations for AI Agents, Fish shell, Git, Ghostty, mise, and other essential development tools

The actual dotfiles exist under the [`home`](./home) directory specified in [`.chezmoiroot`](./.chezmoiroot).
See [.chezmoiroot - chezmoi](https://www.chezmoi.io/reference/special-files-and-directories/chezmoiroot/) for more detail on the setting.

## Tool Ownership

[`home/dot_mise/config.toml`](./home/dot_mise/config.toml) is the source of truth for language runtimes and command-line development tools. This includes Node.js, Python, Rust, package managers, linters, formatters, search tools, and other CLIs that mise can install. Chezmoi exposes it as `~/.config/mise/config.toml` through [`home/dot_config/exact_mise/symlink_config.toml.tmpl`](./home/dot_config/exact_mise/symlink_config.toml.tmpl).

[`install/macos/common/nanobrew-casks.Brewfile`](./install/macos/common/nanobrew-casks.Brewfile) owns GUI apps and fonts. [`install/macos/common/nanobrew-formulae.Brewfile`](./install/macos/common/nanobrew-formulae.Brewfile) should stay empty unless a required package has no practical mise backend.

Do not install the same CLI in both mise and nanobrew.

## Bootstrap

[`setup.sh`](./setup.sh) is intentionally a thin entrypoint: it installs or finds `chezmoi`, initializes this repository, and runs `chezmoi apply`.

Machine provisioning lives in [`install`](./install) and is wired into chezmoi through `home/.chezmoiscripts`.
