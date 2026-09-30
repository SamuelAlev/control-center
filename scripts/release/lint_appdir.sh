#!/usr/bin/env bash
#
# Fails a Linux AppDir that AppImageHub's test would reject, or that would not
# start on the host floor in scripts/lib/linux_desktop.sh, before appimagetool
# packs it: the appdir-lint.sh layout, a desktop entry desktop-file-validate
# accepts, AppStream metadata appstreamcli accepts, every ELF inside the glibc/
# libstdc++ floor and every library an ELF links either in the AppDir or the
# host's. Runs on the Linux build host.
# Usage: scripts/release/lint_appdir.sh <AppDir>
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/linux_desktop.sh"

APPDIR="$(cd "${1:?usage: lint_appdir.sh <AppDir>}" && pwd)"

[ "$(uname -s)" = Linux ] || die "lint_appdir.sh runs on the Linux build host"
require_cmd readelf "apt-get install binutils"
require_cmd desktop-file-validate "apt-get install desktop-file-utils"
require_cmd appstreamcli "apt-get install appstream"

failed=0
fail() { printf 'ERROR: %s\n' "$*" >&2; failed=1; }

ver_gt() { # a b -> 0 when a > b
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1)" = "$1" ]
}

log "Linting AppDir $APPDIR"

# Layout. appdir-lint.sh wants an executable AppRun and exactly one top-level
# desktop entry; appimagetool points .DirIcon at the top-level <Icon>.png.
[ -x "$APPDIR/AppRun" ] || fail "AppRun is missing or not executable"
shopt -s nullglob
desktops=("$APPDIR"/*.desktop)
shopt -u nullglob
if [ "${#desktops[@]}" -ne 1 ]; then
  fail "want exactly one top-level .desktop file, found ${#desktops[@]}"
  exit 1
fi
desktop="${desktops[0]}"
id="$(basename "$desktop" .desktop)"
icon="$(sed -nE '/^Icon=/{s/^Icon=//p;q;}' "$desktop")"
[ -n "$icon" ] || fail "$id.desktop has no Icon="
[ -f "$APPDIR/$icon.png" ] || fail "no top-level $icon.png for .DirIcon"
[ -f "$APPDIR/usr/share/applications/$id.desktop" ] || fail "no usr/share/applications/$id.desktop (AppStream's launchable)"
[ -n "$(find "$APPDIR/usr/share/icons/hicolor" \( -name "$icon.png" -o -name "$icon.svg" \) -print -quit 2>/dev/null)" ] ||
  fail "no $icon icon under usr/share/icons/hicolor"

# Desktop entries, with the validator appimagetool and appdir-lint.sh run.
for d in "$desktop" "$APPDIR/usr/share/applications/$id.desktop"; do
  [ -f "$d" ] || continue
  desktop-file-validate "$d" || fail "desktop-file-validate rejects ${d#"$APPDIR"/}"
done

# AppStream. appimagetool and appdir-lint.sh only look for <id>.appdata.xml.
# --no-net: the screenshots are checked where the metadata is written, not in a
# release job whose egress is blocked.
metainfo="$APPDIR/usr/share/metainfo/$id.appdata.xml"
if [ -f "$metainfo" ]; then
  appstreamcli validate-tree --no-net "$APPDIR" || fail "appstreamcli rejects the AppStream metadata"
else
  fail "no usr/share/metainfo/$id.appdata.xml"
fi

declare -A HOST=() UNLOADED=() EXCLUDED=()
while IFS= read -r soname; do HOST[$soname]=1; done < <(desktop_host_sonames)
for soname in "${CC_DESKTOP_UNLOADED_LIBS[@]}"; do UNLOADED[$soname]=1; done
while IFS= read -r soname; do EXCLUDED[$soname]=1; done < <(grep -vE '^[[:space:]]*(#|$)' "$REPO_ROOT/scripts/release/appimage_excludelist")

echo "Checking ELF files: glibc <= $CC_DESKTOP_GLIBC_MAX, GLIBCXX <= $CC_DESKTOP_GLIBCXX_MAX, CXXABI <= $CC_DESKTOP_CXXABI_MAX (${CC_DESKTOP_LINUX_BASE})"
elves=0
while IFS= read -r -d '' elf; do
  elves=$((elves + 1))
  rel="${elf#"$APPDIR"/}"
  name="$(basename "$elf")"
  [ -z "${EXCLUDED[$name]:-}" ] || fail "$rel is on appimage_excludelist and must come from the host"

  # A program (it has an interpreter) that is not executable cannot be spawned.
  if [ ! -x "$elf" ] && readelf -lW "$elf" 2>/dev/null | grep 'Requesting program interpreter' >/dev/null; then
    fail "$rel is a program but not executable"
  fi

  # Only the needs, not the definitions: a library may define versions of its own.
  while IFS= read -r req; do
    case "$req" in
      GLIBCXX_*) floor="$CC_DESKTOP_GLIBCXX_MAX"; version="${req#GLIBCXX_}" ;;
      CXXABI_*) floor="$CC_DESKTOP_CXXABI_MAX"; version="${req#CXXABI_}" ;;
      GLIBC_*) floor="$CC_DESKTOP_GLIBC_MAX"; version="${req#GLIBC_}" ;;
      *) continue ;;
    esac
    if ver_gt "$version" "$floor"; then
      symbols="$(readelf --dyn-syms -W "$elf" 2>/dev/null | grep -F "@$req" | awk '{print $8}' | sed 's/@.*//' | sort -u | paste -sd' ' || true)"
      fail "$rel requires $req (floor $floor) — symbols: ${symbols:-unknown}"
    fi
  done < <(readelf -V -W "$elf" 2>/dev/null | sed -n '/Version needs section/,$p' | grep -oE '(GLIBC|GLIBCXX|CXXABI)_[0-9]+(\.[0-9]+)*' | sort -u)

  while IFS= read -r soname; do
    [ -n "${HOST[$soname]:-}" ] && continue
    [ -n "${UNLOADED[$soname]:-}" ] && continue
    found=0
    while IFS= read -r searched; do
      # Only the AppDir counts: a build-tree RUNPATH exists on this host alone.
      case "$searched" in "$APPDIR" | "$APPDIR"/*) ;; *) continue ;; esac
      [ -e "$searched/$soname" ] && { found=1; break; }
    done < <(desktop_elf_search_dirs "$elf")
    [ "$found" -eq 1 ] || fail "$rel links $soname, which is neither on the host floor nor on its RUNPATH inside the AppDir"
  done < <(desktop_elf_needed "$elf")
done < <(desktop_elf_files "$APPDIR")
[ "$elves" -gt 0 ] || fail "no ELF files in $APPDIR"

[ "$failed" -eq 0 ] || die "AppDir lint failed; AppImageHub's test (and a stock ${CC_DESKTOP_LINUX_BASE} host) would reject this AppImage"
log "AppDir lint passed ($elves ELF files)"
