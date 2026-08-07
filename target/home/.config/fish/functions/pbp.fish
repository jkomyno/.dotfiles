# pbp: portable clipboard paste shorthand
function pbp --wraps clipboard-paste -d "paste clipboard contents"
    clipboard-paste $argv
end
