# Local software maintenance

`just update mise` updates declared tools and refreshes the shared lockfile.
The standalone mise bootstrap version is pinned in `install/common/mise.sh`;
run that script with `--binary-only` after changing the pin.
The current lockfile format requires mise 2026.11.5 or newer. Keep its
`locks/` dependency sidecars with the main lockfile. Lock targets match the
supported hosts: macOS arm64 and Linux x64/arm64. Slack's CLI is skipped on
Linux arm64 because upstream does not publish that binary.

Use `just update-check` before a full update. It reports the managed tools,
macOS packages, plugins, extensions, and vendored skills. Skill updates require
the `sync-skills` workflow; the ordinary updater reports them without rewriting
vendored content.

## Tool storage

Keep the latest selected release of each managed tool. Node.js is the
exception: retain the latest patches of 24 and 26, with 26 as the default.
Project-specific pins and running processes can temporarily retain older
versions; update those projects or finish those processes before pruning them.

Preview obsolete versions with `just prune-tools`. Run
`just prune-tools --apply` after reviewing the preview. This limits mise's
collector to declared tools, keeps versions selected by tracked projects, and
keeps versions with running processes. Ad hoc installations stay installed.
Mise does not know about every absolute path in a private script, so review
those before removing an old version.

## Rust storage

The Rust tool's `mr_boxington = true` supplies Cargo wrapping. Put the
`mr-boxington` tool before Rust so an old executable in `~/.cargo/bin` cannot
take precedence. An explicit Cargo wrapper is unnecessary with native mise
integration. Editors and noninteractive agents should use mise's Cargo shim
or `mise exec -- cargo`.

The shared policy is `target/home/.config/mbx/config.toml`. Mise maps it to
`~/Library/Application Support/mbx/config.toml` on macOS and
`~/.config/mbx/config.toml` on Linux. The policy sets a 20 GiB combined budget
for cached compilations, targets, and incremental state, and preserves 40 GiB
of free disk space. Active and explicitly protected build data can exceed
the budget temporarily.

Inspect `mise exec -- mbx cache stats`, `mise exec -- mbx doctor`, and
`mise exec -- mbx settings ls`. Use `just rust-cache --dry-run` before
`just rust-cache --run`. Never delete a managed `target` directly or run
`cargo clean`; `mbx clean` releases one workspace's build data.

For a combined budget, set `gc.max_total_size` in the managed policy, then
preview collection. It counts logical bytes; APFS clones, hard links, and
active builds mean it is neither a physical-space measurement nor an absolute
ceiling. A smaller budget can require recompilation. See the
[mbx configuration reference](https://mr-boxington.jdx.dev/configuration).

## Home coverage

`just audit-home` inventories mappings, undeclared home entries, and broken
links without exporting file contents. `just audit-home --json` provides a
snapshot for comparison. Use `mise bootstrap dotfiles status` to check rendered
templates as well as links and copies.

Review undeclared entries by ownership. Keep portable preferences under
`target/home` and map individual files. Keep authentication, private machine
settings, caches, histories, and generated state local. Some files contain
both: the live Codex configuration adds project trust and plugin state to the
copied defaults. A differing copy is a prompt for field-level review, not a
reason to force-apply the source.

Application launch metadata and shell history are incomplete. A missing
Spotlight timestamp or shell command is not proof of nonuse; libraries may
be required by another installed package. For skills, count actual invocation
or explicit reads, exclude startup catalogs, and record history coverage and
installation dates before proposing retirement.
