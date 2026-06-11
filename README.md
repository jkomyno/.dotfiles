# jkomyno's dotfiles

Automated dotfiles management for my ([jkomyno](https://x.com/jkomyno)) personal development environment.

## Overview

These dotfiles:
- are managed by [`chezmoi`](https://www.chezmoi.io/)
- target macOS (Apple Silicon)
- use [`mise`](https://mise.jdx.dev/) for language runtimes and CLI developer tools
- use [`nanobrew`](https://github.com/justrach/nanobrew), a faster Homebrew alternative, for macOS apps, fonts, and exceptional formulae
- include configurations for zsh, Git, GitHub CLI, mise, uv, and local AI agent skills

The actual dotfiles exist under the [`home`](./home) directory specified in [`.chezmoiroot`](./.chezmoiroot).
See [.chezmoiroot - chezmoi](https://www.chezmoi.io/reference/special-files-and-directories/chezmoiroot/) for more detail on the setting.

## Tool Ownership

[`home/dot_mise/config.toml`](./home/dot_mise/config.toml) is the source of truth for language runtimes and command-line development tools. This includes Node.js, Python, Rust, package managers, linters, formatters, search tools, and other CLIs that mise can install. Chezmoi exposes it as `~/.config/mise/config.toml` through [`home/dot_config/exact_mise/symlink_config.toml.tmpl`](./home/dot_config/exact_mise/symlink_config.toml.tmpl).

Git and GitHub configuration lives under [`home/dot_config/git`](./home/dot_config/git) and [`home/dot_config/gh/private_config.yml`](./home/dot_config/gh/private_config.yml). GitHub CLI authentication state is intentionally not tracked; `gh` stores tokens in the system credential store and `~/.config/gh/hosts.yml`. Bootstrap generates an Ed25519 SSH key when no keypair exists, and the GitHub setup script uploads the public key as a signing key once `gh` is authenticated.

[`install/macos/common/nanobrew-casks.Brewfile`](./install/macos/common/nanobrew-casks.Brewfile) owns GUI apps and fonts. [`install/macos/common/nanobrew-formulae.Brewfile`](./install/macos/common/nanobrew-formulae.Brewfile) should stay empty unless a required package has no practical mise backend.

Do not install the same CLI in both mise and nanobrew.

## Bootstrap

[`setup.sh`](./setup.sh) is intentionally a thin entrypoint: it installs or finds `chezmoi`, initializes this repository, and runs `chezmoi apply`.

Machine provisioning lives in [`install`](./install) and is wired into chezmoi through `home/.chezmoiscripts`.
