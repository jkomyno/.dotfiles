# cd into a fresh temporary directory and print its path
function tempd -d "Change to a new temporary directory"
    set -l tmpdir (mktemp -d)
    cd $tmpdir
    echo $tmpdir
end
