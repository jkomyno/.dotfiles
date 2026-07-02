# Move files to the macOS Trash instead of permanently deleting them
function trash -d "Move files to trash instead of deleting"
    if test (count $argv) -lt 1
        echo "Usage: trash <file>..." >&2
        return 1
    end

    for file in $argv
        if not test -e $file
            echo "trash: '$file' does not exist" >&2
            continue
        end

        set -l dest ~/.Trash/(basename $file)
        # Avoid clobbering an identically named item already in the trash
        if test -e $dest
            set dest "$dest."(date +%s)
        end
        mv -v $file $dest
    end
end
