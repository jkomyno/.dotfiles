# install

Standalone setup scripts live here.

The repository-root [`setup.sh`](../setup.sh) should stay small: it fetches this checkout, installs or finds the bootstrap `mise` binary, then runs the staged setup order in [`scripts/dotfiles/mise-setup-staged.sh`](../scripts/dotfiles/mise-setup-staged.sh). First-run machine provisioning belongs in this directory and is wired into mise tasks under [`tasks/`](../tasks).

The canonical staged setup order is:

1. `install:common:ssh`
2. `install:macos:command-line-tools`
3. `install:macos:homebrew`
4. `install:macos:nanobrew`
5. `install:macos:nanobrew-casks`
6. `install:macos:nanobrew-formulae`
7. `mise dotfiles apply`
8. `install:common:mise`
9. `install:common:git`
10. `install:common:git-signing`
11. `install:common:gh`
12. `install:common:ollama-models`
13. `install:common:mlx`
14. `install:macos:defaults`

The staged setup runner invokes wrapper tasks with `mise run --skip-deps` in this explicit order, so the dependency graph stays useful for ad hoc task runs without making the full setup path repeat prerequisites. Inspect the plan without running installers via `just setup-plan` (or `mise run setup:staged -- --plan`).

mise owns language runtimes and CLI developer tools through `target/home/.config/mise/config.toml`. nanobrew owns macOS GUI apps, fonts, and only formulae that mise cannot reasonably install.

Each script should:

- detect existing installations before mutating the machine
- run cleanly when invoked by its matching mise task
- keep authentication tokens and other secrets out of the repository
- keep OS-specific logic under the matching OS directory, or guard common scripts explicitly
- avoid writing shell startup files when a managed dotfile can own the same setting

Linux support is intentionally a single future profile for now. Do not split server/client behavior until this repo has a real Linux target to maintain.
