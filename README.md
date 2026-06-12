# jkomyno's dotfiles

Automated dotfiles management for my ([jkomyno](https://x.com/jkomyno)) personal development environment.

## Overview

These dotfiles:
- are managed by [`chezmoi`](https://www.chezmoi.io/)
- target macOS (Apple Silicon)
- use [`mise`](https://mise.jdx.dev/) for language runtimes and CLI developer tools
- use [`nanobrew`](https://github.com/justrach/nanobrew), a faster Homebrew alternative, for macOS apps, fonts, and exceptional formulae
- include configurations for zsh, Git, GitHub CLI, Ghostty, tmux, mise, uv, macOS preferences, and local AI agent skills

The actual dotfiles exist under the [`home`](./home) directory specified in [`.chezmoiroot`](./.chezmoiroot).
See [.chezmoiroot - chezmoi](https://www.chezmoi.io/reference/special-files-and-directories/chezmoiroot/) for more detail on the setting.

## Tool Ownership

[`home/dot_mise/config.toml`](./home/dot_mise/config.toml) is the source of truth for language runtimes and command-line development tools. This includes Node.js, Python, Rust, package managers, linters, formatters, search tools, and other CLIs that mise can install. Chezmoi exposes it as `~/.config/mise/config.toml` through [`home/dot_config/exact_mise/symlink_config.toml.tmpl`](./home/dot_config/exact_mise/symlink_config.toml.tmpl).

Git and GitHub configuration lives under [`home/dot_config/git`](./home/dot_config/git) and [`home/dot_config/gh/private_config.yml`](./home/dot_config/gh/private_config.yml). GitHub CLI authentication state is intentionally not tracked; `gh` stores tokens in the system credential store and `~/.config/gh/hosts.yml`. Bootstrap generates an Ed25519 SSH key when no keypair exists, and the GitHub setup script uploads the public key as a signing key once `gh` is authenticated.

[`install/macos/common/nanobrew-casks.Brewfile`](./install/macos/common/nanobrew-casks.Brewfile) owns GUI apps and fonts. [`install/macos/common/nanobrew-formulae.Brewfile`](./install/macos/common/nanobrew-formulae.Brewfile) should stay empty unless a required package has no practical mise backend.

Do not install the same CLI in both mise and nanobrew.

## Agent Configuration

Coding-agent configuration follows a shared-canonical-plus-adapters layout inspired by [shunk031/dotfiles](https://github.com/shunk031/dotfiles):

- [`home/dot_agents`](./home/dot_agents) is the shared layer, deployed to `~/.agents`. `AGENTS.md` holds instructions common to every harness, and `skills/` holds both first-party skills and vendored third-party skills as real files. Each third-party skill is mapped to its upstream repository in [`exact_sync-skills/manifest.json`](./home/dot_agents/skills/exact_sync-skills/manifest.json); the `sync-skills` skill (inspired by dmmulroy's `sync-pocock-skills`) updates vendored copies from upstream while re-applying local modifications stored as patch files.
- [`home/dot_claude`](./home/dot_claude) deploys Claude Code's global `settings.json`, `CLAUDE.md` (which imports `~/.agents/AGENTS.md`), `hooks/`, and per-skill symlinks from `~/.claude/skills/` into `~/.agents/skills/`.
- [`home/dot_codex`](./home/dot_codex) deploys a curated `~/.codex/config.toml`, `AGENTS.md` (which defers to `~/.agents/AGENTS.md`), and the same per-skill symlinks.

Only curated configuration is tracked. Runtime state in `~/.claude` (sessions, history, caches) and `~/.codex` (the `[projects.*]` trust list, `rules/`, sqlite databases) stays unmanaged; chezmoi never touches files it does not list, and none of these directories use `exact_` at the top level. Skill directories not listed in this repository (for example one-off installs by other tooling) are left alone; only the per-skill `exact_` directories are pruned on apply. To take a previously installed skill under management, vendor it via `sync-skills` instead of editing the deployed copy.

macOS user preferences live in [`install/macos/common/defaults.sh`](./install/macos/common/defaults.sh) and are applied through a `run_onchange_after` chezmoi hook. The script handles repeatable user-level defaults by default, including a Dock that shows only running applications; clearing saved Dock pins and sudo-backed power/login settings are explicit opt-ins. Per-device machine identity is set once by [`setup.sh`](./setup.sh), defaulting to `Alberto's MacBook Pro`.

## Bootstrap

[`setup.sh`](./setup.sh) is intentionally a thin entrypoint: it installs or finds `chezmoi`, initializes this repository, and runs `chezmoi apply`.

Machine provisioning lives in [`install`](./install) and is wired into chezmoi through `home/.chezmoiscripts`.

## Testing Changes Safely

Nothing touches `$HOME` until `chezmoi apply`, so preview every change first:

```sh
chezmoi diff                      # exact changes that apply would make
chezmoi apply --dry-run --verbose # rehearse an apply without writing
```

To inspect the rendered output of a template or a target file without applying:

```sh
chezmoi execute-template < home/dot_config/exact_mise/symlink_config.toml.tmpl
chezmoi cat ~/.config/mise/config.toml
```

To materialize the full deployed tree somewhere disposable (skipping `run_` scripts, which would otherwise execute for real):

```sh
chezmoi apply --destination /tmp/fakehome --exclude scripts
```

Note that `chezmoi apply` refuses to overwrite a target file that changed since the last apply unless given `--force`, which protects uncommitted edits in `$HOME`.

For end-to-end bootstrap testing (`setup.sh`, `run_once_` scripts, Brewfiles, SSH keygen), use an isolated environment: a second macOS user account is the cheapest option, and a macOS VM via [Tart](https://tart.run) or UTM gives a true blank slate that can be snapshotted and retried.
