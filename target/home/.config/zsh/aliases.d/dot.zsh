# dot: run the dotfiles `just` from anywhere without changing the current dir.
# --working-directory makes recipes (which use $PWD and relative script paths)
# resolve against the repo, and the interactive shell's cwd is never touched, so
# it "returns" for free — even on Ctrl-C or failure. Bare `dot` lists recipes.
alias dot="command just --working-directory ~/work/me/.dotfiles --justfile ~/work/me/.dotfiles/justfile"
