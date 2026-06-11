# ct: keep the Mac awake while Ghostty is running (display may still sleep)
function ct --wraps coffee -d "coffee -d app Ghostty"
    coffee -d app Ghostty
end
