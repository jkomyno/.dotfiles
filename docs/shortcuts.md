# Shortcuts

Every keybinding, shell shortcut, and modern CLI replacement actually configured in this repo, grouped by tool. Each table only lists what's customized here — defaults a tool ships with on its own aren't repeated unless a section says so explicitly.

## tmux

Config: [`target/home/.config/tmux/tmux.conf`](../target/home/.config/tmux/tmux.conf). Prefix key is `Ctrl+b` (tmux's default, unchanged here) — press it, release, then press the key below.

| Keys (after prefix) | Action |
| --- | --- |
| `c` | New window, opened in the current pane's path |
| `\` | Split right |
| `Enter` | Split below |
| `x` | Kill current pane |
| `m` | Toggle pane zoom (maximize/restore) |
| `1`–`9` | Jump to window N |
| `v` | Enter copy mode (vi keys) |
| `d` | Detach from the session (`tmux attach` resumes it) |
| `r` | Reload `tmux.conf` |
| `-` / `=` / `[` / `]` | Resize pane down/up/left/right (repeatable — hold prefix once, tap the key several times) |

**Copy mode** (`prefix v` to enter, vi-style keys since `mode-keys vi` is set):

| Key | Action |
| --- | --- |
| `v` | Begin selection |
| `V` | Select whole line |
| `Ctrl+v` | Toggle rectangle (block) selection |
| `y` | Yank selection to the macOS clipboard (`pbcopy`) |
| `q` | Cancel / exit copy mode |
| mouse drag | Selecting with the mouse also copies to the clipboard on release |

Mouse mode is on (`set -g mouse on`): click to switch panes, drag borders to resize, wheel-scroll enters copy mode automatically. `Escape` has no delay (helps vim inside tmux feel instant), and windows/panes are numbered from 1 to match the keyboard row.

Auto-attach is opt-in, not default: set `export DOTFILES_AUTO_TMUX=1` (see [`session.d/tmux.zsh`](../target/home/.config/zsh/session.d/tmux.zsh)) and every new interactive terminal — except SSH sessions, nested tmux, CI, and editor-embedded terminals — attaches to (or creates) a session named `default`.

## Neovim (LazyVim)

Config: [`target/home/.config/nvim`](../target/home/.config/nvim). Leader key is `Space`, local leader is `\` (set in [`options.lua`](../target/home/.config/nvim/lua/config/options.lua)). Almost every keymap here comes from LazyVim's defaults rather than this repo — the only binding added on top is:

| Keys | Action |
| --- | --- |
| `<space>gd` | Open Diffview (full working-tree diff) |
| `<space>gh` | Diffview file history for the current file |

To discover the rest: press `Space` and wait about a second — a `which-key` popup lists every available leader shortcut grouped by category (files, search, git, LSP, etc.), and drilling into a group shows its own keys the same way. The full default list is also documented at [lazyvim.org/keymaps](https://www.lazyvim.org/keymaps).

A couple worth knowing up front since they cover the most common flows:
- `<space>ff` — find files; `<space>fg` (or `<space>/`) — grep across the project
- `<space>e` — toggle the file explorer
- `gd` / `gr` — LSP go-to-definition / find references; `K` — hover docs
- `<space>gg` — open lazygit (if installed)

This machine's language support (TypeScript, Rust, Python, SQL, JSON/TOML/YAML, Markdown) is enabled via LazyVim's `extras` in [`lazyvim.json`](../target/home/.config/nvim/lazyvim.json), each of which brings its own LSP-triggered keymaps (formatting, code actions, etc.) automatically.

## Ghostty

Config: [`target/home/.config/ghostty/config`](../target/home/.config/ghostty/config). `cmd+s` is a leader key here — press it, release, then press the follow-up key (Ghostty calls this a keybind sequence).

| Keys | Action |
| --- | --- |
| `cmd+t` | New tab |
| `cmd+j` / `cmd+k` | Previous / next tab |
| `cmd+s` then `r` | Reload Ghostty config |
| `cmd+s` then `x` | Close the current split/surface |
| `cmd+s` then `h`/`j`/`k`/`l` | Jump to the split left/below/above/right |
| `shift+enter` | Insert a literal newline (useful in prompts that treat plain Enter as submit) |
| `shift+↑` / `shift+↓` | Scroll 3 lines up/down |
| `cmd+shift+u` / `cmd+shift+d` | Scroll up/down half a page |

The scroll bindings are `performable`, meaning they only act inside Ghostty's own scrollback — if a full-screen app (tmux, vim, less) is active, the same keys pass straight through to it instead.

## Zsh

Config: [`.zshrc`](../target/home/.zshrc), [`plugins.zsh`](../target/home/.config/zsh/plugins.zsh). Beyond the OS defaults, these line-editing keys are explicitly rebound:

| Keys | Action |
| --- | --- |
| `fn+←` / `fn+→` | Jump to beginning / end of line |
| `fn+delete` | Delete the character under the cursor (forward delete) |
| `option+←` / `option+→` | Jump one word back / forward |

Two plugins (loaded via zinit, deferred so they don't slow down shell startup) change how typing itself feels:

- **zsh-autosuggestions** — as you type, it shows a greyed-out completion guessed from your history; press `→` (End of line) to accept it.
- **zsh-fzf-history-search** — replaces the default `Ctrl+r` history search with an fzf-powered fuzzy picker over your full shell history.
- **zsh-autocomplete** — expands Tab-completion into an always-on interactive menu as you type.

`Ctrl+r` is worth calling out on its own: without this setup it's a plain substring search; here it opens a fuzzy, scrollable picker, which is a much faster way to reuse a long command from a week ago than retyping it.

## Modern CLI replacements

[`mise/config.toml`](../target/home/.config/mise/config.toml) and [`git/config`](../target/home/.config/git/config) install and wire up faster/friendlier rewrites of several standard Unix tools. Most run under their own name (`rg`, `fd`, `jq`, `hunk`, `ghui`); `ls` and `cat` are aliased over the standard-tool name itself once the replacement is installed (falling back to the real thing if it isn't); delta and mergiraf hook into git config so they run automatically without ever being typed.

| Instead of | Use | Why |
| --- | --- | --- |
| `grep -r` | `rg` (**ripgrep**) | Respects `.gitignore`, searches recursively by default, and is dramatically faster on large trees. Also the engine behind `Ctrl+r` history search and `<leader>fg`/`<leader>/` project grep in Neovim ([`FZF_DEFAULT_COMMAND`](../target/home/.zshrc) and LazyVim both shell out to it). |
| `find` | `fd` | Sensible defaults (ignores `.git`, respects `.gitignore`), simpler glob-like syntax instead of `find`'s flags. |
| `ls` / `ls -al` | `ls` / `lsa` (**eza**, aliased over `ls` itself) | Long view with icons, git status per file, and human-readable sizes/dates out of the box — see [Shell command shortcuts](#shell-command-shortcuts). |
| `cat` | `cat` (**bat**, aliased over `cat` itself, paging disabled) | Syntax highlighting, line numbers, and a git-modified gutter, while still dumping straight to the terminal instead of opening a pager — see [Shell command shortcuts](#shell-command-shortcuts). |
| `grep`/`sed` across code (structural edits) | `ast-grep` | Matches and rewrites code by AST pattern instead of text, so it doesn't get confused by formatting or match inside comments/strings. |
| `git diff` / `less` as a diff pager | **delta** (`git/config`: `core.pager`, `interactive.diffFilter`) | Side-by-side, syntax-highlighted diffs with line numbers and clickable hyperlinks — applies automatically to every `git diff`, `git show`, and `git add -p`. |
| resolving conflicting merges by hand | **mergiraf** (`git/config`: `[merge "mergiraf"]`, enabled repo-wide by [`git/attributes`](../target/home/.config/git/attributes)) | Syntax-aware 3-way merges: it re-parses both sides and often resolves conflicts standard git would block on. |
| eyeballing/parsing JSON with `sed`/`awk` | `jq` | A real query language for JSON — filtering, reshaping, and formatting without regex gymnastics. |
| `git diff` / `git add -p` for reviewing before committing | `hunk` | A review-first TUI for staging and inspecting hunks, separate from delta (which is just the pager). |
| plain `gh pr list` / `gh pr view` | `ghui` | A TUI over the same GitHub PR data, easier to scan than the raw CLI output. |

## Shell command shortcuts

These are functions/aliases, not keybindings — type the short form and press Enter. Defined once and shared: git ones in [`git-shortcuts.zsh`](../target/home/.config/zsh/aliases.d/git-shortcuts.zsh) (zsh) / [`gm.fish`](../target/home/.config/fish/functions/gm.fish), [`gbda.fish`](../target/home/.config/fish/functions/gbda.fish) (fish); the rest in `aliases.d/*.zsh` and `.config/fish/functions/*.fish`.

| Shortcut | Expands to / does | Shells |
| --- | --- | --- |
| `gp` | `git push origin <current-branch>` | zsh, fish (via OMZ override) |
| `gpl` | `git pull origin <current-branch>` | zsh |
| `gco <ref>` | `git checkout <ref>` — if `<ref>` is a GitHub PR URL, runs `gh pr checkout` instead | zsh, fish |
| `gcom` / `gm` | Check out the repo's default branch (main or master, auto-detected) | zsh, fish |
| `gbda` | Delete local branches already merged into the default branch, including squash-merged ones | zsh, fish |
| `ls` / `lsa` | `eza` long listing with icons (`lsa` also shows hidden files) | zsh |
| `cat` | `bat` with paging disabled (syntax highlighting, line numbers, no pager) | zsh, fish |
| `p` | `pnpm` | zsh, fish |
| `pt` | `pnpm test` | zsh, fish |
| `pb` | `pnpm build` | zsh, fish |
| `pbc` | `pbcopy` | zsh, fish |
| `pbp` | `pbpaste` | zsh, fish |
| `ct` | Keep the Mac awake while Ghostty is running (`coffee -d app Ghostty`) | zsh, fish |

Two are guardrails rather than shortcuts to type on purpose: plain `npm`/`pnpm install -g ...` is blocked with a pointer to `mise use -g "npm:<package>"` instead (see [`npm-guard.zsh`](../target/home/.config/zsh/aliases.d/npm-guard.zsh)), and `git checkout <PR URL>` transparently becomes `gh pr checkout <PR URL>`.

## Git aliases

Defined directly in [`git/config`](../target/home/.config/git/config)'s `[alias]` block — these work in any shell, no zsh/fish wiring needed.

| Alias | Runs |
| --- | --- |
| `git st` | `git status` |
| `git co` | `git checkout` |
| `git com` | Check out the repo's default branch (same detection logic as `gcom`/`gm`) |
| `git br` | `git branch` |
| `git ci` / `git civ` | `git commit --no-verify` / `git commit --verify` |
| `git ca` / `git cav` | `git commit --amend --no-verify` / `git commit --amend --verify` |
| `git ph` / `git pl` | `git push` / `git pull` |
| `git r` | `git reset` |
| `git rs` | `git reset --soft HEAD~1` (undo last commit, keep changes staged) |
| `git rh` | `git reset --hard HEAD~1` (undo last commit, discard its changes) |

`--no-verify` is the default on `ci`/`ca` on purpose (fast local commits); use the `*v` variant (`civ`/`cav`) when you deliberately want hooks to run. `rh` is destructive — it discards the last commit's changes, not just the commit itself.
