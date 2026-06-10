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

## Files

| Source path | Target or behavior | Role |
| --- | --- | --- |
| `.chezmoi.yaml.tmpl` | chezmoi config template | Sets small data values used while rendering templates. Today it records the active platform, OS, and architecture. |
| `.chezmoiignore` | chezmoi ignore file | Keeps repository-only files out of `$HOME` and leaves room for future platform-specific exclusions. |
| `.chezmoiscripts/macos/run_once_before_01-install-command-line-tools.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs or verifies Xcode Command Line Tools before other installers run. |
| `.chezmoiscripts/macos/run_once_before_02-install-homebrew.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs or activates Homebrew. |
| `.chezmoiscripts/macos/run_once_before_03-install-nanobrew.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs nanobrew. Runtime PATH is managed by `.zprofile`, not by the installer side effect. |
| `.chezmoiscripts/macos/run_once_before_04-install-nanobrew-casks.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs nanobrew cask bundles after the `nb` binary exists. |
| `.chezmoiscripts/macos/run_once_before_05-install-nanobrew-formulae.sh.tmpl` | one-time pre-apply script | On Apple Silicon macOS, installs nanobrew formula bundles after casks are handled. |
| `dot_zprofile.tmpl` | `~/.zprofile` | Login-shell setup for PATH entries such as `~/.local/bin`, Homebrew, and nanobrew. |
| `dot_zshenv` | `~/.zshenv` | Minimal zsh environment loaded by every zsh invocation. Keep this file cheap and side-effect-light. |
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
