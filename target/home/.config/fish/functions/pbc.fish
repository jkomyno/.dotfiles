# pbc: portable clipboard copy shorthand
function pbc --wraps clipboard-copy -d "copy stdin to the clipboard"
    clipboard-copy $argv
end
