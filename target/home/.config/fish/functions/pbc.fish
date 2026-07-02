# pbc: clipboard copy shorthand
function pbc --wraps pbcopy -d "alias for pbcopy"
    pbcopy $argv
end
