# gm: checkout the repo's default branch (works for both main and master)
function gm -d "git checkout the default branch"
    git checkout (git symbolic-ref refs/remotes/origin/HEAD | string replace 'refs/remotes/origin/' '')
end
