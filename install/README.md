# install

Standalone setup scripts live here.

The repository-root [`setup.sh`](../setup.sh) should stay small: it fetches this checkout, installs or finds the bootstrap `mise` binary, then runs the staged setup order in [`scripts/dotfiles/mise-setup-staged.sh`](../scripts/dotfiles/mise-setup-staged.sh). First-run machine provisioning belongs in this directory and is wired into mise tasks under [`tasks/`](../tasks).

mise owns language runtimes and CLI developer tools through `target/home/.config/mise/config.toml`. nanobrew owns macOS GUI apps, fonts, and only formulae that mise cannot reasonably install.

Each script should:

- detect existing installations before mutating the machine
- run cleanly when invoked by its matching mise task
- keep authentication tokens and other secrets out of the repository
- keep OS-specific logic under the matching OS directory, or guard common scripts explicitly
- avoid writing shell startup files when a managed dotfile can own the same setting

Linux support is intentionally a single future profile for now. Do not split server/client behavior until this repo has a real Linux target to maintain.
