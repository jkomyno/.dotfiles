# Brewfile-style formula bundle consumed by nanobrew.
# Keep GUI apps and fonts in nanobrew-casks.Brewfile.

# Shells
# https://github.com/fish-shell/fish-shell - friendly interactive shell.
# Lives here instead of mise: a login shell needs a stable path for
# /etc/shells and chsh, which per-version mise installs cannot provide.
brew "fish"

# Media tools
# https://github.com/FFmpeg/FFmpeg - audio and video processing toolkit.
# Lives here instead of mise: the mise ffmpeg plugin builds from source,
# which is impractically slow and fragile on macOS.
brew "ffmpeg"

# Machine learning
# https://github.com/microsoft/onnxruntime - cross-platform inference engine for ONNX models.
# Lives here instead of mise: it is a native library (shared objects and headers)
# consumed by other tools, not a versioned CLI, so mise has no backend for it.
brew "onnxruntime"
