# Main fish config. Most setup lives in conf.d/*.fish, which fish sources
# automatically (in alphabetical order) before this file.

# Disable the default greeting
set fish_greeting

# Interactive-only setup goes here
if status is-interactive
    # Fish timestamps and incrementally saves deduplicated history by default.
    # It does not expose a configurable history-size limit.
    # Import commands from other live sessions before each prompt.
    function __jkomyno_merge_history --on-event fish_prompt
        if test -z "$fish_private_mode"
            builtin history merge
        end
    end
end
