#!/usr/bin/env bash
# Writes the THIRD-PARTY-LICENSES.txt a packaged artifact carries.
#
# Usage:
#   bash scripts/release/gen_third_party_licenses.sh <role> <out-file>
#
#   role      desktop | server  — which component set the artifact ships
#   out-file  where to write (the packagers put it beside the app / in the
#             archive root)
#
# The component table is scripts/lib/third_party.sh; the license texts live in
# third_party/licenses/. Nothing is fetched: a signed artifact must not depend
# on a network read at package time, and the Linux release job blocks egress
# anyway.
#
# WHY THIS EXISTS. Control Center itself is MIT, but the artifacts redistribute
# a dozen third-party components — and one of them, libmp3lame, is LGPL-2.1 and
# STATICALLY linked. MIT/BSD/Apache all require their notice to travel with the
# binary; LGPL-2.1 section 6 additionally requires that a recipient be able to
# relink. Shipping only the app's own LICENSE satisfied none of that.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export REPO_ROOT

# shellcheck source=../lib/common.sh
. "$REPO_ROOT/scripts/lib/common.sh"
# shellcheck source=../lib/third_party.sh
. "$REPO_ROOT/scripts/lib/third_party.sh"

ROLE="${1:-}"
OUT="${2:-}"
case "$ROLE" in
  desktop | server) ;;
  *)
    echo "usage: $0 <desktop|server> <out-file>" >&2
    exit 2
    ;;
esac
[ -n "$OUT" ] || {
  echo "usage: $0 <desktop|server> <out-file>" >&2
  exit 2
}

# Versions come from the same pins the build compiles against, so this file
# cannot drift from what actually shipped.
load_native_pins

LICENSE_DIR="$REPO_ROOT/third_party/licenses"
APP_VERSION="${VERSION:-$(grep -m1 '^version:' "$REPO_ROOT/pubspec.yaml" | sed -E 's/version:[[:space:]]*//')}"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  echo "Control Center — third-party licenses"
  echo "====================================="
  echo
  echo "Version: $APP_VERSION  (artifact role: $ROLE)"
  echo
  echo "Control Center itself is distributed under the MIT License; see the"
  echo "LICENSE file that accompanies it, or"
  echo "https://github.com/SamuelAlev/control-center/blob/main/LICENSE."
  echo
  echo "This artifact additionally redistributes the components listed below."
  echo "Each one's full license text is reproduced in this file."
  echo
  if [ "$ROLE" = desktop ]; then
    echo "Dart and Flutter package dependencies, and the Flutter engine's own"
    echo "third-party code, are covered by the engine-generated NOTICES file"
    echo "inside the application bundle (flutter_assets/NOTICES)."
    echo
  fi
  echo "SUMMARY"
  echo "-------"
  printf '%-26s %-12s %-20s %s\n' COMPONENT VERSION LICENSE LINKAGE
  while IFS='|' read -r name version spdx _home _file linkage; do
    printf '%-26s %-12s %-20s %s\n' "$name" "$version" "$spdx" "$linkage"
  done < <(cc_third_party_for "$ROLE")
  echo
} >"$tmp"

# The LGPL relink offer only has to appear when a copyleft component is in this
# artifact's set.
#
# `grep -c`, never `grep -q`: -q closes the pipe on the first match, the
# producer takes SIGPIPE, and under `set -o pipefail` the whole condition then
# evaluates FALSE. The notice silently never printed.
lgpl_components="$(cc_third_party_for "$ROLE" | grep -c 'LGPL' || true)"
if [ "${lgpl_components:-0}" -gt 0 ]; then
  {
    echo "NOTICE — LGPL COMPONENTS AND RELINKING"
    echo "--------------------------------------"
    echo "libmp3lame (LAME) is licensed under the GNU Lesser General Public"
    echo "License version 2.1 and is linked statically into the liblame_ffi"
    echo "library shipped here. Under section 6 of that license you may modify"
    echo "libmp3lame and relink it into this work. Everything required to do so"
    echo "is public:"
    echo
    echo "  * The exact upstream release used, and its SHA-256, are pinned in"
    echo "    scripts/lib/native_pins.env (LAME_VERSION, LAME_SHA256)."
    echo "  * The shim that links it — its complete source — is"
    echo "    packages/cc_natives/native/lame_ffi.cc."
    echo "  * The build recipe is scripts/natives/build_lame.sh, which accepts"
    echo "    LAME_PREFIX=<dir> to link against a libmp3lame you built."
    echo
    echo "All three are in the Control Center source repository at"
    echo "https://github.com/SamuelAlev/control-center. LAME upstream sources"
    echo "are at https://lame.sourceforge.io/."
    echo
  } >>"$tmp"
fi

while IFS='|' read -r name version spdx home file _linkage; do
  text="$LICENSE_DIR/$file"
  [ -f "$text" ] || die "missing license text: third_party/licenses/$file (for $name)"
  {
    echo
    echo "================================================================================"
    echo "$name $version"
    echo "$spdx — $home"
    echo "================================================================================"
    echo
    cat "$text"
  } >>"$tmp"
done < <(cc_third_party_for "$ROLE")

mkdir -p "$(dirname "$OUT")"
command mv "$tmp" "$OUT"
trap - EXIT
log "Wrote $OUT ($(wc -c <"$OUT" | tr -d ' ') bytes, role=$ROLE)"
