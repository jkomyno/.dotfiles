# cat: syntax-highlighted viewing via bat — line numbers, git gutter, and a
# filename header, but paging disabled so it still dumps straight to the
# terminal like plain cat. Falls back to plain cat if bat is missing.
if command -v bat >/dev/null 2>&1; then
  alias cat="bat --paging=never"
fi
