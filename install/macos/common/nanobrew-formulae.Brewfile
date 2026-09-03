# Brewfile-style formula bundle consumed by nanobrew.
# Keep GUI apps and fonts in nanobrew-casks.Brewfile.

# Desktop integration
# https://github.com/moretension/duti - manages macOS default application
# associations. It has no mise registry entry or prebuilt GitHub releases.
brew "duti"

# Shells
# https://github.com/fish-shell/fish-shell - friendly interactive shell.
# Lives here instead of mise: a login shell needs a stable path for
# /etc/shells and chsh, which per-version mise installs cannot provide.
brew "fish"

# https://github.com/tsl0922/ttyd - terminal-over-web server that vhs drives
# to record terminal demos. Lives here instead of mise: upstream releases and
# the aqua registry ship no macOS arm64 binaries, only Homebrew has a bottle.
brew "ttyd"

# Machine learning
# https://github.com/microsoft/onnxruntime - cross-platform inference engine for ONNX models.
# Lives here instead of mise: it is a native library (shared objects and headers)
# consumed by other tools, not a versioned CLI, so mise has no backend for it.
brew "onnxruntime"

# Networking
# https://tailscale.com - WireGuard-based mesh VPN; provides `tailscale` and `tailscaled`.
# Lives here instead of mise: it needs a root LaunchDaemon (`tailscaled install-system-daemon`),
# not just a versioned CLI, so a per-version mise install cannot manage the daemon.
# install/macos/common/tailscale.sh wires up the daemon and guides `tailscale up`.
brew "tailscale"
