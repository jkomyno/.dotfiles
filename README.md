# jkomyno's dotfiles

Automated dotfiles management for my ([jkomyno](https://x.com/jkomyno)) personal development environment.

## Start Here

On a brand-new Apple Silicon Mac with only Terminal available, paste:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"
```

That command downloads [`setup.sh`](./setup.sh), installs `chezmoi` into `~/.local/bin` if needed, creates `~/work/me`, fetches this repository with chezmoi's built-in Git support, and applies the managed files. It does not require `git` to be installed first.

By default, the repository checkout lands at:

```sh
~/work/me/dotfiles
```

The managed chezmoi source root is the `home` subdirectory inside that checkout because this repository uses [`.chezmoiroot`](./.chezmoiroot):

```sh
~/work/me/dotfiles/home
```

The managed files are applied from that source root into `$HOME`. Verify it at any time with `chezmoi source-path`.

Useful first-run variants:

```sh
# Do not rename this Mac during bootstrap.
DOTFILES_SKIP_COMPUTER_NAME=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"

# Use a specific machine name.
DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"

# Bootstrap a branch other than main.
DOTFILES_BRANCH=my-branch /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"

# Use a different parent directory.
DOTFILES_WORK_DIR="$HOME/work/personal" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"

# Use an exact checkout directory.
DOTFILES_CHECKOUT_DIR="$HOME/src/dotfiles" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"
```

If this repository is private, the raw `curl` command and the later `chezmoi init` both need read access. The clean path is to make the repository readable for bootstrap or provide a short-lived HTTPS credential for the first fetch, then switch the remote back to SSH after `gh auth login` and SSH-key upload have completed.

After setup finishes, open a new terminal so the managed shell environment is loaded, then run:

```sh
cd ~/work/me/dotfiles
just doctor
```

`just doctor` checks the source checkout, rendered chezmoi templates, package ownership, and the mise lock refresh path.

## What Setup Does

The root [`setup.sh`](./setup.sh) is intentionally small:

1. Requires `curl`.
2. On macOS, keeps sudo alive for the first run and optionally sets the computer name.
3. Installs or finds `chezmoi`.
4. Runs `chezmoi init` with `--use-builtin-git true`.
5. Runs `chezmoi apply`.

The apply step runs the provisioning hooks under [`home/.chezmoiscripts`](./home/.chezmoiscripts). On macOS Apple Silicon, those hooks install Xcode Command Line Tools, Homebrew, nanobrew, GUI apps/fonts, exceptional formulae, the standalone mise binary, the configured mise toolchain, SSH/Git/GitHub setup, Ollama models, and repeatable macOS defaults.

Linux is not a full provisioning target yet. The shared dotfiles and diagnostics are expected to work, while macOS package/default hooks skip themselves until this repository grows a real Linux profile.

## Overview

These dotfiles:
- are managed by [`chezmoi`](https://www.chezmoi.io/)
- target macOS (Apple Silicon)
- use [`mise`](https://mise.jdx.dev/) for language runtimes and CLI developer tools
- use [`nanobrew`](https://github.com/justrach/nanobrew), a faster Homebrew alternative, for macOS apps, fonts, and exceptional formulae
- include configurations for zsh, Git, GitHub CLI, Ghostty, tmux, Neovim/LazyVim, hunk, ghui, mise, uv, macOS preferences, and local AI agent skills

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
- [`home/dot_codex`](./home/dot_codex) deploys a curated `~/.codex/config.toml` and `AGENTS.md` (which defers to `~/.agents/AGENTS.md`). Codex needs no skill symlinks: it scans `~/.agents/skills/` natively (its own `~/.codex/skills/` location is deprecated upstream).

Only curated configuration is tracked. Runtime state in `~/.claude` (sessions, history, caches) and `~/.codex` (the `[projects.*]` trust list, `rules/`, sqlite databases) stays unmanaged; chezmoi never touches files it does not list, and none of these directories use `exact_` at the top level. Skill directories not listed in this repository (for example one-off installs by other tooling) are left alone; only the per-skill `exact_` directories are pruned on apply. To take a previously installed skill under management, vendor it via `sync-skills` instead of editing the deployed copy.

Per-idea reference corpora (pinned shallow clones of upstream repositories, blog-post snapshots, and agent-written digests) live under `~/.jk/ideas/<name>` and are managed by the first-party `jk-cli` skill. Projects opt in through an `AGENTS.local.md` at the repository root — hidden by the global gitignore and read by every harness via the shared `AGENTS.md` — so reference material never appears in a project's git history. `~/.jk` is machine state owned by the `jk` CLI (the skill bootstraps `~/.jk/ideas` on first use); chezmoi does not manage it.

macOS user preferences live in [`install/macos/common/defaults.sh`](./install/macos/common/defaults.sh) and are applied through a `run_onchange_after` chezmoi hook. The script handles repeatable user-level defaults by default, including a Dock that shows only running applications; clearing saved Dock pins and sudo-backed power/login settings are explicit opt-ins. Per-device machine identity is set once by [`setup.sh`](./setup.sh), defaulting to `Alberto's MacBook Pro`.

## Maintenance

Repeatable operator tasks live in the root [`Justfile`](./Justfile). After `setup.sh` has installed the managed mise toolchain, run:

```sh
just doctor             # non-mutating repository, chezmoi, package, and toolchain checks
just status             # git status plus deployed-home drift when this checkout is installed
just packages           # validate package ownership and report installed/missing macOS packages
just versions           # check third-party mise versions and lock refreshes without writing
just sync-skills-check  # compare vendored agent skills with upstream
just dotfiles-spike     # run the disposable mise dotfiles migration spike
just dotfiles-check     # validate the mirrored mise dotfiles slice in a temporary HOME
just dotfiles-mirror-check # check mirrored target files still match current sources
```

Every recipe is backed by a plain script under [`scripts/dotfiles`](./scripts/dotfiles), so a fresh machine without `just` can run the same checks directly, for example:

```sh
bash scripts/dotfiles/doctor.sh
bash scripts/dotfiles/versions.sh --check
```

Mutating maintenance commands are explicit:

```sh
just versions-update
bash scripts/dotfiles/versions.sh --write
```

`versions-update` preserves configured version ranges such as `node = "24"` and refreshes [`home/dot_mise/mise.lock`](./home/dot_mise/mise.lock) for Linux and macOS, x64 and arm64. Use `scripts/dotfiles/versions.sh --write --bump` only when you intentionally want to change requested versions in [`home/dot_mise/config.toml`](./home/dot_mise/config.toml).

To pull repo changes on an already-provisioned machine:

```sh
chezmoi update
```

This checkout may also be used as a planning or migration workspace before it
has ever been applied to the current `$HOME`. In that case, deployed-home drift
is not meaningful. `just status` and `just diff` skip the chezmoi comparison
unless the active chezmoi source is this checkout's `home/` directory. To force
the comparison for diagnostics:

```sh
DOTFILES_FORCE_CHEZMOI_DRIFT=1 just status
DOTFILES_FORCE_CHEZMOI_DRIFT=1 just diff
```

The staged migration away from chezmoi is tracked in [`MIGRATION.md`](./MIGRATION.md).

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
