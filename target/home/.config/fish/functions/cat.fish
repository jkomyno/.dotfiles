# cat: syntax-highlighted viewing via bat — line numbers, git gutter, and a
# filename header, but paging disabled so it still dumps straight to the
# terminal like plain cat. Falls back to plain cat if bat is missing.
function cat --wraps bat -d "cat via bat (syntax highlighting, no pager)"
    if command -q bat
        bat --paging=never $argv
    else
        command cat $argv
    end
end
