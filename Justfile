set shell := ["env", "LC_ALL=C", "LANG=C", "bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Run non-mutating repository, chezmoi, package, and toolchain diagnostics.
doctor:
    @scripts/dotfiles/doctor.sh

# Show source git status plus deployed-home drift when this checkout is installed.
status:
    @git status --short
    @scripts/dotfiles/chezmoi-drift.sh status

# Show deployed-home diff when this checkout is installed.
diff:
    @scripts/dotfiles/chezmoi-drift.sh diff

# Validate and report macOS package bundle ownership.
packages:
    @scripts/dotfiles/packages.sh

# Check third-party mise versions and lockfile refreshes without writing.
versions:
    @scripts/dotfiles/versions.sh --check

# Upgrade matching third-party mise versions and refresh home/dot_mise/mise.lock.
versions-update:
    @scripts/dotfiles/versions.sh --write

# Check vendored third-party agent skills against upstream.
sync-skills-check:
    @bash home/dot_agents/skills/exact_sync-skills/scripts/sync.sh --keep-upstream

# Benchmark interactive shell startup. Override with: just benchmark-shell zsh 20
benchmark-shell shell="zsh" runs="10":
    @scripts/dotfiles/benchmark-shell.sh --shell "{{shell}}" --runs "{{runs}}"

# Run the disposable mise dotfiles migration spike.
dotfiles-spike:
    @scripts/dotfiles/mise-dotfiles-spike.sh

# Backward-compatible alias from the initial migration name.
system-files-spike:
    @just dotfiles-spike

# Validate the repository mise dotfiles slice against a temporary HOME.
dotfiles-check:
    @scripts/dotfiles/mise-dotfiles-check.sh

# Check that target-shaped mirrors still match the current chezmoi sources.
dotfiles-mirror-check:
    @scripts/dotfiles/mise-dotfiles-mirror-check.sh

# Probe mise dotfiles behavior in a disposable project and HOME.
dotfiles-capabilities:
    @scripts/dotfiles/mise-dotfiles-capabilities.sh

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
