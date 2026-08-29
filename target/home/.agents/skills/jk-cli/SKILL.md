---
name: jk-cli
description: Operate jk, @jkomyno's deterministic CLI, for identity, notifications, GitHub Actions pinning, and idea corpora. Use for any `jk` command or output contract.
---

# jk-cli

`jk` is @jkomyno's personal assistant CLI: it performs **deterministic**,
mechanical tasks for coding agents and local workflows with stable flags,
stable machine-readable output, and meaningful exit codes. It never calls
LLMs, reads model-provider API keys, makes network calls to a model, or makes
judgment calls. Treat it as a predictable tool, not an assistant — same input,
same output, every time.

The binary is `jk` (on PATH at `~/.local/bin/jk`). Four commands:

| Command   | Reach for it when…                                                               |
| --------- | ------------------------------------------------------------------------------- |
| `whoami`  | You need the GitHub login the `gh` CLI is authenticated as (read offline).       |
| `notify`  | A script/hook/long command should ping a phone via Telegram.                     |
| `actions` | A repo's GitHub Actions refs need pinning to SHAs or an update report.           |
| `idea`    | You need to acquire, index, or **search** a reference corpus under `~/.jk/ideas`. |

## The output contract (read this before parsing anything)

`jk` auto-detects its consumer:

- **Piped / non-TTY stdout** (agents, scripts, hooks) → **JSON**. This is the
  stable API. Parse it; never scrape the human text.
- **Interactive terminal** → human-readable text.
- Force either way with the global `--json <BOOL>`: `--json=true` or
  `--json=false`. It is POSIX-style and the **last one on the line wins**.

Because an agent's stdout is piped, `jk` already emits JSON to you by default —
no flag needed. Add `--json=false` only when showing a human the text form.
stdout carries **only** the data payload; all diagnostics, progress, and errors
go to **stderr**.

## Exit codes (branch on these, not on text)

| Code | Meaning            | Examples                                                                             |
| ---- | ------------------ | ----------------------------------------------------------------------------------- |
| `0`  | success            | normal completion; `idea search` found ≥1 hit                                        |
| `1`  | command findings   | `actions check` found drift; `idea search` found **no** hits (grep-style)            |
| `2`  | usage error        | missing/invalid flags, bad subcommand                                               |
| `3`  | operational error  | network failure, `idea index` could not convert a document, wrapped command failed   |

`1` is *not* a crash — it is a meaningful "there is something to report"
signal. Distinguish it from `2`/`3` when scripting.

## Common recipes

### whoami — who is `gh` logged in as

```bash
jk whoami                      # {"host":"github.com","login":"jkomyno"}
jk whoami --json=false         # jkomyno
jk whoami --host github.com    # or set GH_HOST
```

Reads `gh`'s `hosts.yml` offline (honors `GH_CONFIG_DIR`, `XDG_CONFIG_HOME`,
`GH_HOST`). Fails if `gh` is not authenticated.

### notify — Telegram ping

```bash
jk notify --message "Build finished"          # one Bot API call
echo "deploy done" | jk notify --stdin        # body from a pipe
jk notify --wrap -- just test                 # run cmd, notify with exit status + duration
jk notify --dry-run --message "test"          # resolve everything, skip the send
```

The body comes from **exactly one** explicit source: `--message`, `--stdin`,
or `--wrap`. `jk` reads stdin **only** with `--stdin`, so a hook fed JSON on
stdin (e.g. Claude Code hooks) never hangs and never sends garbage — a missing
body source is a usage error (`2`), not a malformed notification.

- `--stdin` sends piped output **as the message** (best for a short curated
  line); it can't observe the producer's exit status.
- `--wrap -- <cmd>` spawns the command itself, streams its output to stderr,
  then notifies with ✅/❌ from the exit status. A failing wrapped command also
  fails `jk notify` with exit `3`, preserving the child's code in the JSON.

First-time setup is a one-off wizard: `jk notify setup telegram`. Credentials
live in the macOS keychain (service `jk`) or `~/.jk/telegram/.env` — never in
flags or process env. Pair `--wrap` with Claude Code Stop/Notification hooks to
get pinged when long agent runs finish.

### actions — pin & check GitHub Actions

```bash
jk actions check                       # report available updates (exit 1 if drift)
jk actions bump                        # pin every bumpable ref to its SHA, write files
jk actions bump --dry-run              # full recap, write nothing
jk actions bump --freeze-major         # hold major bumps back, report separately
jk actions bump --only 'actions/*'     # restrict to matching action identifiers (glob)
jk actions bump path/to/repo           # scan a specific repo root (default: cwd)
```

`check` is read-only and exits `1` when updates exist (CI-friendly drift gate);
`bump` is the mutating writer — always offer `--dry-run` first.

### idea — query a reference corpus

`jk idea` owns the **mechanical** corpus steps (clone, snapshot, convert,
chunk, index, search). The **judgment** side it leaves to you: choosing which
sources to acquire and writing the `BRIEF.md` / `PATTERNS.md` / `maps/` digests
that `jk` then indexes. `jk` is the sole writer of `sources.json` and the index;
you are the sole author of the digests.

Most common job — find and read knowledge in an existing corpus:

```bash
jk idea list                                        # all corpora + source counts
jk idea search durable-workflows "alarm scheduling" --limit 5
jk idea search durable-workflows "retry" --role map --source agents-starter
jk idea read durable-workflows maps/agents-starter.md --seq 4
jk idea neighbors durable-workflows maps/agents-starter.md --seq 4 --before 2 --after 2
jk idea show durable-workflows                      # sources, docs, index freshness
```

`search` ranks heading-bounded chunks with BM25 and returns each hit's path,
line span, heading path, snippet, and any `path:line` pointers into the pinned
clones. **Reading order for agents:** brief → patterns → `jk idea search` →
`jk idea read`/`neighbors` the returned `(path, seq)` spans → `rg` the clones
under `$(jk idea path <name>)/repos/` for anything deeper. `search`/`show` are
read-only and never build the index implicitly; if none exists they tell you to
run `jk idea index`.

Acquire and index (mutating):

```bash
jk idea new <name> --link <url> [--link <url> ...]   # create corpus, clone/snapshot
jk idea add <name> --link <url> [--kind repo|article|pdf|paper]
jk idea index <name>                                 # convert + chunk + refresh stale rows
jk idea index <name> --rebuild                       # drop index.db, re-derive everything
```

`index` is the **only** database writer; `index.db` is derived data (gitignored,
rebuildable). A document it cannot convert is a visible failure (exit `3`),
never a silent placeholder.

## Diagnostics

```bash
JK_LOG=debug jk whoami            # opt-in tracing to stderr
JK_KEYCHAIN=never jk notify ...   # skip macOS keychain (dotenv only)
```

## Full flag reference

For every command's complete flag set, the polymorphic `--link` detection
rules, the `--role`/`--source` filter vocabularies, and the idea index/convert
internals, read [references/commands.md](references/commands.md). Prefer
`jk <command> --help` for the live, version-exact surface.
