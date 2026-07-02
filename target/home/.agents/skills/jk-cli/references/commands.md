# jk — complete command reference

Authoritative source is always `jk <command> [<subcommand>] --help`, which
reflects the installed version exactly. This file is the at-a-glance map.

Global option on every command: `--json <BOOL>` (`true` | `false`) forces the
output format; last occurrence on the line wins. Default behavior auto-detects:
piped stdout → JSON, TTY → text.

Exit codes everywhere: `0` success · `1` command findings · `2` usage error ·
`3` operational error.

---

## whoami

```
jk whoami [--host <HOST>] [--json <BOOL>]
```

- `--host <HOST>` — GitHub host to read the active account for. Env: `GH_HOST`.
  Default `github.com`.

Reads `gh`'s `hosts.yml` offline; honors `GH_CONFIG_DIR` and `XDG_CONFIG_HOME`.
JSON shape: `{"host": "...", "login": "..."}`. Text shape: the bare login.

---

## notify

```
jk notify [OPTIONS] <--message <TEXT> | --stdin | --wrap> [-- <CMD>...]
jk notify setup [TRANSPORT]
```

Exactly one body source is required: `--message`, `--stdin`, or `--wrap`.

| Option                  | Meaning                                                                          |
| ----------------------- | ------------------------------------------------------------------------------- |
| `--transport <T>`       | Delivery transport. Values: `telegram` (default).                               |
| `--message <TEXT>`      | Message body, given inline.                                                      |
| `--stdin`               | Read the body from stdin. **The only case stdin is read.**                      |
| `--wrap`                | Run the command after `--`, notify with its exit status + duration.             |
| `--title <TEXT>`        | Title line shown above the body.                                                 |
| `--level <LEVEL>`       | `info` (default) · `success` · `failure`. With `--wrap` it derives from exit status. |
| `--source <NAME>`       | Sender name appended to the notification (e.g. a hook name).                     |
| `--dry-run`             | Validate/resolve everything, skip the provider call. With `--wrap` the wrapped command still runs. |
| `[-- <CMD>...]`         | Command to wrap; everything after `--`.                                          |

Behavior notes:

- `jk` never reads stdin unless `--stdin` is passed → safe in hooks/cron that
  receive unrelated JSON on stdin. Missing body source ⇒ exit `2`.
- `--stdin` sends piped output *as the message*; cannot see the producer's exit
  status, so `--level` is whatever you pass.
- `--wrap -- <cmd>` spawns the command, streams its output to **stderr** (stdout
  stays reserved for jk's JSON receipt), and notifies ✅/❌. A failing wrapped
  command fails `jk notify` with exit `3`, with the child's code in the JSON.

### notify setup (wizard)

```
jk notify setup [TRANSPORT] [--dry-run] [--json <BOOL>]
```

- `[TRANSPORT]` — `telegram` (default).
- `--dry-run` — walk the wizard without sending the test message or writing any store.

Interactive one-off: create a bot via @BotFather, pick a chat (auto-detected),
send a verification message, then choose where credentials are stored — macOS
login keychain (service `jk`, default) or `~/.jk/telegram/.env` (the only option
off macOS). Re-running prefills existing values and confirms before replacing.
Offers to import bot token + chat ID from `~/.telegram-env` if present.

Credential diagnostics:
- `JK_KEYCHAIN=never` — skip the macOS keychain (dotenv file only).
- `JK_TELEGRAM_API_URL=URL` — override the Telegram Bot API base URL (testing).

---

## actions

Pin and check GitHub Actions workflow references.

```
jk actions check [PATH] [--freeze-major] [--only <PATTERN>] [--json <BOOL>]
jk actions bump  [PATH] [--dry-run] [--freeze-major] [--only <PATTERN>] [--json <BOOL>]
```

| Option             | Meaning                                                          |
| ------------------ | --------------------------------------------------------------- |
| `[PATH]`           | Repository root to scan (default: current directory).           |
| `--freeze-major`   | Hold major updates back and report them separately.             |
| `--only <PATTERN>` | Restrict resolution to action identifiers matching this glob.   |
| `--dry-run` (bump) | Print the full recap without writing workflow files.            |

- `check` is read-only and exits `1` when updates are available — a CI drift
  gate. `0` means up to date.
- `bump` is the mutating writer: pins every bumpable ref to a SHA and updates
  workflow files. Run `--dry-run` first to preview.

---

## idea

Manage reference corpora under `~/.jk/ideas`. A corpus is **file-canonical**:
pinned shallow clones in `repos/`, snapshotted articles in `articles/`,
agent-written digests (`BRIEF.md`, `PATTERNS.md`, `maps/`), and a `sources.json`
provenance manifest. The derived knowledge DB `<corpus>/index.db` is a pure
function of those files — gitignored, never migrated, rebuildable.

`jk` is the sole writer of both `sources.json` and the index. `index` is the
only command that writes the database. `search`/`show` never build it implicitly.

`<NAME>` is always a kebab-case corpus slug.

### Acquisition (mutating, networked, supports --dry-run)

```
jk idea new <NAME> --link <URL> [--link <URL> ...] [-n|--dry-run] [--json <BOOL>]
jk idea add <NAME> --link <URL> [--kind <KIND>]    [-n|--dry-run] [--json <BOOL>]
```

- `--link <URL>` — source to acquire. On `new`, repeatable for multiple sources;
  re-adding an existing URL re-pins it.
- `--kind <KIND>` (add) — override detection. Values: `repo`, `article`, `pdf`, `paper`.
- `-n, --dry-run` — report what would be acquired without cloning or writing.

`--link` is **polymorphic** (override with `--kind`):
| Input                              | Detected kind | Handling                                     |
| ---------------------------------- | ------------- | -------------------------------------------- |
| `.git` suffix or known git host    | `repo`        | shallow-cloned and pinned to a commit        |
| arXiv link                         | `paper`       | paper                                        |
| `.pdf`                             | `pdf`         | document                                     |
| anything else                      | `article`     | fetched, reduced to readable markdown        |

### Indexing (only database writer)

```
jk idea index <NAME> [-n|--dry-run] [--rebuild] [--reconvert] [--json <BOOL>]
```

- `-n, --dry-run` — report what would change without touching the database.
- `--rebuild` — drop `index.db` and re-derive everything from the corpus files.
- `--reconvert` — re-run document conversion even when an artifact already
  exists (e.g. after a converter-backend upgrade).

Converts downloaded documents **in process** with Kreuzberg (native text
extraction, no OCR, no network), chunks every markdown artifact along its
headings, and syncs incrementally by content hash. Conversion auto-reruns when
the downloaded binary or backend version changes. Reruns are idempotent. A
document Kreuzberg cannot convert is a visible partial failure (exit `3`).

### Read-only query & inspection

```
jk idea list                                   [--json <BOOL>]
jk idea path      <NAME>                        [--json <BOOL>]
jk idea show      <NAME>                        [--json <BOOL>]
jk idea search    <NAME> <QUERY> [--limit <N>] [--role <ROLE>] [--source <SLUG>] [--json <BOOL>]
jk idea outline   <NAME> [--doc <PATH>]        [--role <ROLE>] [--source <SLUG>] [--json <BOOL>]
jk idea read      <NAME> <PATH>  [--seq <SEQ>] [--json <BOOL>]
jk idea neighbors <NAME> <PATH>  --seq <SEQ>   [--before <N>] [--after <N>] [--json <BOOL>]
```

- `list` — all corpora with source counts.
- `path` — print one corpus directory (for scripting, e.g. `$(jk idea path x)`).
- `show` — describe one corpus: sources, documents, index freshness.
- `search <QUERY>` — BM25 ranking over chunk text and heading paths.
  - `--limit <N>` — max hits (default 10).
  - `--role <ROLE>` / `--source <SLUG>` — filter hits (see vocab below).
  - Exits `0` with ≥1 hit, `1` with none (grep convention).
- `outline` — corpus document map, or one document's chunk outline via `--doc`.
  `--role`/`--source` filter the document map only.
- `read <PATH>` — exact chunk text by document path. `--seq <SEQ>` reads one
  chunk; omit to read the whole document in seq order.
- `neighbors <PATH> --seq <SEQ>` — chunks surrounding an anchor; `--before <N>`
  (default 1) and `--after <N>` (default 1).

`<PATH>` is an indexed document path exactly as reported by `search`/`outline`;
`<SEQ>` is a chunk's seq from the same output. Together `(path, seq)` is the
stable handle for `read`/`neighbors`.

**Filter vocabularies:**
- `--role`: `brief` · `patterns` · `map` · `article` · `document` · `repo`.
- `--source`: a source slug as shown by `jk idea show`.

**Agent reading order:** `BRIEF.md` → `PATTERNS.md` → `jk idea search` → read
the returned spans with `jk idea read` / `jk idea neighbors` → `rg` the pinned
clones under `<corpus>/repos/` for anything deeper.

---

## Scope

This reference covers only the **mechanical** CLI surface. The **judgment**
side of `jk idea` — choosing sources and writing the `BRIEF.md`/`PATTERNS.md`/
`maps/` digests that `jk` indexes — is the author's job, not the CLI's.
