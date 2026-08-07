# install

Standalone setup scripts live here.

The repository-root [`setup.sh`](../setup.sh) should stay small: it fetches this checkout, installs or finds the bootstrap `mise` binary, then runs the staged setup order in [`scripts/dotfiles/mise-setup-staged.sh`](../scripts/dotfiles/mise-setup-staged.sh). First-run machine provisioning belongs in this directory and is wired into mise tasks under [`tasks/`](../tasks).

The canonical staged setup order is:

1. `install:linux:packages`
2. `install:common:ssh`
3. `install:macos:sudoers-nopasswd`
4. `install:macos:command-line-tools`
5. `install:macos:nanobrew`
6. `install:macos:nanobrew-casks`
7. `install:macos:ghostty-terminfo`
8. `install:macos:nanobrew-formulae`
9. `install:macos:tailscale`
10. `mise bootstrap dotfiles apply`
11. `install:linux:login-shell`
12. `install:common:mise`
13. `install:common:paseo`
14. `install:common:agentmemory`
15. `install:common:git`
16. `install:common:git-signing`
17. `install:common:gh`
18. `install:common:claude`
19. `install:common:agents`
20. `install:common:amp`
21. `install:common:vscode-extensions`
22. `install:common:ollama-models`
23. `install:common:mlx`
24. `install:macos:defaults`

The staged setup runner invokes wrapper tasks with `mise run --skip-deps` in this explicit order, so the dependency graph stays useful for ad hoc task runs without making the full setup path repeat prerequisites. Inspect the plan without running installers via `just setup-plan` (or `mise run setup:staged -- --plan`).

Mise owns portable language runtimes and CLI tools through `target/home/.config/mise/config.toml`. The Linux profile adds tools through `target/home/.config/mise/config.linux.toml`. Apt owns Linux system prerequisites. Nanobrew owns macOS GUI apps, fonts, and only formulae that mise cannot reasonably install.

Each script should:

- detect existing installations before mutating the machine
- run cleanly when invoked by its matching mise task
- keep authentication tokens and other secrets out of the repository
- keep OS-specific logic under the matching OS directory, or guard common scripts explicitly
- avoid writing shell startup files when a managed dotfile can own the same setting

Linux support targets Debian 12 and Ubuntu 24.04 with systemd on x64 or arm64. Desktop Linux, GUI application installation, Tailscale provisioning, and non-Debian package managers are out of scope.
