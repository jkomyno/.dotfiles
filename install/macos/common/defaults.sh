#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -n "${DOTFILES_DEBUG:-}" ]]; then
  set -x
fi

RESET_DOCK="${DOTFILES_RESET_DOCK:-false}"
APPLY_PRIVILEGED_DEFAULTS="${DOTFILES_APPLY_PRIVILEGED_MACOS_DEFAULTS:-false}"
RESTART_AFFECTED_APPS="${DOTFILES_RESTART_AFTER_MACOS_DEFAULTS:-true}"

readonly MACOS_NATURAL_SCROLLING="false"
readonly MACOS_AUTOMATIC_QUOTE_SUBSTITUTION="false"
readonly MACOS_AUTOMATIC_DASH_SUBSTITUTION="false"
readonly MACOS_FONT_SMOOTHING="2"
readonly MACOS_LAUNCHSERVICES_QUARANTINE="false"
readonly MACOS_STARTUP_AUDIO_VOLUME=" "
readonly MACOS_STANDBY_DELAY_SECONDS="86400"
readonly MACOS_HIBERNATE_MODE="3"
readonly MACOS_AC_SLEEP_MINUTES="0"
readonly MACOS_FINDER_ICON_ARRANGE_BY="grid"
readonly NANOBREW_BIN_DIR="${NANOBREW_BIN_DIR:-/opt/nanobrew/prefix/bin}"

log() {
  printf '==> %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
Usage: install/macos/common/defaults.sh [options]

Apply the macOS defaults managed by this dotfiles repository.

Options:
  --reset-dock   Also clear pinned Dock items. Off by default.
  --privileged   Also apply sudo-backed power/login defaults. Off by default.
  --no-restart   Do not restart affected macOS services after writing defaults.
  -h, --help     Show this help.

Environment:
  DOTFILES_RESET_DOCK=1
  DOTFILES_APPLY_PRIVILEGED_MACOS_DEFAULTS=1
  DOTFILES_RESTART_AFTER_MACOS_DEFAULTS=0
USAGE
}

truthy() {
  case "${1:-}" in
    1 | [Tt][Rr][Uu][Ee] | [Yy][Ee][Ss] | [Yy] | [Oo][Nn])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --reset-dock)
        RESET_DOCK="true"
        ;;
      --privileged)
        APPLY_PRIVILEGED_DEFAULTS="true"
        ;;
      --no-restart)
        RESTART_AFFECTED_APPS="false"
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      *)
        die "unknown option: $1"
        ;;
    esac
    shift
  done
}

quit_system_settings() {
  # Open Settings panes can write stale values back after this script changes
  # preferences, so close both the Ventura+ and legacy app names.
  osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true
  osascript -e 'tell application "System Preferences" to quit' >/dev/null 2>&1 || true
}

apply_section() {
  local name="$1"
  shift

  log "${name}"
  "$@"
}

plistbuddy_set_string() {
  local plist="$1"
  local key_path="$2"
  local value="$3"

  if /usr/libexec/PlistBuddy -c "Set ${key_path} ${value}" "${plist}" >/dev/null 2>&1; then
    return 0
  fi

  /usr/libexec/PlistBuddy -c "Add ${key_path} string ${value}" "${plist}" >/dev/null 2>&1 ||
    log "Could not set Finder plist value ${key_path}"
}

defaults_general_ui() {
  # Keep locale choices from the previous dotfiles generation, but avoid
  # machine identity settings such as ComputerName and HostName.
  defaults write NSGlobalDomain AppleLanguages -array "en" "it"
  defaults write NSGlobalDomain AppleLocale -string "en_US@currency=EUR"
  defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
  defaults write NSGlobalDomain AppleMetricUnits -bool true

  # Prefer predictable text rendering and status indicators.
  defaults write NSGlobalDomain AppleFontSmoothing -int "${MACOS_FONT_SMOOTHING}"
  defaults write -g CGFontRenderingFontSmoothingDisabled -bool false
  defaults -currentHost write com.apple.controlcenter BatteryShowPercentage -bool true
  defaults write com.apple.controlcenter "NSStatusItem Visible Bluetooth" -bool true

  # Disable the "Are you sure you want to open this application?" dialog.
  defaults write com.apple.LaunchServices LSQuarantine -bool "${MACOS_LAUNCHSERVICES_QUARANTINE}"
}

defaults_input_devices() {
  # Fast repeat is more useful for editors than the macOS default.
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 20
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Code-friendly text input.
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool "${MACOS_AUTOMATIC_DASH_SUBSTITUTION}"
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool "${MACOS_AUTOMATIC_QUOTE_SUBSTITUTION}"
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

  # Trackpad: invert the macOS default natural scrolling direction.
  defaults write NSGlobalDomain com.apple.swipescrolldirection -bool "${MACOS_NATURAL_SCROLLING}"

  # Trackpad comfort settings for both this user and the login screen.
  defaults write -g com.apple.trackpad.scaling -float 2.0
  defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
}

defaults_application_shortcuts() {
  # Match Ghostty's cmd+j/cmd+k tab navigation. macOS requires the Chrome menu
  # item titles exactly as shown; "@" is the NSUserKeyEquivalents command key.
  defaults write com.google.Chrome NSUserKeyEquivalents -dict-add \
    "Select Previous Tab" "@j" \
    "Select Next Tab" "@k"
}

defaults_file_associations() {
  local duti_bin="${NANOBREW_BIN_DIR}/duti"
  local vscode_bundle_id="com.microsoft.VSCode"
  local extensions=(
    ts
    tsx
    js
    mjs
    cjs
    css
    toml
    rs
    go
    json
    yaml
    yml
    sh
    bash
    zsh
    py
    c
    cpp
    h
    hpp
  )
  local extension

  [[ -x "${duti_bin}" ]] || die "duti is not installed; run install:macos:nanobrew-formulae first"

  # VS Code declares support for Markdown's UTI; assigning every role makes it
  # the default app for opening both .md and .markdown documents.
  "${duti_bin}" -s "${vscode_bundle_id}" net.daringfireball.markdown all

  # Keep this list extension-specific so setup changes only the explicitly
  # requested developer formats, not every type inheriting a broad source UTI.
  for extension in "${extensions[@]}"; do
    "${duti_bin}" -s "${vscode_bundle_id}" ".${extension}" all
  done
}

defaults_screen_and_screenshots() {
  # Require the password immediately after sleep or screen saver starts.
  defaults write com.apple.screensaver askForPassword -int 1
  defaults write com.apple.screensaver askForPasswordDelay -int 0

  # Keep screenshots visible and scriptable.
  mkdir -p "${HOME}/Desktop"
  defaults write com.apple.screencapture location -string "${HOME}/Desktop"
  defaults write com.apple.screencapture type -string "png"
  defaults write com.apple.screencapture show-thumbnail -bool false
}

defaults_finder() {
  local finder_plist="${HOME}/Library/Preferences/com.apple.finder.plist"

  # Show developer-relevant file information by default.
  defaults write com.apple.finder AppleShowAllFiles -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

  # Prefer stable, scannable Finder windows.
  defaults write com.apple.finder NewWindowTarget -string "PfHm"
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
  defaults write com.apple.finder _FXSortFoldersFirst -bool true
  defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

  # Keep external volumes clean and reduce Finder confirmation dialogs.
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
  defaults write com.apple.finder WarnOnEmptyTrash -bool false
  defaults write com.apple.finder FXRemoveOldTrashItems -bool true

  # Snap desktop and icon-view items to the Finder grid. PlistBuddy's Add
  # creates intermediate dictionaries, so the nested key paths are safe.
  plistbuddy_set_string "${finder_plist}" ":DesktopViewSettings:IconViewSettings:arrangeBy" "${MACOS_FINDER_ICON_ARRANGE_BY}"
  plistbuddy_set_string "${finder_plist}" ":FK_StandardViewSettings:IconViewSettings:arrangeBy" "${MACOS_FINDER_ICON_ARRANGE_BY}"
  plistbuddy_set_string "${finder_plist}" ":StandardViewSettings:IconViewSettings:arrangeBy" "${MACOS_FINDER_ICON_ARRANGE_BY}"
}

defaults_dock_and_mission_control() {
  # Keep the Dock out of the way and focused on running applications.
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0.2
  defaults write com.apple.dock tilesize -int 36
  defaults write com.apple.dock show-recents -bool false
  defaults write com.apple.dock static-only -bool true

  # Keep Spaces in a predictable order across work contexts.
  defaults write com.apple.dock mru-spaces -bool false

  if truthy "${RESET_DOCK}"; then
    # Clearing Dock items is intentionally opt-in because it is destructive on
    # an established machine.
    defaults write com.apple.dock persistent-apps -array
    defaults write com.apple.dock persistent-others -array
    defaults write com.apple.dock recent-apps -array
  fi
}

defaults_save_panels() {
  # Expand save/print panels and save to disk by default.
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
  defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
}

defaults_system_apps() {
  # Do not prompt to use newly attached disks for Time Machine.
  defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

  # Do not auto-open Photos/Image Capture when devices are attached.
  defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

  # Prefer explicit activation for assistant/dictation features.
  defaults write com.apple.assistant.support "Assistant Enabled" -bool false
  defaults write com.apple.HIToolbox AppleDictationAutoEnable -bool false

  # Keep Mac App Store updates and inspection tools available.
  defaults write com.apple.appstore WebKitDeveloperExtras -bool true
  defaults write com.apple.commerce AutoUpdate -bool true
}

defaults_login_window() {
  # Show host details at the login window without hard-coding this Mac's name.
  sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
}

defaults_energy_saving() {
  # Set standby delay to 24 hours. The macOS default is often 1 hour.
  sudo pmset -a standbydelay "${MACOS_STANDBY_DELAY_SECONDS}" >/dev/null 2>&1 ||
    log "pmset standbydelay is not supported on this Mac"

  # Hibernation mode:
  # 0 disables hibernation and speeds up entering sleep.
  # 3 copies RAM to disk so state can be restored after power loss.
  sudo pmset -a hibernatemode "${MACOS_HIBERNATE_MODE}" >/dev/null 2>&1 ||
    log "pmset hibernatemode is not supported on this Mac"

  # Disable machine sleep while charging.
  sudo pmset -c sleep "${MACOS_AC_SLEEP_MINUTES}" >/dev/null 2>&1 ||
    log "pmset AC sleep setting is not supported on this Mac"
}

defaults_startup_sound() {
  # Disable the startup sound on macOS versions/hardware that still honor this
  # NVRAM key.
  sudo nvram SystemAudioVolume="${MACOS_STARTUP_AUDIO_VOLUME}" >/dev/null 2>&1 ||
    log "nvram SystemAudioVolume is not supported on this Mac"
}

defaults_privileged() {
  if ! truthy "${APPLY_PRIVILEGED_DEFAULTS}"; then
    return 0
  fi

  # sudo needs either cached credentials or a TTY to prompt on. Skip instead
  # of aborting the whole staged setup in headless runs.
  if ! sudo -n -v 2>/dev/null && ! [[ -r /dev/tty && -w /dev/tty ]]; then
    log "Skipping privileged defaults: sudo needs a password but no TTY is available"
    return 0
  fi

  log "Privileged defaults"
  sudo -v
  defaults_login_window
  defaults_energy_saving
  defaults_startup_sound
}

restart_affected_applications() {
  if ! truthy "${RESTART_AFFECTED_APPS}"; then
    log "Skipping application restarts"
    return 0
  fi

  # Restart only the services directly affected by this script. Avoid killing
  # terminals, browsers, and productivity apps during staged setup.
  local apps=(
    "cfprefsd"
    "Dock"
    "Finder"
    "SystemUIServer"
  )

  log "Restarting affected applications"
  local app
  for app in "${apps[@]}"; do
    killall "${app}" >/dev/null 2>&1 || true
  done
}

main() {
  parse_args "$@"

  [[ "$(uname -s)" == "Darwin" ]] || return 0
  [[ "$(uname -m)" == "arm64" ]] || die "only macOS arm64 is supported today"

  quit_system_settings
  apply_section "General UI defaults" defaults_general_ui
  apply_section "Trackpad, mouse, keyboard, Bluetooth accessories, and input defaults" defaults_input_devices
  apply_section "Application keyboard shortcuts" defaults_application_shortcuts
  apply_section "Default file associations" defaults_file_associations
  apply_section "Screen and screenshot defaults" defaults_screen_and_screenshots
  apply_section "Finder defaults" defaults_finder
  apply_section "Dock and Mission Control defaults" defaults_dock_and_mission_control
  apply_section "Save panel defaults" defaults_save_panels
  apply_section "System app defaults" defaults_system_apps
  defaults_privileged
  restart_affected_applications

  log "macOS defaults applied. Some changes may require logout or restart."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
