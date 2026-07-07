# NOTE: marlonrichert/zsh-autocomplete was removed on purpose — do not re-add it.
# Its async completion uses a `zle -F` fd-widget on a pipe (.autocomplete:async:
# complete:fd-widget / .autocomplete:async:pty) that leaks ~1 unnamed pipe per
# command, so an interactive session climbs toward the open-file limit until zsh
# can no longer dup fd 1 ("cannot duplicate fd 1: too many open files") and every
# external command silently fails. Its unload path is broken too. Vanilla compinit
# Tab completion + zsh-autosuggestions + fzf history search below cover the UX
# without the leak.

# Everything below is deferred with turbo mode (wait lucid): it loads just
# after the first prompt is shown, so it never delays startup.
zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

zinit ice wait lucid atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

# Replaces Ctrl-R with an fzf-backed history picker.
zinit ice lucid wait'0'
zinit light joshskidmore/zsh-fzf-history-search

zinit ice wait lucid
zinit snippet OMZL::git.zsh

# OMZ git defines its own git shortcuts; re-apply ours after it loads (see
# aliases.d/git-shortcuts.zsh for the full story).
zinit ice wait lucid atload'_git_alias_overrides'
zinit snippet OMZP::git

zinit ice wait lucid
zinit snippet OMZP::sudo

zinit ice wait lucid
zinit snippet OMZP::command-not-found

# Third-party completions, also deferred (skipped when not installed).
if [[ -s "$HOME/.bun/_bun" ]]; then
  zinit ice wait lucid
  zinit snippet "$HOME/.bun/_bun"
fi

zinit cdreplay -q
