# zsh-autocomplete loads eagerly because it is the interactive editing UX.
zinit light marlonrichert/zsh-autocomplete

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
