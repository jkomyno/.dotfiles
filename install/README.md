# install

Standalone setup scripts live here.

The repository-root [`setup.sh`](../setup.sh) should stay small: it fetches this checkout, installs or finds the bootstrap `mise` binary, then runs the staged setup order in [`scripts/dotfiles/mise-setup-staged.sh`](../scripts/dotfiles/mise-setup-staged.sh). First-run machine provisioning belongs in this directory and is wired into mise tasks under [`tasks/`](../tasks).

The staged runner owns the setup order. From the repository root, print it without running installers:

```sh
just setup-plan
# Without just:
bash scripts/dotfiles/mise-setup-staged.sh --plan
```

The runner invokes wrapper tasks with `mise run --skip-deps` in this order. Individual task runs still use their declared dependencies, while the full setup avoids repeating prerequisites.

Mise owns portable language runtimes and CLI tools through `target/home/.config/mise/config.toml`. The Linux profile adds tools through `target/home/.config/mise/config.linux.toml`. Apt owns Linux system prerequisites. Nanobrew owns macOS GUI apps, fonts, and only formulae that mise cannot reasonably install.

Each script should:

- detect existing installations before mutating the machine
- run cleanly when invoked by its matching mise task
- keep authentication tokens and other secrets out of the repository
- keep OS-specific logic under the matching OS directory, or guard common scripts explicitly
- avoid writing shell startup files when a managed dotfile can own the same setting

Linux support targets Debian 12 and Ubuntu 24.04 with systemd on x64 or arm64. Desktop Linux, GUI application installation, Tailscale provisioning, and non-Debian package managers are out of scope.
