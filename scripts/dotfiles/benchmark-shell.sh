#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=./lib.sh
source "${SCRIPT_DIR}/lib.sh"

RUNS=10
SHELL_NAME=""
VERBOSE=false
RESULTS_FILE=""

usage() {
  cat <<'USAGE'
Usage: scripts/dotfiles/benchmark-shell.sh [--shell zsh|fish|bash] [--runs N] [--verbose]

Measure interactive shell startup time. Defaults to zsh when available, then
the user's login shell, then bash.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --shell)
      [[ $# -ge 2 ]] || {
        error "--shell requires a value"
        exit 2
      }
      SHELL_NAME="$2"
      shift 2
      ;;
    --runs|-r)
      [[ $# -ge 2 ]] || {
        error "--runs requires a value"
        exit 2
      }
      RUNS="$2"
      shift 2
      ;;
    --verbose|-v)
      VERBOSE=true
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

if ! [[ "${RUNS}" =~ ^[0-9]+$ ]] || ((RUNS < 1 || RUNS > 200)); then
  error "--runs must be an integer between 1 and 200"
  exit 2
fi

choose_shell() {
  if [[ -n "${SHELL_NAME}" ]]; then
    command -v "${SHELL_NAME}"
    return
  fi

  if have zsh; then
    command -v zsh
  elif [[ -n "${SHELL:-}" && -x "${SHELL}" ]]; then
    printf '%s\n' "${SHELL}"
  elif have bash; then
    command -v bash
  else
    return 1
  fi
}

time_once() {
  local shell_path="$1"

  if have python3; then
    python3 - "${shell_path}" <<'PY'
import subprocess
import sys
import time

shell = sys.argv[1]
start = time.perf_counter()
subprocess.run([shell, "-i", "-c", "exit"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
print(f"{time.perf_counter() - start:.6f}")
PY
    return
  fi

  if have perl; then
    perl -MTime::HiRes=time -e '
      my $shell = shift @ARGV;
      my $start = time();
      system($shell, "-i", "-c", "exit >/dev/null 2>&1");
      printf "%.6f\n", time() - $start;
    ' "${shell_path}"
    return
  fi

  error "python3 or perl is required for timing"
  return 1
}

main() {
  local shell_path
  shell_path="$(choose_shell)" || {
    error "no shell found to benchmark"
    return 1
  }

  log "Benchmarking ${shell_path} interactive startup (${RUNS} runs)"

  RESULTS_FILE="$(mktemp)"
  trap 'rm -f "${RESULTS_FILE}"' EXIT

  local i elapsed
  for i in $(seq 1 "${RUNS}"); do
    elapsed="$(time_once "${shell_path}")"
    printf '%s\n' "${elapsed}" >> "${RESULTS_FILE}"
    if [[ "${VERBOSE}" == true ]]; then
      printf 'run %3d: %.3fs\n' "${i}" "${elapsed}"
    fi
  done

  awk '
    NR == 1 { min = $1; max = $1 }
    { sum += $1; if ($1 < min) min = $1; if ($1 > max) max = $1 }
    END {
      avg = sum / NR
      printf "runs: %d\n", NR
      printf "average: %.3fs\n", avg
      printf "fastest: %.3fs\n", min
      printf "slowest: %.3fs\n", max
      if (avg <= 0.050) print "assessment: excellent"
      else if (avg <= 0.100) print "assessment: good"
      else if (avg <= 0.200) print "assessment: fair"
      else print "assessment: slow"
    }
  ' "${RESULTS_FILE}"

  printf 'profile hint: %s --profile /tmp/shell-startup.profile -i -c exit\n' "${shell_path}"
}

main "$@"
