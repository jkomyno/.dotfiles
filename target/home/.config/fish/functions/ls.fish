# ls: modern listing via eza — long view with group/header columns, ISO
# dates, and icons. Falls back to plain ls if eza is missing.
function ls --wraps eza -d "ls via eza (long view, icons)"
    if command -q eza
        eza --long --group --header --binary --time-style=long-iso --icons $argv
    else
        command ls $argv
    end
end
