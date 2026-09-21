#!/usr/bin/env bash
#
# Builds libccpty (vendored flutter_pty; REQUIRED). Loose dylib so pure-Dart
# cc_server can load it without a Flutter plugin build step.
# Usage: scripts/natives/build_pty.sh [DEST_DIR]
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

DEST="${1:-}"
PTY_SRC_DIR="$REPO_ROOT/packages/cc_natives/native/pty"
UMBRELLA="$PTY_SRC_DIR/flutter_pty.c" # #includes dart_api_dl.c + forkpty.c + flutter_pty_unix.c

case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_pty.sh does not support $(uname -s). Windows natives are built by scripts/release/windows_natives.sh (MSVC + ConPTY)." ;;
esac
native_detect_platform
CC="${CC:-cc}"
require_cmd "$CC" "Install a C toolchain (Xcode CLT on macOS, build-essential on Linux) and re-run."
[ -f "$UMBRELLA" ] || die "PTY umbrella source not found: $UMBRELLA (did the vendored sources move?)"

LIB="libccpty.$NATIVE_EXT"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The vendored .c uses strlen/strcmp without an explicit <string.h> on some
# paths; -Wno-implicit-function-declaration keeps clang's C99 default from
# erroring (the symbols resolve from libc at link time, same as upstream's
# Flutter build).
CFLAGS=(-std=c11 -O2 -fPIC -Wno-implicit-function-declaration -I "$PTY_SRC_DIR")

log "Compiling PTY native ($UMBRELLA) for $NATIVE_OS"
"$CC" "${CFLAGS[@]}" -c "$UMBRELLA" -o "$WORK/ccpty.o"

if [ "$NATIVE_OS" = "Darwin" ]; then
  log "Linking $LIB"
  "$CC" -dynamiclib -o "$WORK/$LIB" "$WORK/ccpty.o" \
    -lpthread \
    -install_name "@rpath/$LIB"
else
  log "Linking $LIB"
  "$CC" -shared -o "$WORK/$LIB" "$WORK/ccpty.o" \
    -Wl,-soname,"$LIB" \
    -lpthread
fi

# Sanity: confirm the exported PTY ABI is present.
if [ "$NATIVE_OS" = "Darwin" ]; then
  for sym in _pty_create _pty_write _pty_resize _pty_getpid; do
    nm -gU "$WORK/$LIB" | grep -q "$sym" || die "built $LIB is missing the ${sym#_} symbol"
  done
else
  for sym in pty_create pty_write pty_resize pty_getpid; do
    nm -D "$WORK/$LIB" | grep -q " $sym" || die "built $LIB is missing the $sym symbol"
  done
fi

# Install to the app-support root (the single dev / runtime location) + the
# optional explicit DEST (CI staging — release packaging copies it into the
# bundle).
dests=("$(native_support_root)")
[ -n "$DEST" ] && dests+=("$DEST")

for d in "${dests[@]}"; do
  mkdir -p "$d"
  cp -f "$WORK/$LIB" "$d/$LIB"
  native_adhoc_sign "$d/$LIB"
  echo "  - $d/$LIB"
done

log "Done. Installed $LIB ($(du -h "$WORK/$LIB" | cut -f1)) to ${#dests[@]} location(s)."
