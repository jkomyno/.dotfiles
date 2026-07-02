set shell := ["env", "LC_ALL=C", "LANG=C", "bash", "-euo", "pipefail", "-c"]

default:
    @just --list

# Run non-mutating repository, chezmoi, package, and toolchain diagnostics.
doctor:
    @scripts/dotfiles/doctor.sh

# Show source git status plus deployed-home drift when chezmoi is available.
status:
    @git status --short
    @if command -v chezmoi >/dev/null 2>&1; then chezmoi --source "$PWD" status; else echo "chezmoi not installed"; fi

# Show deployed-home diff when chezmoi is available.
diff:
    @if command -v chezmoi >/dev/null 2>&1; then chezmoi --source "$PWD" diff; else echo "chezmoi not installed"; exit 1; fi

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
