# Portable login-shell setup, with platform-specific additions rendered by mise.
typeset -gU path

# Raise the open-file soft limit, inherited by every child of this login shell.
# GUI-launched macOS shells default to a low 256, which a leaky interactive
# plugin or an fd-heavy command (e.g. `mise reshim`) can exhaust — at which point
# zsh can no longer dup fd 1 and external commands fail silently. 8192 is ample
# headroom; fall back to the hard cap when it is lower.
ulimit -Sn 8192 2>/dev/null || ulimit -Sn "$(ulimit -Hn)" 2>/dev/null || true

if [ -d "${HOME}/.local/bin" ]; then
  path=("${HOME}/.local/bin" $path)
fi
{%- if os() == "macos" and arch() == "arm64" %}
# Command-line entrypoints shipped inside GUI app bundles.
path=(
  $path
  "/Applications/Visual Studio Code.app/Contents/Resources/app/bin"(N-/)
)

# OrbStack command-line tools and shell integration.
if [ -r "${HOME}/.orbstack/shell/init.zsh" ]; then
  source "${HOME}/.orbstack/shell/init.zsh"
fi
{%- elif os() == "linux" %}
# User-installed binaries follow the XDG layout on Linux.
{%- else %}
# Unsupported platform for now.
{%- endif %}

{%- if os() == "macos" and arch() == "arm64" %}
if [ -d /opt/nanobrew/prefix/bin ]; then
  path=(/opt/nanobrew/prefix/bin $path)
  # Nanobrew relocates Homebrew bottles from /opt/homebrew, but ncurses keeps
  # its compiled terminfo path. Use the relocated and system databases as
  # fallbacks while Ghostty's explicit TERMINFO entry retains precedence.
  export TERMINFO_DIRS="/opt/nanobrew/prefix/share/terminfo:/usr/share/terminfo"
fi
{%- endif %}
