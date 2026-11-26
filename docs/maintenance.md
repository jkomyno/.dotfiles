# Local software maintenance

`just update mise` installs active tools from the shared and Linux locks.
Maintainers use `just versions-update` to refresh the complete catalog.
The standalone mise bootstrap version is pinned in `install/common/mise.sh`;
run that script with `--binary-only` after changing the pin.
The managed configuration requires mise 2026.11.8 or newer. Keep its
`locks/` dependency sidecars with the main lockfile. Lock targets match the
supported hosts: macOS arm64 and Linux x64/arm64. Slack's CLI is skipped on
Linux arm64 because upstream does not publish that binary.

Pi uses the standalone release, so project Node versions do not affect it.
Hugging Face uses its own Python 3.14 runtime so its native dependencies can
be locked and installed without building against the default Python 3.15.

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
snapshot for comparison. Use `scripts/dotfiles/dotfiles.sh status` to check rendered
templates as well as links and copies.

Review undeclared entries by ownership. Keep portable preferences under
`target/home` and map individual files. Keep authentication, private machine
settings, caches, histories, and generated state local. Some files contain
both. The agent reconciler manages selected MCP servers, hooks, plugins and
Pi package sources while retaining local project trust and provider settings.

Application launch metadata and shell history are incomplete. A missing
Spotlight timestamp or shell command is not proof of nonuse; libraries may
be required by another installed package. For skills, count actual invocation
or explicit reads, exclude startup catalogs, and record history coverage and
installation dates before proposing retirement.

## Work VM rollout

1. Keep an SSH session open. Open a second one and record `command -v node go python3`, `getent passwd "$USER"`, and `systemctl --user show paseo.service -p FragmentPath -p MainPID -p ExecStart`. Record the current daemon home, registration and loopback health locally. Keep provider credentials on the host.
2. Run `just setup-plan --profile work --with go`. Review differing targets, host instructions, active skills, Pi extensions and the existing unit. Back up only the paths you plan to adopt, including symlinks, with `cp -a` into a private directory. For one reviewed native file, use `DOTFILES_SELECTION='work go' scripts/dotfiles/dotfiles.sh apply --force --yes "$HOME/path"`. Identity migration also requires `DOTFILES_MIGRATE_IDENTITY=1`.
3. Run `bash setup.sh --profile work --with go`. The default work setup keeps the current SSH and Git identity and login shell. Sign into agents separately. On Bash hosts, review the existing startup files and add the following to the interactive startup path once:

   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   eval "$(mise activate bash)"
   ```

4. Verify a fresh SSH login and `mise which node`, `mise which go`, `codex --version`, `claude --version` and `pi --version`. Noninteractive SSH commands can use `~/.local/bin/mise exec -- node --version`. Check `just update mise` and `git status --short` in the checkout.
5. Migrate Paseo independently. Existing Linux links to the earlier unit source keep their original contents across the pull. The reviewed target selects the separate `paseo-mise.service` source. Keep the original unit and environment file, daemon home and image Node available. Review and apply just the replacement:

   ```sh
   DOTFILES_MIGRATE_PASEO=1 scripts/dotfiles/dotfiles.sh apply --force --yes "$HOME/.config/systemd/user/paseo.service"
   DOTFILES_MIGRATE_PASEO=1 bash install/common/paseo.sh
   systemctl --user show paseo.service -p MainPID -p ExecStart
   ss -lntp | grep ':6767'
   curl -fsS http://127.0.0.1:6767/api/health
   ~/.local/bin/mise exec -- paseo daemon status
   ```

   Inspect `/proc/<pid>/exe` for the daemon and workers after a stop/start. Verify the existing host registration and provider discovery from the paired client. To roll back, stop the new unit, replace its symlink with the backed-up unit, restore any changed environment file, then run `systemctl --user daemon-reload` and restore its previous enabled/running state. Revert the reviewed Bash snippet and restore the prior profile selection if needed. Keep OS Python, image Node and Go, shell, networking and system services installed.

### Rehearsal results

On 2026-11-26, `setup.sh --profile work --with go` completed on an isolated Ubuntu 24.04 arm64 VM. Mise resolved 34 tool installations. A second SSH session kept Bash and resolved Node 26.13.1, Go 1.27.4, npm 12.2.2 and pnpm 12.21.0 through mise. The distribution's Node 18.19.1 and Go 1.22.2 remained available under `/usr/bin`.

Setup preserved the original service PID, SSH and Git configuration, Shelley instruction link and pre-existing Pi extension. Both `just update mise` and `just update` completed with a clean checkout and identical source lock checksums. GitHub briefly rate-limited the Neovim plugin's release lookup during the first install. Retrying after the rate limit reset installed the locked release.

The independent Paseo cutover used the pinned CLI's `daemon run` command. The rollback restored the prior unit. After a stop/start, the managed unit returned HTTP 200 at `/api/health`, retained its server ID, and ran its Node processes from mise. Paseo reported Claude, Codex and Pi available without a provider sign-in or pairing a client.
