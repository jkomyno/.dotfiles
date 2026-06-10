# home

This directory is the chezmoi source root for files that should be applied into `$HOME`.

The repository root has `.chezmoiroot` set to `home`, so chezmoi reads this directory as if it were the top of your home directory. A normal file here would be copied into `$HOME` unless a chezmoi rule says otherwise.

## Naming Rules

chezmoi encodes target paths in source filenames:

- `dot_foo` becomes `~/.foo`
- `dot_config/app/config.toml` becomes `~/.config/app/config.toml`
- `*.tmpl` files are rendered as Go templates before being applied
- `.chezmoi*` files and directories configure chezmoi itself
- `.chezmoiscripts/*` files are executed by chezmoi during `chezmoi apply`

Because this README is only for repository documentation, `.chezmoiignore` excludes it from the apply step.

## Tool Ownership

`dot_mise/config.toml` owns global language runtimes and command-line development tools. Project-level `mise.toml` files should override those defaults when reproducibility matters.

`dot_config/exact_mise/symlink_config.toml.tmpl` exposes that source file as `~/.config/mise/config.toml`. `.chezmoitemplates/chezmoiignore.d/common` keeps `dot_mise` source-only so chezmoi does not also deploy `~/.mise`.

`dot_config/uv/symlink_uv.toml.tmpl` exposes `dot_uv/uv.toml` as `~/.config/uv/uv.toml`, matching the upstream uv layout while keeping `dot_uv` source-only.

nanobrew bundles under `../install/macos/common` own GUI apps, fonts, and only the rare formula that mise cannot handle. Avoid duplicating CLI tools across both systems.

## Files

| Source path | Target or behavior | Role |
| --- | --- | --- |
| `.chezmoi.yaml.tmpl` | chezmoi config template | Sets small data values used while rendering templates. Today it records the active platform, OS, and architecture. |
| `.chezmoiignore` | chezmoi ignore file | Keeps repository-only files out of `$HOME` and includes shared ignore patterns. |
| `.chezmoitemplates/chezmoiignore.d/common` | ignore template | Shared ignore patterns for ported source-only trees such as `dot_mise` and `dot_uv`. |
| `.chezmoiscripts/common/run_once_after_02-install-mise.sh.tmpl` | one-time post-apply script | Installs a pinned standalone mise and the globally configured language tools after `~/.config/mise/config.toml` exists. |
| `.chezmoiscripts/macos/run_once_before_01-install-command-line-tools.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs or verifies Xcode Command Line Tools before other installers run. |
| `.chezmoiscripts/macos/run_once_before_02-install-homebrew.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs or activates Homebrew. |
| `.chezmoiscripts/macos/run_once_before_03-install-nanobrew.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs nanobrew. Runtime PATH is managed by `.zprofile`, not by the installer side effect. |
| `.chezmoiscripts/macos/run_once_before_04-install-nanobrew-casks.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs nanobrew cask bundles after the `nb` binary exists. |
| `.chezmoiscripts/macos/run_once_before_05-install-nanobrew-formulae.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs nanobrew formula bundles after casks are handled. |
| `dot_config/exact_mise/symlink_config.toml.tmpl` | `~/.config/mise/config.toml` | Creates a symlink to the repo-owned mise config. `exact_mise` keeps `~/.config/mise` limited to entries managed here. |
| `dot_config/uv/symlink_uv.toml.tmpl` | `~/.config/uv/uv.toml` | Creates a symlink to the repo-owned uv config. |
| `dot_mise/config.toml` | source-only | Global mise defaults for runtimes and CLI development tools. The common ignore template prevents this from also becoming `~/.mise/config.toml`. |
| `dot_zprofile.tmpl` | `~/.zprofile` | Login-shell setup for PATH entries such as `~/.local/bin`, Homebrew, and nanobrew. |
| `dot_zshrc` | `~/.zshrc` | Interactive zsh setup that activates mise when the binary is available. |
| `dot_zshenv` | `~/.zshenv` | Minimal zsh environment loaded by every zsh invocation. Keep this file cheap and side-effect-light. |
| `dot_uv/uv.toml` | source-only | uv defaults, currently keeping Python package resolution at least seven days behind newest releases. The common ignore template prevents this from also becoming `~/.uv/uv.toml`. |
| `README.md` | ignored | Explains this source tree. It should not be applied to `~/README.md`. |

## How To Work Here

Preview changes before applying them:

```bash
chezmoi diff
chezmoi apply --dry-run --verbose
```

Apply changes:

```bash
chezmoi apply
```

List files managed by chezmoi:

```bash
chezmoi managed
```

When adding a new dotfile, encode the target path in the filename. For example, add `home/dot_gitconfig` if you want chezmoi to manage `~/.gitconfig`.
