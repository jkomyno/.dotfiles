# gm: checkout the repo's default branch (works for both main and master).
#
# The OMZ git plugin loads *deferred* (after .zshrc finishes) and defines its
# own gm (= git merge) and gbda (merge-only, not squash-aware), which would
# silently override ours. So the definitions live in a function: it runs once
# here, and the `atload` ice on the OMZP::git snippet in .zshrc re-runs it
# right after the plugin loads.
_git_alias_overrides() {
  unalias gbda gm 2>/dev/null
  alias gm='git checkout $(git symbolic-ref refs/remotes/origin/HEAD | sed "s@^refs/remotes/origin/@@")'
}
_git_alias_overrides
