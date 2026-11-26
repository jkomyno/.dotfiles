#!/usr/bin/env bash
# First line of ~/.config/dotfiles/profile is the profile; subsequent lines add bundles.
# This file is sourced by Bash 3.2 bootstraps and invoked by mise templates.
profile_error() { printf 'dotfiles profile: %s\n' "$*" >&2; return 2; }

profile_resolve() {
  local file="${HOME}/.config/dotfiles/profile" requested="${1:-}" item extras="" chosen=""
  local catalog="web go system-engineering machine-learning personal-extras"
  local -a selection_parts
  if [[ $# -gt 0 ]]; then shift; fi
  if [[ -n "${requested}" ]]; then
    DOTFILES_PROFILE_ORIGIN=requested
  elif [[ -n "${DOTFILES_SELECTION:-}" ]]; then
    # Encoded only by this resolver; validate inherited tokens again.
    IFS=' ' read -r -a selection_parts <<<"${DOTFILES_SELECTION}"
    set -- "${selection_parts[@]}"
    requested="$1"
    shift
    DOTFILES_PROFILE_ORIGIN=inherited
  elif [[ -e "${file}" || -L "${file}" ]]; then
    [[ -f "${file}" && -r "${file}" ]] || { profile_error "cannot read ${file}"; return 2; }
    {
      IFS= read -r requested || [[ -n "${requested}" ]] || { profile_error "empty ${file}"; return 2; }
      while IFS= read -r item || [[ -n "${item}" ]]; do set -- "$@" "${item}"; done
    } <"${file}"
    DOTFILES_PROFILE_ORIGIN=saved
  else
    requested=full
    DOTFILES_PROFILE_ORIGIN=default
  fi
  case "${requested}" in
    full) chosen="${catalog}" ;;
    work) chosen=web ;;
    essentials) ;;
    *) profile_error "unknown profile '${requested}'"; return 2 ;;
  esac
  for item in "$@"; do
    case " ${catalog} " in
      *" ${item} "*) [[ -n "${item}" && "${item}" != *" "* ]] || { profile_error "invalid bundle '${item}'"; return 2; } ;;
      *) profile_error "unknown bundle '${item}'"; return 2 ;;
    esac
    if [[ "${item}" == personal-extras && "${requested}" != full ]]; then
      profile_error "personal-extras belongs to the full profile"
      return 2
    fi
    extras="${extras} ${item}"
  done
  DOTFILES_PROFILE="${requested}"
  DOTFILES_BUNDLES=essentials
  DOTFILES_SELECTION="${requested}"
  for item in ${catalog}; do
    case " ${chosen} ${extras} " in *" ${item} "*) DOTFILES_BUNDLES+=" ${item}" ;; esac
    case " ${extras} " in *" ${item} "*) DOTFILES_SELECTION+=" ${item}" ;; esac
  done
  export DOTFILES_SELECTION DOTFILES_PROFILE DOTFILES_BUNDLES
}

profile_has() { [[ " ${DOTFILES_BUNDLES} " == *" $1 "* ]]; }
profile_report() { printf 'Profile %s (%s), bundles: %s\n' "${DOTFILES_PROFILE}" "${DOTFILES_PROFILE_ORIGIN}" "${DOTFILES_BUNDLES}" >&2; }

profile_save() {
  local dir="${HOME}/.config/dotfiles" tmp
  mkdir -p "${dir}" || return 1
  tmp="$(mktemp "${dir}/profile.XXXXXX")" || return 1
  printf '%s\n' ${DOTFILES_SELECTION} >"${tmp}" && mv -f "${tmp}" "${dir}/profile"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -eu
  profile_resolve
  case "${1:-bundles}" in
    bundles) printf '%s\n' "${DOTFILES_BUNDLES}" ;;
    profile) printf '%s\n' "${DOTFILES_PROFILE}" ;;
    has) profile_has "$2" ;;
    include)
      printf '%s/' "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
      if [[ "$2" == splash ]] && profile_has machine-learning; then
        if [[ "${DOTFILES_LOCK_CATALOG:-}" == 1 ]]; then
          printf 'splash-enabled.toml\n'
        else
          sh "$(dirname -- "${BASH_SOURCE[0]}")/splash-profile.sh"
        fi
      elif profile_has "${2%%.*}"; then
        printf 'bundles/%s.toml\n' "$2"
      else
        printf 'bundles/empty.toml\n'
      fi
      ;;
    *) profile_error "unknown operation: $1" ;;
  esac
fi
