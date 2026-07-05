# jkomyno's dotfiles

[![CI](https://github.com/jkomyno/.dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/jkomyno/.dotfiles/actions/workflows/ci.yml)

Automated dotfiles management for my ([jkomyno](https://x.com/jkomyno)) personal development environment.

## Start Here

On a brand-new Apple Silicon Mac with only Terminal available, paste:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"
```

That command downloads [`setup.sh`](./setup.sh), creates `~/work/me`, fetches this repository, installs a bootstrap `mise` binary into `~/.local/bin` if needed, and runs the staged mise setup path. If `git` is not available yet, setup uses a temporary GitHub archive only long enough to install Xcode Command Line Tools, then replaces it with a real git checkout before continuing.

The repository checkout lands at:

```sh
~/work/me/.dotfiles
```

The mise-managed target-shaped source tree is:

```sh
~/work/me/.dotfiles/target/home
```

Useful first-run variants:

```sh
# Do not rename this Mac during bootstrap.
DOTFILES_SKIP_COMPUTER_NAME=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"

# Use a specific machine name.
DOTFILES_COMPUTER_NAME="Alberto's MacBook Pro" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/jkomyno/.dotfiles/main/setup.sh)"
```

After setup finishes, open a new terminal so the managed shell environment is loaded, then run:

```sh
cd ~/work/me/.dotfiles
just doctor
```

`just doctor` checks the source checkout, staged mise setup, target-shaped dotfiles entries, package ownership, and the mise lock refresh path.

## What Setup Does

The root [`setup.sh`](./setup.sh) is intentionally small:

1. Requires `curl`.
2. On macOS, keeps sudo alive for the first run and optionally sets the computer name.
3. Fetches this repository into `~/work/me/.dotfiles`.
4. Installs or finds the pinned standalone `mise` binary.
5. Runs the staged mise setup order from `scripts/dotfiles/mise-setup-staged.sh`.

The staged setup path generates an SSH key (step 1), installs or checks Xcode Command Line Tools, Homebrew, nanobrew, GUI apps/fonts, exceptional formulae, applies the mise `[dotfiles]` entries, installs the configured mise toolchain, runs Git/GitHub setup, pulls Ollama models, installs MLX tooling, and applies repeatable macOS defaults last.

Linux is not a full provisioning target yet. The shared dotfiles and diagnostics are expected to work, while macOS package/default hooks skip themselves until this repository grows a real Linux profile.

## Overview

These dotfiles:
- use [`mise` dotfiles](https://mise.jdx.dev/) for managed files
- target macOS (Apple Silicon)
- use [`mise`](https://mise.jdx.dev/) for language runtimes and CLI developer tools
- use [`nanobrew`](https://github.com/justrach/nanobrew), a faster Homebrew alternative, for macOS apps, fonts, and exceptional formulae
- include configurations for zsh, Git, GitHub CLI, Ghostty, tmux, Neovim/LazyVim, hunk, ghui, mise, uv, macOS preferences, and local AI agent skills

The managed source tree lives under [`target/home`](./target/home).

## Tool Ownership

[`target/home/.config/mise/config.toml`](./target/home/.config/mise/config.toml) is the source of truth for language runtimes and command-line development tools. This includes Node.js, Python, Rust, package managers, linters, formatters, search tools, and other CLIs that mise can install. The staged setup applies the mise dotfiles entry to expose it as `~/.config/mise/config.toml`.

Git and GitHub configuration lives under [`target/home/.config/git`](./target/home/.config/git) and [`target/home/.config/gh/config.yml`](./target/home/.config/gh/config.yml). GitHub CLI authentication state is intentionally not tracked; `gh` stores tokens in the system credential store and `~/.config/gh/hosts.yml`. Bootstrap generates an Ed25519 SSH key when no keypair exists, and the GitHub setup script uploads the public key as a signing key once `gh` is authenticated.

[`install/macos/common/nanobrew-casks.Brewfile`](./install/macos/common/nanobrew-casks.Brewfile) owns GUI apps and fonts. [`install/macos/common/nanobrew-formulae.Brewfile`](./install/macos/common/nanobrew-formulae.Brewfile) should stay empty unless a required package has no practical mise backend.

Do not install the same CLI in both mise and nanobrew.

## Agent Configuration

Coding-agent configuration follows a shared-canonical-plus-adapters layout inspired by [shunk031/dotfiles](https://github.com/shunk031/dotfiles):

- [`target/home/.agents`](./target/home/.agents) is the shared layer, deployed to `~/.agents`. `AGENTS.md` holds instructions common to every harness, and `skills/` holds both first-party skills and vendored third-party skills as real files. Each third-party skill is mapped to its upstream repository in [`sync-skills/manifest.json`](./target/home/.agents/skills/sync-skills/manifest.json); the `sync-skills` skill (inspired by dmmulroy's `sync-pocock-skills`) updates vendored copies from upstream while re-applying local modifications stored as patch files.
- [`target/home/.claude`](./target/home/.claude) deploys Claude Code's global `settings.json`, `CLAUDE.md` (which imports `~/.agents/AGENTS.md`), hooks, and a `~/.claude/skills` symlink into `~/.agents/skills`. The plugins that `settings.json` enables are made reproducible by [`install/common/agents.sh`](./install/common/agents.sh), which reads [`scripts/dotfiles/agent-plugins.json`](./scripts/dotfiles/agent-plugins.json) and registers each marketplace and installs each plugin. It runs during staged setup and on `just update plugins`, and skips gracefully when the `claude` CLI is not installed yet.
- [`target/home/.codex`](./target/home/.codex) deploys a curated `~/.codex/config.toml` and `AGENTS.md` (which defers to `~/.agents/AGENTS.md`). The Codex CLI itself is provisioned via mise (`npm:@openai/codex`). Codex needs no skill symlinks: it scans `~/.agents/skills/` natively (its own `~/.codex/skills/` location is deprecated upstream). Codex plugins declared in [`scripts/dotfiles/agent-plugins.json`](./scripts/dotfiles/agent-plugins.json) are also converged by `install/common/agents.sh`.
- [`target/home/.pi`](./target/home/.pi) deploys pi's `~/.pi/agent/settings.json` and the managed `~/.pi/agent/extensions/agentmemory` extension; the pi CLI is provisioned via mise (`npm:@earendil-works/pi-coding-agent`) and auto-discovers `~/.agents/skills`, so no per-skill wiring is needed.
- [`agentmemory`](https://github.com/rohitg00/agentmemory) is the shared persistent memory layer for Claude Code, Codex, and pi. The CLI is provisioned via mise (`npm:@agentmemory/agentmemory`), Claude/Codex plugin installation is declared in `agent-plugins.json`, and pi uses the vendored extension under `target/home/.pi/agent/extensions/agentmemory`. Start the local server with `agentmemory`; it serves the memory API on `http://localhost:3111` and the viewer on `http://localhost:3113`.

All three harnesses (Claude Code, Codex, pi) read the same first-party and vendored skills from `~/.agents/skills`. Plugin-delivered skills are host-specific; to expose a skill to every harness, vendor it into `~/.agents/skills` via `sync-skills`.

Only curated configuration is tracked. Runtime state in `~/.claude` (sessions, history, caches), `~/.codex` (the `[projects.*]` trust list, `rules/`, sqlite databases), and `~/.agentmemory` (memory database, engine state, optional `.env`) stays unmanaged; mise dotfiles only applies the explicit entries in [`mise.toml`](./mise.toml). Skill directories not listed in this repository (for example one-off installs by other tooling) are left alone. To take a previously installed skill under management, vendor it via `sync-skills` instead of editing the deployed copy.

Per-idea reference corpora (pinned shallow clones of upstream repositories, blog-post snapshots, and agent-written digests) live under `~/.jk/ideas/<name>` and are managed by the first-party `jk-cli` skill. Projects opt in through an `AGENTS.local.md` at the repository root — hidden by the global gitignore and read by every harness via the shared `AGENTS.md` — so reference material never appears in a project's git history. `~/.jk` is machine state owned by the `jk` CLI and is not managed by these dotfiles.

macOS user preferences live in [`install/macos/common/defaults.sh`](./install/macos/common/defaults.sh) and are applied through the staged setup task `install:macos:defaults`. The script handles repeatable user-level defaults by default, including a Dock that shows only running applications; clearing saved Dock pins and sudo-backed power/login settings are explicit opt-ins. Per-device machine identity is set once by [`setup.sh`](./setup.sh), defaulting to `Alberto's MacBook Pro`.

## Maintenance

Repeatable operator tasks live in the root [`Justfile`](./Justfile). After `setup.sh` has installed the managed mise toolchain, run:

```sh
just doctor             # non-mutating repository, setup, package, and toolchain checks
just status             # source git status
just diff               # mise dotfiles dry-run against the current HOME
just packages           # validate package ownership and report installed/missing macOS packages
just versions           # check third-party mise versions and lock refreshes without writing
just sync-skills-check  # compare vendored agent skills with upstream
just dotfiles-check     # validate the mise dotfiles slice in a temporary HOME
just setup-smoke        # run the safe staged setup subset in a temporary HOME
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

`versions-update` preserves configured version ranges such as `node = "24"` and refreshes [`target/home/.config/mise/mise.lock`](./target/home/.config/mise/mise.lock) for Linux and macOS, x64 and arm64. Use `scripts/dotfiles/versions.sh --write --bump` only when you intentionally want to change requested versions in [`target/home/.config/mise/config.toml`](./target/home/.config/mise/config.toml).

### Updating everything

One command updates every managed layer, or just one component:

```sh
just update              # mise tools, casks, formulae, agent plugins, skills report, dotfiles apply
just update-check        # non-mutating preview of the same

just update mise         # upgrade mise-managed CLIs/runtimes and refresh the lockfile
just update casks        # converge and upgrade GUI apps and fonts (nanobrew or Homebrew)
just update plugins      # register Claude/Codex marketplaces and update enabled plugins
just update skills       # report vendored agent-skill drift (apply with /sync-skills)
just update codex        # upgrade just the Codex CLI (subset of `just update mise`)
just update agentmemory  # upgrade just the agentmemory CLI (subset of `just update mise`)
just update self         # git pull --ff-only, then re-apply mise dotfiles to $HOME
```

Like every recipe, the updater is backed by a plain script so a machine without
`just` can run it directly: `bash scripts/dotfiles/update.sh [--check] [component ...]`.
Each component updates its own store: `mise` upgrades installed tools and refreshes
the tracked lockfile, `casks`/`formulae` update installed apps, `plugins` updates
agent plugin state, and `skills` only reports. Only `self` re-applies managed
dotfiles to `$HOME`, and `mise dotfiles apply` refuses to overwrite existing
whole-file targets without `--force`.

To pull repo changes on an already-provisioned machine:

```sh
cd ~/work/me/.dotfiles
git pull --ff-only
mise dotfiles apply --yes
```

The managed [`mise.toml`](./mise.toml) and `~/.config/mise/config.toml` both set
`experimental = true`, so `mise dotfiles` commands run without a
`MISE_EXPERIMENTAL=true` prefix. `setup.sh` also marks this repo's `mise.toml` as
trusted so these commands work directly. If mise ever reports the config is not
trusted (for example on a machine provisioned before this was added), run `mise
trust` once from the checkout.

## Testing Changes Safely

Use the dotfiles checks for managed-file work; they apply only to temporary homes:

```sh
just dotfiles-check
just setup-smoke
```

To inspect what mise dotfiles would do against the current `$HOME` without applying:

```sh
mise dotfiles status
mise dotfiles apply --dry-run
```

Note that `mise dotfiles apply` refuses to overwrite existing whole-file targets unless given `--force`.

For end-to-end bootstrap testing (`setup.sh`, staged setup tasks, Brewfiles, SSH keygen), use an isolated environment: a second macOS user account is the cheapest option, and a macOS VM via [Tart](https://tart.run) or UTM gives a true blank slate that can be snapshotted and retried.

## License

Released under the [MIT License](./LICENSE). These are personal dotfiles shared as a
reference: they encode one person's preferences and machine identity, and are not
affiliated with any tool they configure. Read what a script does before running it,
and adapt rather than adopt wholesale — the bootstrap one-liner runs remote code and
`setup.sh` changes system settings.
