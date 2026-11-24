#!/bin/sh
# mise includes the matching profile on supported Splash hosts.
chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)
version=$(sw_vers -productVersion 2>/dev/null || true)
case "$(uname -s):$(uname -m):$chip" in
  Darwin:arm64:Apple\ M[3-9]*|Darwin:arm64:Apple\ M[1-9][0-9]*)
    major=${version%%.*}
    rest=${version#*.}
    minor=${rest%%.*}
    case "$major:$minor" in *[!0-9:]*|:*) ;; *)
      if [ "$major" -gt 26 ] || { [ "$major" -eq 26 ] && [ "$minor" -ge 4 ]; }; then
        printf 'splash-enabled.toml'
        exit 0
      fi ;;
    esac ;;
esac
printf 'splash-disabled.toml'
