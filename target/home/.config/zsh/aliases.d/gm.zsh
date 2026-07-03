# git shortcuts that need to beat OMZ's deferred git aliases.
#
# The OMZ git plugin loads *deferred* (after .zshrc finishes) and defines its
# own gp, gco, gm, and gbda, which would silently override ours. So these
# definitions live in a function: it runs once here, and the `atload` ice on
# the OMZP::git snippet in .zshrc re-runs it right after the plugin loads.
_git_alias_overrides() {
  unalias gbda gco gcom gm gp gpl 2>/dev/null

  if ! whence -w git_current_branch >/dev/null 2>&1; then
    function git_current_branch {
      local branch
      branch="$(command git branch --show-current 2>/dev/null)" && [[ -n "$branch" ]] && {
        print -r -- "$branch"
        return 0
      }
      command git rev-parse --short HEAD 2>/dev/null
    }
  fi

  function git_primary_branch {
    local branch

    branch="$(command git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)" && [[ -n "$branch" ]] && {
      print -r -- "${branch#origin/}"
      return 0
    }

    for branch in main master; do
      if command git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null ||
        command git show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
        print -r -- "$branch"
        return 0
      fi
    done

    print -u2 "git_primary_branch: unable to determine primary branch"
    return 1
  }

  function gpl {
    local branch
    branch="$(git_current_branch)" || return
    git pull origin "$branch"
  }

  function gp {
    local branch
    branch="$(git_current_branch)" || return
    git push origin "$branch"
  }

  function gco {
    git checkout "$@"
  }

  function gcom {
    local branch
    branch="$(git_primary_branch)" || return
    git checkout "$branch"
  }

  alias gm='gcom'
}
_git_alias_overrides

_git_is_github_pr_url() {
  case "$1" in
    http://github.com/*/*/pull/[0-9]* | https://github.com/*/*/pull/[0-9]*) return 0 ;;
  esac
  return 1
}

function git {
  if [[ "$1" == "checkout" && "$#" -eq 2 ]] && _git_is_github_pr_url "$2"; then
    command gh pr checkout "$2"
    return
  fi

  command git "$@"
}

(( $+functions[compdef] )) && compdef _git git
