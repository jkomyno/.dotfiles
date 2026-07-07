# nanobrew (drop-in Homebrew replacement). PATH for /opt/nanobrew/prefix/bin is
# owned by 00-paths.fish; this file only wires man/info lookup for the prefix.
if test -n "$MANPATH[1]"; set --global --export MANPATH '' $MANPATH; end
if not contains "/opt/nanobrew/prefix/share/info" $INFOPATH
    set --global --export INFOPATH "/opt/nanobrew/prefix/share/info" $INFOPATH
end
