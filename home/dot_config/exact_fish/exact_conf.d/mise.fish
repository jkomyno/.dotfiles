# mise — version manager for node, python, rust, ...
# Activated eagerly so node/python/etc work immediately in every new shell.
# Do not cache this: `mise activate` embeds the live PATH in its output.
if test -x "$HOME/.local/bin/mise"
    "$HOME/.local/bin/mise" activate fish | source
end
