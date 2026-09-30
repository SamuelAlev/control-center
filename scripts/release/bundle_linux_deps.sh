#!/usr/bin/env bash
#
# Makes the Linux desktop bundle start on a host that has only what
# scripts/lib/linux_desktop.sh assumes: copies the reviewed libraries the bundle
# links (CC_DESKTOP_BUNDLED_LIBS) into <bundle>/lib, points every ELF that needs
# something in the bundle at it, and appends the copied libraries' licenses to
# the bundle's THIRD-PARTY-LICENSES.txt. Runs on the Linux build host.
# Usage: scripts/release/bundle_linux_deps.sh <bundle-dir>
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/linux_desktop.sh"

BUNDLE="$(cd "${1:?usage: bundle_linux_deps.sh <bundle-dir>}" && pwd)"
LIBDIR="$BUNDLE/lib"
NOTICES="$BUNDLE/THIRD-PARTY-LICENSES.txt"

[ "$(uname -s)" = Linux ] || die "bundle_linux_deps.sh runs on the Linux build host"
require_cmd readelf "apt-get install binutils"
require_cmd patchelf "apt-get install patchelf"
require_cmd dpkg-query "run it on the Debian/Ubuntu build host release.yml uses"
[ -d "$LIBDIR" ] || die "no lib/ in $BUNDLE; build the Flutter bundle first"
[ -f "$NOTICES" ] || die "no THIRD-PARTY-LICENSES.txt in $BUNDLE; gen_third_party_licenses.sh runs first"

declare -A HOST=() ALLOWED=() UNLOADED=() COPIED=()
while IFS= read -r soname; do HOST[$soname]=1; done < <(desktop_host_sonames)
for soname in "${CC_DESKTOP_BUNDLED_LIBS[@]}"; do ALLOWED[$soname]=1; done
for soname in "${CC_DESKTOP_UNLOADED_LIBS[@]}"; do UNLOADED[$soname]=1; done

# Copies a library into lib/ and queues it: what it links is resolved like
# everything else in the bundle.
QUEUE=()
bundle_lib() { # soname
  local soname="$1" src
  [ -n "${ALLOWED[$soname]:-}" ] || die "$soname is linked by the bundle but is neither on the host floor nor in CC_DESKTOP_BUNDLED_LIBS (scripts/lib/linux_desktop.sh). Check its license and whether it is safe to carry privately, then add it to one of the two lists."
  src="$(desktop_host_lib_path "$soname")"
  [ -n "$src" ] || die "$soname is linked by the bundle but the build host does not have it; install its -dev package"
  log "bundling $soname ($src)"
  install -m755 "$(readlink -f "$src")" "$LIBDIR/$soname"
  COPIED[$soname]="$src"
  QUEUE+=("$LIBDIR/$soname")
}

while IFS= read -r -d '' f; do QUEUE+=("$f"); done < <(desktop_elf_files "$BUNDLE")

# Every NEEDED is the host's, never loaded, or in the bundle next to (or in
# lib/ below) the ELF that links it, found through a RUNPATH entry INSIDE the
# bundle. A plugin's RUNPATH is the build tree's linux/flutter/ephemeral: it
# exists here, on the build host, and resolves nothing on a user's machine.
i=0
while [ "$i" -lt "${#QUEUE[@]}" ]; do
  elf="${QUEUE[$i]}"
  i=$((i + 1))
  dir="$(dirname "$elf")"
  wanted=()
  while IFS= read -r soname; do
    [ -n "${HOST[$soname]:-}" ] && continue
    [ -n "${UNLOADED[$soname]:-}" ] && continue
    if [ -e "$dir/$soname" ]; then
      target="$dir"
    else
      [ -e "$LIBDIR/$soname" ] || bundle_lib "$soname"
      target="$LIBDIR"
    fi
    # A re-run finds the copy from the last one; its license still has to be
    # appended to the freshly generated notices.
    if [ -n "${ALLOWED[$soname]:-}" ] && [ -z "${COPIED[$soname]:-}" ]; then
      COPIED[$soname]="$(desktop_host_lib_path "$soname")"
    fi
    found=0
    while IFS= read -r searched; do
      case "$searched" in "$BUNDLE" | "$BUNDLE"/*) ;; *) continue ;; esac
      [ -e "$searched/$soname" ] && { found=1; break; }
    done < <(desktop_elf_search_dirs "$elf")
    [ "$found" -eq 1 ] && continue
    if [ "$target" = "$dir" ]; then
      wanted+=('$ORIGIN')
    else
      wanted+=("\$ORIGIN/$(realpath --relative-to="$dir" "$target")")
    fi
  done < <(desktop_elf_needed "$elf")
  [ "${#wanted[@]}" -gt 0 ] || continue
  # Keeps the $ORIGIN-relative entries it already had and drops the absolute
  # ones, which are build-tree paths that do not exist where the app runs.
  runpath="$(
    {
      readelf -dW "$elf" | sed -nE 's/.*\((RUNPATH|RPATH)\).*\[(.*)\]$/\2/p' | tr ':' '\n' | grep -E '^\$(ORIGIN|\{ORIGIN\})' || true
      printf '%s\n' "${wanted[@]}"
    } | awk 'NF && !seen[$0]++' | paste -sd:
  )"
  log "RUNPATH $runpath -> ${elf#"$BUNDLE"/}"
  patchelf --set-rpath "$runpath" "$elf"
done

if [ "${#COPIED[@]}" -eq 0 ]; then
  log "no libraries to bundle"
  exit 0
fi

# LGPL (and most other) libraries ship with their license and a pointer to the
# corresponding source. The Debian copyright file is both, and it may defer the
# license text to /usr/share/common-licenses, which is inlined too.
{
  echo
  echo "SYSTEM LIBRARIES BUNDLED IN THE LINUX BUILD"
  echo "-------------------------------------------"
  echo
  echo "These are unmodified copies from ${CC_DESKTOP_LINUX_BASE} packages,"
  echo "dynamically linked and replaceable. Their source is the named Ubuntu"
  echo "source package at the named version (https://launchpad.net/ubuntu/+source)."
  for soname in $(printf '%s\n' "${!COPIED[@]}" | sort); do
    # The real file, not the soname link: merged-/usr hosts list the link under
    # /lib, which dpkg has no record of.
    pkg="$(dpkg-query -S "$(readlink -f "${COPIED[$soname]}")" | head -n1 | cut -d: -f1)"
    version="$(dpkg-query -W -f='${Version}' "$pkg")"
    source_pkg="$(dpkg-query -W -f='${source:Package}' "$pkg")"
    copyright="/usr/share/doc/$pkg/copyright"
    [ -f "$copyright" ] || die "no copyright file for $pkg ($soname) at $copyright"
    echo
    echo "================================================================================"
    echo "$soname — Ubuntu package $pkg $version (source: $source_pkg)"
    echo "================================================================================"
    echo
    cat "$copyright"
    for common in $(grep -oE '/usr/share/common-licenses/[A-Za-z0-9.+-]+' "$copyright" | sort -u); do
      [ -f "$common" ] || continue
      echo
      echo "--- $common ---"
      echo
      cat "$common"
    done
  done
} >>"$NOTICES"
log "Bundled ${#COPIED[@]} librar$([ "${#COPIED[@]}" -eq 1 ] && echo y || echo ies): $(printf '%s\n' "${!COPIED[@]}" | sort | paste -sd' ')"
