#!/usr/bin/env bash
# codex-notify.sh — Codex `notify` adapter.
#
# Codex invokes its `notify` program with the event JSON as a single argv arg
# (NOT stdin). The only event it currently emits is `agent-turn-complete`, i.e.
# "the agent finished responding" — our checkpoint trigger. We pull `cwd` from
# the payload and delegate to the shared checkpoint script.
#
# Wired in ~/.codex/config.toml:
#   notify = ["/Users/jkomyno/.agents/bin/codex-notify.sh"]

set -uo pipefail

payload="${1:-}"
[ -n "$payload" ] || exit 0

type="$(printf '%s' "$payload" | jq -r '.type // empty' 2>/dev/null)"
[ "$type" = "agent-turn-complete" ] || exit 0

cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"

exec "$HOME/.agents/bin/agent-checkpoint.sh" commit --agent codex --cwd "$cwd"
