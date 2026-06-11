# ls: modern listing via eza — long view with group/header columns, ISO
# dates, and icons. Falls back to plain ls if eza is missing.
if command -v eza >/dev/null 2>&1; then
  alias ls="eza --long --group --header --binary --time-style=long-iso --icons"
fi
