# Block global npm/pnpm installs: CLI tools are owned by mise (see CLAUDE.md
# "Tool Ownership"). `mise use -g npm:<package>` edits the managed
# ~/.config/mise/config.toml, which symlinks back into the dotfiles repo.

_node_global_install_blocked() {
  local has_global="false"
  local subcommand=""

  while (($#)); do
    case "$1" in
      -g | --global | --location=global)
        has_global="true"
        ;;
      --location)
        shift
        [[ "${1:-}" == "global" ]] && has_global="true"
        ;;
      -*) ;;
      *)
        [[ -z "${subcommand}" ]] && subcommand="$1"
        ;;
    esac
    shift
  done

  [[ "${has_global}" == "true" ]] || return 1

  case "${subcommand}" in
    install | i | add | update | up | upgrade)
      return 0
      ;;
  esac
  return 1
}

_node_global_install_message() {
  print -u2 "$1 global install/update is blocked: CLI tools are managed by mise."
  print -u2 '  Add the tool with: mise use -g "npm:<package>"'
  print -u2 '  (this edits the managed mise config in the dotfiles repo)'
}

npm() {
  if _node_global_install_blocked "$@"; then
    _node_global_install_message npm
    return 1
  fi
  command npm "$@"
}

pnpm() {
  if _node_global_install_blocked "$@"; then
    _node_global_install_message pnpm
    return 1
  fi
  command pnpm "$@"
}
