# jkomyno's dotfiles

[![CI](https://github.com/jkomyno/.dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/jkomyno/.dotfiles/actions/workflows/ci.yml)

My ([jkomyno](https://x.com/jkomyno)) personal development environment for Apple Silicon Macs. One command provisions a factory-fresh machine end to end, `just doctor` verifies the result, and `just update` keeps every layer current after that.

Three decisions shape the whole repository:

- **mise manages the dotfiles themselves, not just the toolchain.** Most dotfiles managers make you encode metadata in filenames (chezmoi's `dot_zshrc` and `exact_` prefixes) or maintain a symlink farm by hand. This repo uses mise's experimental [`[dotfiles]`](https://mise.jdx.dev/) feature instead: the source tree under [`target/home`](./target/home) reads exactly like `$HOME`, and a table in [`mise.toml`](./mise.toml) declares how each entry deploys (symlink, copy, or template). The tool that pins my language runtimes and CLIs also places my config files, so one manager does the work of two.
- **One skills layer feeds three coding agents.** Claude Code, Codex, and pi all read the same `~/.agents/skills` directory. Third-party skills are vendored as real files and kept current from upstream by the `sync-skills` skill, with local modifications preserved as patches; shared instructions and persistent agent memory follow the same pattern. Details in [Agent Configuration](#agent-configuration).
- **The repo tests itself.** `just doctor` syntax-checks every shell script, validates the mise task graph, runs the staged setup against a throwaway `$HOME`, and dry-runs the lockfile refresh for four platforms. CI runs it on every push; the badge above is the result.

Beyond that, mise owns language runtimes and CLI tools, [nanobrew](https://github.com/justrach/nanobrew) owns GUI apps and fonts, the tracked configuration covers zsh, fish, Git, GitHub CLI, Ghostty, tmux, Neovim/LazyVim, starship, hunk, ghui, uv, macOS defaults, and the coding-agent stack, and [Tailscale](https://tailscale.com), Screen Sharing, and [Paseo](https://paseo.sh) (drive local agents from your phone) make a Mac reachable remotely over the tailnet.

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

`just doctor` checks the source checkout, staged mise setup, target-shaped dotfiles entries, package ownership, the mise lock refresh path, and whether `gh`, `codex`, and `claude` are authenticated.

Then sign in to the coding-agent CLIs (the one step setup cannot do for you, because these credentials are never tracked):

```sh
just auth
```

This drives the interactive login for `gh`, `codex`, and `claude`, skipping any that are already authenticated. See [Authentication](#authentication) for details.

## What Setup Does

The root [`setup.sh`](./setup.sh) is intentionally small:

1. Requires `curl`.
2. On macOS, keeps sudo alive for the first run and optionally sets the computer name.
3. Fetches this repository into `~/work/me/.dotfiles`.
4. Installs or finds the pinned standalone `mise` binary.
5. Runs the staged mise setup order from `scripts/dotfiles/mise-setup-staged.sh`.

The staged setup path generates an SSH key (step 1), installs or checks Xcode Command Line Tools, nanobrew, GUI apps/fonts, exceptional formulae, installs the tailscaled system daemon, applies the mise `[dotfiles]` entries, installs the configured mise toolchain, loads the paseo and agentmemory daemons, runs Git/GitHub setup, pulls Ollama models, installs MLX tooling, and applies repeatable macOS defaults last.

Linux is not a full provisioning target yet. The shared dotfiles and diagnostics are expected to work, while macOS package/default hooks skip themselves until this repository grows a real Linux profile.

## Authentication

Setup never stores CLI credentials: `gh` keeps its token in the system keyring, while `codex` and `claude` use browser OAuth tied to a subscription. None of that belongs in a git checkout, so signing in is the one manual step after provisioning. [`scripts/dotfiles/auth.sh`](./scripts/dotfiles/auth.sh) drives it:

```sh
just auth          # log in to gh, codex, and claude (skips any already authenticated)
just auth-check    # report status only; never launches a login flow
```

`just auth` is idempotent — an already-authenticated tool is left untouched, and a tool not installed yet is skipped. `just doctor` reports the same status as warnings (authentication is a manual step, never a hard failure). Once `gh` is authenticated, re-running the GitHub setup step (`mise run install:common:gh`, part of staged setup) uploads your SSH signing key and installs the configured `gh` extensions.

## Remote Machines: TouchID SSH and Passwordless Sudo

Two optional conveniences for driving another Mac (for example over `ssh`):

- **TouchID for SSH.** [Secretive](https://github.com/maxgoedjen/secretive) stores an SSH key in the Secure Enclave and gates every use behind TouchID. Only the `secretive` cask is tracked; the per-host wiring lives in the unmanaged `~/.ssh/config.local` (a global `IdentityAgent` would hijack every host), so a fresh machine is unaffected until you opt a host in. Full walkthrough in [`docs/touchid-ssh.md`](./docs/touchid-ssh.md).
- **Passwordless sudo.** To stop `sudo` prompting on a machine you administer often, [`install/macos/common/sudoers-nopasswd.sh`](./install/macos/common/sudoers-nopasswd.sh) installs a `visudo`-validated `/etc/sudoers.d` drop-in:

  ```sh
  just nopasswd-sudo            # enable for the current user (needs your password once)
  just nopasswd-sudo --check    # report whether it is active
  just nopasswd-sudo --remove   # undo
  ```

  This is a deliberate security trade-off — anyone with a shell as your user then has root without a password — so it is strictly opt-in. It stays a no-op inside staged setup unless `DOTFILES_ENABLE_NOPASSWD_SUDO=1` is set. Note that macOS TouchID (`pam_tid`) cannot authorize `sudo` inside an SSH session, so passwordless sudo — not TouchID — is the way to silence remote sudo prompts.

## Remote Access: Tailscale, Screen Sharing, and Paseo

Three layers for reaching a Mac you drive remotely (the intended combination is Tailscale for private connectivity, then Screen Sharing and Paseo reachable over the tailnet — nothing is exposed publicly):

- **Tailscale (headless daemon).** The `tailscale` Homebrew formula ships `tailscale` and `tailscaled`; it lives in [`nanobrew-formulae.Brewfile`](./install/macos/common/nanobrew-formulae.Brewfile) rather than mise because it needs a root LaunchDaemon, not just a versioned CLI. Staged setup runs [`install/macos/common/tailscale.sh`](./install/macos/common/tailscale.sh), which installs the `tailscaled` system daemon (`install-system-daemon`, needs sudo once) and then guides joining your tailnet. Authentication is interactive by design (browser SSO), so — like `just auth` — it is the one manual step: run `tailscale up` (or set `TAILSCALE_AUTHKEY` to join non-interactively). Re-run any time with `just tailscale`; skip in setup with `DOTFILES_SKIP_TAILSCALE=1`.

  ```sh
  just tailscale        # (re)install the daemon and guide `tailscale up`
  tailscale up          # join the tailnet (opens a browser login URL)
  ```

- **Screen Sharing (native mac-to-mac VNC, opt-in).** [`install/macos/common/screen-sharing.sh`](./install/macos/common/screen-sharing.sh) uses Apple's `kickstart` to activate the Remote Management agent (which serves Screen Sharing) and grant access to all local users, so another Mac connects over `vnc://` and signs in with this machine's account password. It is Apple-to-Apple only — legacy (plaintext) VNC stays disabled. `kickstart` (not a bare `launchctl` load) is required so access is actually configured; enable runs a clean deactivate→activate cycle, which is the headless form of Apple's "disable and re-enable" recovery. Because remote screen access widens the attack surface, it is strictly opt-in and never runs during staged setup:

  ```sh
  just screen-sharing            # enable (needs sudo once)
  just screen-sharing --check    # report whether it is enabled
  just screen-sharing --remove   # disable
  ```

  Then, from another Mac: Finder → Go → Connect to Server → `vnc://<tailscale-ip>` and log in. **macOS 14+ caveat:** the Screen Recording/Control entitlement is TCC-gated and cannot be granted from the CLI — if a client connects but the screen is black or refused, toggle Screen Sharing ON once in System Settings → General → Sharing on the target Mac. That one grant is GUI/MDM-only; everything else the script handles.

- **Paseo (drive local agents from your phone).** [Paseo](https://paseo.sh) runs your local coding agents (Claude Code, Codex, pi) and lets the phone/web app control them. The CLI is a mise tool (`npm:@getpaseo/cli`); the always-on daemon is a tracked LaunchAgent ([`sh.paseo.daemon.plist`](./target/home/Library/LaunchAgents/sh.paseo.daemon.plist)) that runs `paseo daemon start --foreground --listen 0.0.0.0:6767 --hostnames true` so the phone can reach it over Tailscale. It launches paseo through `mise exec npm:@getpaseo/cli` (not a shim, which isn't generated on activate-mode machines), and `--foreground` is required so launchd doesn't respawn-loop a self-daemonizing process. Staged setup loads it via [`install/common/paseo.sh`](./install/common/paseo.sh); it restarts on every login.

  ```sh
  just paseo            # load / restart the daemon LaunchAgent
  just paseo --pair     # print the pairing QR/link for the phone app
  just paseo --status   # show agent + daemon status and the connect URL
  just paseo --remove   # unload
  ```

  Pairing is one-time: `just paseo --pair` (or add `http://<tailscale-ip>:6767` in the phone app), then approve.

## Always-on Background Services

A few tools this repo installs are only useful while a process of theirs stays running — a long-lived service that must survive logout and reboot and restart itself if it crashes, not something you start by hand. On macOS that is a launchd job: a **LaunchDaemon** (system-wide, runs as root, in `/Library/LaunchDaemons`) or a **LaunchAgent** (per-user, runs in your login GUI session, in `~/Library/LaunchAgents`). Each such service is tracked here — the launchd job as a source file, plus a loader that boots it into the running session — so a service that dies is a `just` command away, not a debugging session. All are enumerated below; nothing else in these dotfiles runs unattended.

| Service | Kind | Started at setup by | Manage | Bound to |
| --- | --- | --- | --- | --- |
| **tailscaled** | system LaunchDaemon (root) | `install:macos:tailscale` | `just tailscale` | tailnet |
| **paseo** | user LaunchAgent | `install:common:paseo` | `just paseo` | `0.0.0.0:6767` (tailnet) |
| **agentmemory** | user LaunchAgent | `install:common:agentmemory` | `just agentmemory` | `localhost:3111` / `:3113` |

- **tailscaled** is a root system daemon installed by Homebrew (`tailscaled install-system-daemon`); it needs sudo once and is not a mise tool. See [Remote Access](#remote-access-tailscale-screen-sharing-and-paseo).
- **paseo** is a user LaunchAgent ([`sh.paseo.daemon.plist`](./target/home/Library/LaunchAgents/sh.paseo.daemon.plist)) that keeps the phone/web bridge reachable over the tailnet. See [Remote Access](#remote-access-tailscale-screen-sharing-and-paseo).
- **agentmemory** is a user LaunchAgent ([`com.agentmemory.daemon.plist`](./target/home/Library/LaunchAgents/com.agentmemory.daemon.plist)) that keeps the shared memory server up so Claude Code, Codex, and pi can save and recall memory at any time; it binds localhost only. Loaded by [`install/common/agentmemory.sh`](./install/common/agentmemory.sh); logs to `~/Library/Logs/agentmemory.daemon.log`. Its iii engine persists a file-based store whose path is cwd-relative, so the LaunchAgent sets `WorkingDirectory=~/.agentmemory` to keep the store at `~/.agentmemory/data` (not a stray `~/data`). Two behaviours worth knowing: the store only rehydrates on a full engine restart (reboot/logout or `agentmemory stop`), not a worker-only `launchctl kickstart`; and after a restart the REST health endpoint answers a few seconds before the store finishes loading, so `agentmemory status` can briefly report `Memories: 0` while it hydrates.

  ```sh
  just agentmemory            # load / restart the daemon LaunchAgent
  just agentmemory --status   # report agent state + server health
  just agentmemory --remove   # unload
  ```

Both user LaunchAgents use the same shape: a `template`-mode plist tracked under [`target/home/Library/LaunchAgents/`](./target/home/Library/LaunchAgents) (registered in [`mise.toml`](./mise.toml) so `mise dotfiles apply` renders it with the real `$HOME`), `RunAtLoad` + `KeepAlive` so they start on login and respawn on crash, and a loader script that runs the tool through `mise exec` (a shim is not always generated) and bootstraps the agent into the live GUI session. They need an active desktop login to bootstrap — over SSH they load on the next console login. To add another always-on service, copy that shape and add a row above.

Not every server here is always-on: **Ollama** is deliberately on-demand — [`install/common/ollama-models.sh`](./install/common/ollama-models.sh) starts a temporary `ollama serve` only while pulling models and stops it afterward, so there is no Ollama LaunchAgent.

## Repository Layout

Shell scripts live in three trees, and each tree has one job:

- [`install/`](./install) holds the implementation of first-run provisioning: standalone, idempotent scripts (SSH keygen, nanobrew, Git/GitHub setup, macOS defaults) plus the package bundles. Every script runs on its own, without mise.
- [`tasks/`](./tasks) holds thin [mise task](https://mise.jdx.dev/tasks/) wrappers, a few lines each, that `exec` into `install/` or `scripts/dotfiles/`. They exist only to give scripts stable task names (`install:common:git`, `setup:staged`), declared dependencies, and a place in the staged setup order. No logic lives here.
- [`scripts/dotfiles/`](./scripts/dotfiles) holds repeatable maintenance and diagnostics (`doctor.sh`, `update.sh`, `versions.sh`), each exposed as a `Justfile` recipe. These run for the life of the machine, not just at first setup.

So the same file can be reached three ways: `bash install/common/git.sh` directly, `mise run install:common:git` through its task wrapper, or as one step of `setup.sh`'s staged order. Pick the layer that matches how much orchestration you want.

## Tool Ownership

[`target/home/.config/mise/config.toml`](./target/home/.config/mise/config.toml) is the source of truth for language runtimes and command-line development tools. This includes Node.js, Python, Rust, package managers, linters, formatters, search tools, and other CLIs that mise can install. The staged setup applies the mise dotfiles entry to expose it as `~/.config/mise/config.toml`.

Git and GitHub configuration lives under [`target/home/.config/git`](./target/home/.config/git) and [`target/home/.config/gh/config.yml`](./target/home/.config/gh/config.yml). GitHub CLI authentication state is intentionally not tracked; `gh` stores tokens in the system credential store and `~/.config/gh/hosts.yml`. Bootstrap generates an Ed25519 SSH key when no keypair exists, and the GitHub setup script uploads the public key as a signing key once `gh` is authenticated.

[`install/macos/common/nanobrew-casks.Brewfile`](./install/macos/common/nanobrew-casks.Brewfile) owns GUI apps and fonts. [`install/macos/common/nanobrew-formulae.Brewfile`](./install/macos/common/nanobrew-formulae.Brewfile) should stay empty unless a required package has no practical mise backend.

Do not install the same CLI in both mise and nanobrew.

## Agent Configuration

Coding-agent configuration follows a shared-canonical-plus-adapters layout inspired by [shunk031/dotfiles](https://github.com/shunk031/dotfiles):

- [`target/home/.agents`](./target/home/.agents) is the shared layer, deployed to `~/.agents`. `AGENTS.md` holds instructions common to every harness, and `skills/` holds both first-party skills and vendored third-party skills as real files. Each third-party skill is mapped to its upstream repository in [`sync-skills/manifest.json`](./target/home/.agents/skills/sync-skills/manifest.json); the `sync-skills` skill (inspired by dmmulroy's `sync-pocock-skills`) updates vendored copies from upstream while re-applying local modifications stored as patch files.
- [`target/home/.claude`](./target/home/.claude) deploys Claude Code's global `settings.json`, `CLAUDE.md` (which imports `~/.agents/AGENTS.md`), and hooks. Claude's `~/.claude/skills` remains a real, host-owned directory because plugins and local tools install their own skills there; [`scripts/dotfiles/claude-skill-links.sh`](./scripts/dotfiles/claude-skill-links.sh) adds per-skill links into the shared `~/.agents/skills` tree without replacing those host-owned entries. The plugins that `settings.json` enables are made reproducible by [`install/common/agents.sh`](./install/common/agents.sh), which reads [`scripts/dotfiles/agent-plugins.json`](./scripts/dotfiles/agent-plugins.json) and registers each marketplace and installs each plugin. It runs during staged setup and on `just update plugins`, and skips gracefully when the `claude` CLI is not installed yet.
- [`target/home/.codex`](./target/home/.codex) deploys a curated `~/.codex/config.toml` and `AGENTS.md` (which defers to `~/.agents/AGENTS.md`). The Codex CLI itself is provisioned via mise (`npm:@openai/codex`). Codex needs no skill symlinks: it scans `~/.agents/skills/` natively (its own `~/.codex/skills/` location is deprecated upstream). Codex plugins declared in [`scripts/dotfiles/agent-plugins.json`](./scripts/dotfiles/agent-plugins.json) are also converged by `install/common/agents.sh`.
- [`target/home/.pi`](./target/home/.pi) deploys pi's `~/.pi/agent/settings.json` and the managed `~/.pi/agent/extensions/agentmemory` extension; the pi CLI is provisioned via mise (`npm:@earendil-works/pi-coding-agent`) and auto-discovers `~/.agents/skills`, so no per-skill wiring is needed.
- [`agentmemory`](https://github.com/rohitg00/agentmemory) is the shared persistent memory layer for Claude Code, Codex, and pi. The CLI is provisioned via mise (`npm:@agentmemory/agentmemory`), Claude/Codex plugin installation is declared in `agent-plugins.json`, and pi uses the vendored extension under `target/home/.pi/agent/extensions/agentmemory`. Its memory API (`http://localhost:3111`) and viewer (`http://localhost:3113`) must be running for `memory_save`/`memory_search` to work, so the server runs as an always-on LaunchAgent rather than something started by hand — see [Always-on Background Services](#always-on-background-services). Manage it with `just agentmemory`.

All three harnesses (Claude Code, Codex, pi) read the same first-party and vendored skills from `~/.agents/skills`. Plugin-delivered skills are host-specific; to expose a skill to every harness, vendor it into `~/.agents/skills` via `sync-skills`.

Only curated configuration is tracked. Runtime state in `~/.claude` (sessions, history, caches, host-specific skills), `~/.codex` (the `[projects.*]` trust list, `rules/`, sqlite databases), and `~/.agentmemory` (memory database, engine state, optional `.env`) stays unmanaged; mise dotfiles only applies the explicit entries in [`mise.toml`](./mise.toml). Skill directories not listed in this repository (for example one-off installs by other tooling) are left alone. To take a previously installed skill under management, vendor it via `sync-skills` instead of editing the deployed copy.

Per-idea reference corpora (pinned shallow clones of upstream repositories, blog-post snapshots, and agent-written digests) live under `~/.jk/ideas/<name>` and are managed by the first-party `jk-cli` skill. Projects opt in through an `AGENTS.local.md` at the repository root (hidden by the global gitignore and read by every harness via the shared `AGENTS.md`), so reference material never appears in a project's git history. `~/.jk` is machine state owned by the `jk` CLI and is not managed by these dotfiles.

macOS user preferences live in [`install/macos/common/defaults.sh`](./install/macos/common/defaults.sh) and are applied through the staged setup task `install:macos:defaults`. The script handles repeatable user-level defaults by default, including a Dock that shows only running applications; clearing saved Dock pins and sudo-backed power/login settings are explicit opt-ins. Per-device machine identity is set once by [`setup.sh`](./setup.sh), defaulting to `Alberto's MacBook Pro`.

## Encrypted Secrets

Per-project secrets are stored encrypted inline in each project's `mise.toml` via mise's built-in [`age`](https://mise.jdx.dev/environments/secrets/age.html) support and decrypted automatically at runtime. The global wiring — the experimental flag and the `[settings.age] ssh_identity_files` setting that uses `~/.ssh/id_ed25519` as the age identity — is tracked in [`target/home/.config/mise/config.toml`](./target/home/.config/mise/config.toml), so a new machine needs only your passphrase-protected SSH key in place. Setup, the `age-keygen`-vs-SSH-key rationale, and the portability caveats are in [`docs/encrypted-secrets.md`](./docs/encrypted-secrets.md).

## Shortcuts

Every keybinding and shell shortcut this repo configures — tmux, Neovim/LazyVim, Ghostty, and zsh/fish — is catalogued in [`docs/shortcuts.md`](./docs/shortcuts.md).

## Changing These Dotfiles

Most changes touch three things: the tracked source, the ownership manifest, and
the check that proves the manifest still works. Keep those in the same change.

- **Managed dotfiles:** edit files under [`target/home`](./target/home), then add or update the matching `[dotfiles]` entry in [`mise.toml`](./mise.toml). For copy or template targets, update [`scripts/dotfiles/mise-dotfiles-check.sh`](./scripts/dotfiles/mise-dotfiles-check.sh) when the rendered content matters. Verify with `just dotfiles-check`; use `mise dotfiles apply --dry-run` to preview the current `$HOME`.
- **Setup steps:** put first-run machine logic in [`install/`](./install), add a thin wrapper under [`tasks/`](./tasks), wire the explicit setup order in [`scripts/dotfiles/mise-setup-staged.sh`](./scripts/dotfiles/mise-setup-staged.sh), and update [`install/README.md`](./install/README.md) or [`install/macos/README.md`](./install/macos/README.md) when the order changes. Verify with `just tasks-check` and `just setup-smoke`.
- **Tools and apps:** put language runtimes and CLI developer tools in [`target/home/.config/mise/config.toml`](./target/home/.config/mise/config.toml). Put GUI apps and fonts in [`install/macos/common/nanobrew-casks.Brewfile`](./install/macos/common/nanobrew-casks.Brewfile). Use [`install/macos/common/nanobrew-formulae.Brewfile`](./install/macos/common/nanobrew-formulae.Brewfile) only when mise has no practical backend. Verify ownership with `just packages`; use `just versions` or `just versions-update` for the mise lockfile path.
- **Agent configuration:** put shared instructions and vendored skills under [`target/home/.agents`](./target/home/.agents). Declare Claude and Codex plugin installation in [`scripts/dotfiles/agent-plugins.json`](./scripts/dotfiles/agent-plugins.json), and keep Claude's enabled plugin IDs in [`target/home/.claude/settings.json`](./target/home/.claude/settings.json) synchronized. Verify with `just dotfiles-check`, `just update-check plugins`, and JSON validation for edited JSON files.
- **Bootstrap and machine state:** treat [`setup.sh`](./setup.sh), [`install/common/mise.sh`](./install/common/mise.sh), and [`install/macos/common/defaults.sh`](./install/macos/common/defaults.sh) as real machine mutators. Start with non-mutating proof: `just setup-plan`, `just setup-smoke`, `just git-signing-check`, and `bash -n` for changed shell scripts. Use a separate macOS account or VM for a full first-run bootstrap.

Before committing, run `git diff --check` and `git status --short`. For
provisioning changes, run `just doctor` when the local machine has the required
tools. Stage only the intended files; this repo often has unrelated local tool
or lockfile drift.

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
just update casks        # converge and upgrade GUI apps and fonts (nanobrew)
just update plugins      # register Claude/Codex marketplaces and update enabled plugins
just update skills       # report vendored agent-skill drift (apply with /sync-skills)
just update codex        # upgrade just the Codex CLI (subset of `just update mise`)
just update agentmemory  # upgrade just the agentmemory CLI (subset of `just update mise`)
just update self         # pull, re-apply dotfiles, then restore agent adapters
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

First-party content is released under the [MIT License](./LICENSE). Skills vendored
under `target/home/.agents/skills/` remain under their upstream licenses; see
[THIRD-PARTY-NOTICES.md](./THIRD-PARTY-NOTICES.md) for the per-skill attribution.
These are personal dotfiles shared as a reference: they encode one person's
preferences and machine identity, and are not affiliated with any tool they
configure. Read what a script does before running it,
and adapt rather than adopt wholesale: the bootstrap one-liner runs remote code and
`setup.sh` changes system settings.
