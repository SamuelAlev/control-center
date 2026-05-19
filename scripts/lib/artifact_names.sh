#!/usr/bin/env bash
#
# Usage:
#   source scripts/lib/artifact_names.sh   # then release_asset_name <kind> <ver>
#   bash   scripts/lib/artifact_names.sh 1.2.3   # print the complete set
#
# THE release artifact name table. Every other place that names a shipped file
# derives from here or is pinned against it by
# test/tooling/release_assets_test.dart:
#
#   scripts/release/make_release.sh      the collect/checksum/upload manifest
#   scripts/release/macos_package.sh     the DMG it writes
#   scripts/release/linux_package.sh     the AppImage + tarball it writes
#   scripts/release/windows_package.sh   the installer + portable zip it writes
#   scripts/release/cc_server_package.sh the standalone server archives
#   scripts/release/gen_appcast.sh       the enclosures the updaters download
#   .github/workflows/release.yml        the attest + upload globs
#   RELEASING.md                         the "What gets built" table
#
# These names are a PUBLIC interface: `cc_server update` matches its download
# against `cc_server-<ver>-<os>-<arch>.{tar.gz,zip}`, the Sparkle appcasts embed
# the desktop names as signed enclosure URLs, and SHA256SUMS.txt keys on them.
# Renaming one is a breaking change for already-installed clients, not a
# cosmetic edit.
#
# Use it either way:
#   source scripts/lib/artifact_names.sh; release_asset_name dmg 1.2.3
#   bash   scripts/lib/artifact_names.sh 1.2.3      # prints the complete set

# Echoes one artifact's file name.
release_asset_name() { # kind version
  local kind="$1" v="$2"
  case "$kind" in
    dmg)             printf 'Control-Center-%s-arm64.dmg\n' "$v" ;;
    win-setup)       printf 'Control-Center-%s-x64-setup.exe\n' "$v" ;;
    win-portable)    printf 'Control-Center-%s-windows-x64.zip\n' "$v" ;;
    appimage)        printf 'Control-Center-%s-x86_64.AppImage\n' "$v" ;;
    linux-tarball)   printf 'Control-Center-%s-linux-x64.tar.gz\n' "$v" ;;
    server-macos)    printf 'cc_server-%s-macos-arm64.tar.gz\n' "$v" ;;
    server-linux)    printf 'cc_server-%s-linux-x64.tar.gz\n' "$v" ;;
    server-windows)  printf 'cc_server-%s-windows-x64.zip\n' "$v" ;;
    *) printf 'release_asset_name: unknown kind %s\n' "$kind" >&2; return 1 ;;
  esac
}

# WHICH PLATFORMS THIS RELEASE SHIPS.
#
# This one list drives everything downstream: the expected-asset gate in
# make_release.sh, the Sparkle feeds, the release notes, and the drift tests.
# Adding or dropping a platform is this line and the matching build job in
# .github/workflows/release.yml — nothing else needs editing.
RELEASE_PLATFORMS="${RELEASE_PLATFORMS:-macos linux windows}"

# The artifact kinds each platform contributes, in release-notes order.
release_platform_kinds() { # macos|linux|windows
  case "$1" in
    macos)   printf 'dmg\nserver-macos\n' ;;
    linux)   printf 'appimage\nlinux-tarball\nserver-linux\n' ;;
    windows) printf 'win-setup\nwin-portable\nserver-windows\n' ;;
    *) printf 'release_platform_kinds: unknown platform %s\n' "$1" >&2; return 1 ;;
  esac
}

# The Sparkle feed a platform's updater reads, if it has one. Linux is
# notify-only (no Sparkle backend), so it contributes none.
release_platform_feed() { # macos|linux|windows
  case "$1" in
    macos)   printf 'appcast.xml\n' ;;
    windows) printf 'appcast-windows.xml\n' ;;
  esac
}

# Echoes every artifact name for a version, one per line (feeds included).
release_asset_names() { # version
  local platform kind feed
  for platform in $RELEASE_PLATFORMS; do
    while IFS= read -r kind; do
      release_asset_name "$kind" "$1"
    done < <(release_platform_kinds "$platform")
  done
  for platform in $RELEASE_PLATFORMS; do
    feed="$(release_platform_feed "$platform")"
    [ -n "$feed" ] && printf '%s\n' "$feed"
  done
  return 0
}

# True when a platform is part of this release.
release_ships_platform() { # macos|linux|windows
  case " $RELEASE_PLATFORMS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Executed rather than sourced: print the set (this is what the drift test reads).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  set -euo pipefail
  release_asset_names "${1:?usage: artifact_names.sh <version>}"
fi
