# install

Standalone setup scripts live here.

The repository-root [`setup.sh`](../setup.sh) should stay small: it installs or finds `chezmoi`, then runs `chezmoi init` and `chezmoi apply`. First-run machine provisioning belongs in this directory and is wired into chezmoi through `home/.chezmoiscripts`.

mise owns language runtimes and CLI developer tools through `home/dot_mise/config.toml`. nanobrew owns macOS GUI apps, fonts, and only formulae that mise cannot reasonably install.

Each script should:

- detect existing installations before mutating the machine
- run cleanly when invoked by its matching chezmoi hook
- keep authentication tokens and other secrets out of the repository
- keep OS-specific logic under the matching OS directory, or guard common scripts explicitly
- avoid writing shell startup files when a managed dotfile can own the same setting

Linux support is intentionally a single future profile for now. Do not split server/client behavior until this repo has a real Linux target to maintain.
