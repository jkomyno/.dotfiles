#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

CHECK_SYNTAX_ONLY=false

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/packages.sh [--check-syntax]

Validate and report package ownership for the dotfiles checkout.

The command is portable: on Linux it validates tracked bundle files and skips
macOS installation-state checks. On macOS it also reports installed/missing
Homebrew/nanobrew package entries when brew is available.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-syntax)
      CHECK_SYNTAX_ONLY=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      error "unknown argument: $1"
      usage >&2
      exit 2
      ;;
  esac
done

trim() {
  local text="$1"
  text="${text#"${text%%[![:space:]]*}"}"
  text="${text%"${text##*[![:space:]]}"}"
  printf '%s' "${text}"
}

package_name_from_line() {
  local line="$1"
  if [[ "${line}" =~ ^(brew|cask)[[:space:]]+\"([^\"]+)\" ]]; then
    printf '%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
  fi
}

validate_bundle() {
  local file="$1"
  local allowed_kind="$2"
  local issues=0
  local line_no=0
  local raw line kind name

  require_file "${file}" || return 1

  while IFS= read -r raw || [[ -n "${raw}" ]]; do
    line_no=$((line_no + 1))
    line="$(trim "${raw}")"
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    [[ "${line}" =~ ^cask_args[[:space:]] ]] && continue

    if ! package_name_from_line "${line}" >/dev/null; then
      error "${file#"${DOTFILES_ROOT}"/}:${line_no}: unsupported bundle line: ${line}"
      issues=$((issues + 1))
      continue
    fi

    IFS=$'\t' read -r kind name < <(package_name_from_line "${line}")
    if [[ "${kind}" != "${allowed_kind}" ]]; then
      error "${file#"${DOTFILES_ROOT}"/}:${line_no}: expected ${allowed_kind}, got ${kind} \"${name}\""
      issues=$((issues + 1))
    fi
  done < "${file}"

  return "${issues}"
}

list_bundle_packages() {
  local file="$1"
  local raw line
  while IFS= read -r raw || [[ -n "${raw}" ]]; do
    line="$(trim "${raw}")"
    [[ -z "${line}" || "${line}" == \#* ]] && continue
    package_name_from_line "${line}" || true
  done < "${file}"
}

list_mise_tools() {
  local raw line in_tools=false
  while IFS= read -r raw || [[ -n "${raw}" ]]; do
    line="$(trim "${raw%%#*}")"
    [[ -z "${line}" ]] && continue
    if [[ "${line}" =~ ^\[tools\]$ ]]; then
      in_tools=true
      continue
    fi
    if [[ "${line}" =~ ^\[.*\]$ ]]; then
      in_tools=false
      continue
    fi
    if [[ "${in_tools}" == true && "${line}" =~ ^\"?([^\"=]+)\"?[[:space:]]*= ]]; then
      trim "${BASH_REMATCH[1]}"
      printf '\n'
    fi
  done < "${DOTFILES_MISE_CONFIG}"
}

is_installed_brew_formula() {
  local name="$1"
  brew list --formula 2>/dev/null | grep -qxF "${name}"
}

is_installed_brew_cask() {
  local name="$1"
  brew list --cask 2>/dev/null | grep -qxF "${name}"
}

report_bundle_status() {
  local title="$1"
  local file="$2"
  local kind="$3"
  local installed=0
  local missing=0
  local name entry_kind

  printf '\n%s\n' "${title}"
  while IFS=$'\t' read -r entry_kind name; do
    [[ -n "${entry_kind:-}" && -n "${name:-}" ]] || continue
    if [[ "${kind}" == "brew" ]]; then
      if is_installed_brew_formula "${name}"; then
        printf '  ok      %s\n' "${name}"
        installed=$((installed + 1))
      else
        printf '  missing %s\n' "${name}"
        missing=$((missing + 1))
      fi
    else
      if is_installed_brew_cask "${name}"; then
        printf '  ok      %s\n' "${name}"
        installed=$((installed + 1))
      else
        printf '  missing %s\n' "${name}"
        missing=$((missing + 1))
      fi
    fi
  done < <(list_bundle_packages "${file}")
  printf '  summary installed=%s missing=%s\n' "${installed}" "${missing}"
}

main() {
  local casks_file="${DOTFILES_ROOT}/install/macos/common/nanobrew-casks.Brewfile"
  local formulae_file="${DOTFILES_ROOT}/install/macos/common/nanobrew-formulae.Brewfile"
  local issues=0

  log "Validating package ownership"
  validate_bundle "${casks_file}" "cask" || issues=$((issues + $?))
  validate_bundle "${formulae_file}" "brew" || issues=$((issues + $?))

  local duplicates
  duplicates="$(
    {
      list_mise_tools | sed 's/^/mise\t/'
      list_bundle_packages "${formulae_file}" | awk -F '\t' '{print "nanobrew-formula\t" $2}'
      list_bundle_packages "${casks_file}" | awk -F '\t' '{print "nanobrew-cask\t" $2}'
    } | awk -F '\t' '
      { owners[$2] = owners[$2] ? owners[$2] "," $1 : $1; counts[$2]++ }
      END { for (name in counts) if (counts[name] > 1) print name " -> " owners[name] }
    ' | sort
  )"
  if [[ -n "${duplicates}" ]]; then
    error "duplicate package ownership detected"
    printf '%s\n' "${duplicates}" >&2
    issues=$((issues + 1))
  fi

  if [[ "${CHECK_SYNTAX_ONLY}" == true ]]; then
    if ((issues == 0)); then
      log "Package bundle syntax is valid"
    fi
    return "${issues}"
  fi

  if ! is_macos; then
    info "Skipping install-state checks on $(os_name); nanobrew bundles are macOS-only"
    return "${issues}"
  fi

  if ! have brew; then
    warn "brew is not available; run setup.sh or install/macos/common/homebrew.sh before install-state checks"
    return "${issues}"
  fi

  report_bundle_status "nanobrew formulae" "${formulae_file}" "brew"
  report_bundle_status "nanobrew casks" "${casks_file}" "cask"

  return "${issues}"
}

main "$@"
