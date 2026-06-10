# install

Standalone setup scripts live here.

`setup.sh` should stay small: it installs or finds `chezmoi`, then runs `chezmoi init` and `chezmoi apply`. First-run machine provisioning belongs in this directory and is wired into chezmoi through `home/.chezmoiscripts`.

Each script should:

- be safe to run directly with `bash path/to/script.sh`
- detect existing installations before mutating the machine
- keep OS-specific logic under the matching OS directory
- avoid writing shell startup files when a managed dotfile can own the same setting

Linux support is intentionally a single future profile for now. Do not split server/client behavior until this repo has a real Linux target to maintain.
