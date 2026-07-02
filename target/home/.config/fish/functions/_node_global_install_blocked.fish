# Shared by the npm/pnpm guards: returns 0 when the arguments describe a
# global install/update, which this repo blocks in favor of mise.
function _node_global_install_blocked
    set -l has_global false
    set -l subcommand ""
    set -l expect_location_value false

    for arg in $argv
        if test $expect_location_value = true
            set expect_location_value false
            if test "$arg" = global
                set has_global true
            end
            continue
        end

        switch $arg
            case -g --global --location=global
                set has_global true
            case --location
                set expect_location_value true
            case '-*'
            case '*'
                if test -z "$subcommand"
                    set subcommand $arg
                end
        end
    end

    test $has_global = true; or return 1

    switch $subcommand
        case install i add update up upgrade
            return 0
    end
    return 1
end
