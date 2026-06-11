# Block global pnpm installs: CLI tools are owned by mise (see CLAUDE.md
# "Tool Ownership"). `mise use -g npm:<package>` edits the chezmoi-managed
# mise config, which symlinks back into the dotfiles repo.
function pnpm -d "pnpm with a guard against global installs" --wraps pnpm
    if _node_global_install_blocked $argv
        echo "pnpm global install/update is blocked: CLI tools are managed by mise." >&2
        echo '  Add the tool with: mise use -g "npm:<package>"' >&2
        return 1
    end
    command pnpm $argv
end
