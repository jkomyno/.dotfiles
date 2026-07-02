#!/usr/bin/env bash
# PreToolUse hook for Bash: blocks any command whose payload contains the
# Claude attribution trailers. The user has opted out of Claude attribution
# via settings.json (attribution.commit = "" and attribution.pr = ""), but
# that field is advisory only — the model can still insert the trailers in
# a `git commit -m` heredoc or a `gh pr create --body` payload. This hook
# enforces the opt-out at the tool-call boundary.
#
# Forbidden markers (any one match → block):
#   - "Co-Authored-By: Claude"
#   - "🤖 Generated with [Claude Code]"
#   - "claude.com/claude-code"
#
# Output: nothing (exit 0) when clean; a PreToolUse-deny JSON document on
# stdout when a marker is found. Always exits 0; the deny is communicated
# via the JSON payload, not the exit code.

set -u

cmd=$(jq -r '.tool_input.command // empty' 2>/dev/null || true)

if [ -z "$cmd" ]; then
  exit 0
fi

if printf '%s' "$cmd" | LC_ALL=C.UTF-8 grep -qE 'Co-Authored-By: Claude|🤖 Generated with \[Claude Code\]|claude\.com/claude-code'; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked by user opt-out: this command contains a Claude attribution trailer. The user has set attribution.commit and attribution.pr to empty string in ~/.claude/settings.json. Remove any 'Co-Authored-By: Claude', '🤖 Generated with [Claude Code]', or 'claude.com/claude-code' line from the commit message or PR body and retry. Do not add these trailers in future commits/PRs in this session."
  }
}
JSON
fi

exit 0
