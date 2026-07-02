# Delete local branches already merged into the default branch, including
# squash-merged ones (detected via git cherry against the merge base)
function gbda -d "Delete merged local branches, including squash-merged"
    set -l default_branch (git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | string replace 'refs/remotes/origin/' '')
    if test -z "$default_branch"
        echo "gbda: cannot determine default branch (try: git remote set-head origin -a)" >&2
        return 1
    end

    # Regular merged branches (*: current branch, +: checked out in a worktree)
    git branch --merged | \
        command grep -vE '^\*|^\+|^\s*(master|main|develop)\s*$' | \
        command xargs -n 1 git branch -d 2>/dev/null

    # Squash-merged branches
    git for-each-ref refs/heads/ "--format=%(refname:short)" | \
        while read branch
            test "$branch" = "$default_branch"; and continue
            set -l merge_base (git merge-base $default_branch $branch 2>/dev/null); or continue
            if string match -q -- '-*' (git cherry $default_branch (git commit-tree (git rev-parse $branch\^{tree}) -p $merge_base -m _))
                git branch -D $branch
            end
        end
end
