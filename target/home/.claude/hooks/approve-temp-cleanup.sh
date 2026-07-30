#!/bin/bash

set -euo pipefail

payload="$(cat)"

if printf '%s' "${payload}" | jq -e '
  .tool_name == "Bash"
  and ((.tool_input.command // "") | test("^rm[[:space:]]+-rf[[:space:]]+/(tmp|private)/[^[:space:];&|<>$`()]+$"))
  and ((.tool_input.command // "") | test("(^|/)\\.\\.(/|$)") | not)
' >/dev/null 2>&1; then
  printf '%s\n' \
    '{"hookSpecificOutput":{"hookEventName":"PermissionRequest","decision":{"behavior":"allow"}}}'
fi
