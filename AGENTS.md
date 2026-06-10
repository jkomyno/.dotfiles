# AGENTS.md

## Repository Context

- This repository stores jkomyno's personal dotfiles and local agent assets.
- Dotfiles are managed with chezmoi; edit the source files in this checkout rather than deployed files in `$HOME`.
- The target environment is macOS on Apple Silicon.

## Where to Look

- `README.md` explains the intended dotfiles layout and setup assumptions.
- `.agents/skills/` contains local agent skills and their workflow notes.
- `skills-lock.json` records installed skill metadata.

## Tool Ownership

- Put language runtimes and CLI developer tools in `home/dot_mise/config.toml`.
- `home/dot_config/exact_mise/symlink_config.toml.tmpl` exposes that file as `~/.config/mise/config.toml`.
- Put GUI apps and fonts in `install/macos/common/nanobrew-casks.Brewfile`.
- Keep `install/macos/common/nanobrew-formulae.Brewfile` empty unless a required package has no practical mise backend.
- Do not duplicate a CLI between mise and nanobrew.

## Working Rules

- Keep changes small and scoped to the user's request.
- Do not add secrets, tokens, private machine state, or unrelated local artifacts.
- Use `rg` for repository search.
- Before finishing, run `git status --short`; when `chezmoi` is available, also run `chezmoi status` and `chezmoi diff`.
