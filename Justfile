set shell := ["env", "LC_ALL=C", "LANG=C", "bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Run non-mutating repository, package, and toolchain diagnostics.
doctor:
    @scripts/dotfiles/doctor.sh

# Show source git status.
status:
    @git status --short

# Show a mise bootstrap dotfiles dry-run against the current HOME.
diff:
    @MISE_TRUSTED_CONFIG_PATHS="$PWD" mise -C "$PWD" bootstrap dotfiles apply --dry-run

# Validate and report macOS package bundle ownership.
packages:
    @scripts/dotfiles/packages.sh

# Check third-party mise versions and lockfile refreshes without writing.
versions:
    @scripts/dotfiles/versions.sh --check

# Upgrade matching third-party mise versions and refresh target/home/.config/mise/mise.lock.
versions-update:
    @scripts/dotfiles/versions.sh --write

# Update every managed layer, or one component: just update [all|mise|casks|formulae|plugins|vscode|skills|codex|pi|agentmemory|self]
update *args:
    @scripts/dotfiles/update.sh {{args}}

# Non-mutating preview of what `just update` would change. Accepts the same components.
update-check *args:
    @scripts/dotfiles/update.sh --check {{args}}

# Register managed coding-agent marketplaces and install enabled plugins (idempotent).
plugins-install:
    @bash install/common/agents.sh

# Report configured vs installed coding-agent plugins without changing anything.
plugins-check:
    @bash install/common/agents.sh --check

# Grant the current user passwordless sudo (opt-in; needs your password once). Undo: add --remove.
nopasswd-sudo *args:
    @bash install/macos/common/sudoers-nopasswd.sh {{args}}

# Install the tailscaled system daemon and guide joining the tailnet (also part of staged setup).
tailscale *args:
    @bash install/macos/common/tailscale.sh {{args}}

# Enable native mac-to-mac Screen Sharing (opt-in; needs sudo). Status: --check. Undo: --remove.
screen-sharing *args:
    @bash install/macos/common/screen-sharing.sh {{args}}

# Start or restart the paseo user service. Pair: --pair. Status: --status. Undo: --remove.
paseo *args:
    @bash install/common/paseo.sh {{args}}

# Start or restart the agentmemory user service. Status: --status. Undo: --remove.
agentmemory *args:
    @bash install/common/agentmemory.sh {{args}}

# Validate Linux user-service units and lifecycle handling without changing the real manager.
services-check:
    @scripts/dotfiles/services-check.sh

# Authenticate gh, codex, and claude (interactive; skips anything already logged in).
auth:
    @scripts/dotfiles/auth.sh

# Report gh/codex/claude authentication status without launching any login flow.
auth-check:
    @scripts/dotfiles/auth.sh --check

# Adversarially review the current branch with Codex (review-only). Override base: just codex-review main
codex-review base="main":
    @scripts/dotfiles/codex-review-loop.sh --base "{{base}}"

# Check vendored third-party agent skills against upstream.
sync-skills-check:
    @bash target/home/.agents/skills/sync-skills/scripts/sync.sh --keep-upstream

# Benchmark interactive shell startup. Override with: just benchmark-shell zsh 20
benchmark-shell shell="zsh" runs="10":
    @scripts/dotfiles/benchmark-shell.sh --shell "{{shell}}" --runs "{{runs}}"

# Validate the repository mise dotfiles slice against a temporary HOME.
dotfiles-check:
    @scripts/dotfiles/mise-dotfiles-check.sh

# Validate mise task wrappers without running installers.
tasks-check:
    @scripts/dotfiles/mise-tasks-check.sh

# Print the staged mise setup order without running installers.
setup-plan *args:
    @scripts/dotfiles/mise-setup-staged.sh --plan {{args}}

# Run the safe staged setup subset against a temporary HOME.
setup-smoke:
    @scripts/dotfiles/mise-setup-staged-smoke.sh

# Validate generated Git SSH signing config in temporary homes.
git-signing-check:
    @scripts/dotfiles/git-signing-check.sh
