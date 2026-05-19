#!/usr/bin/env bash
#
# Builds libccpty — the pseudo-terminal native (vendored verbatim from
# flutter_pty 0.4.2, see packages/cc_natives/native/pty/PROVENANCE.md) — and
# installs it where the cc_natives PTY loader looks for it (the app-support root
# next to control_center.db, plus an optional explicit DEST for CI staging /
# bundle embedding).
#
# Why a loose dylib: flutter_pty is a Flutter ffiPlugin (its C is compiled only
# by `flutter build`). The pure-Dart `cc_server` binary (`dart build cli`) has
# no Flutter build step, so the headless server can't use the plugin. We compile
# the identical C here — the same runtime-dylib pattern as rift / fff /
# tree-sitter / aec — and load it via dart:ffi DynamicLibrary at runtime, so the
# headless agent executor can spawn PTYs (claude-relay, sandboxed shells).
#
# Self-contained: only libc + pthread (no third-party clone, unlike build_aec).
# The Dart Native API DL (Dart_PostCObject_DL) is compiled in from the vendored
# include/dart_api_dl.c — it links against the loading process's Dart runtime at
# load time, so the SAME dylib works in the standalone Dart VM and under Flutter.
#
# Cross-platform: macOS (arm64/x86_64) and Linux (x86_64/arm64) here; Windows is
# built separately by scripts/release/windows_natives.sh (MSVC + flutter_pty_win.c).
# Any other OS is skipped (exit 0) so build_natives.sh stays best-effort.
#
# Requirements: a C compiler (cc/clang/gcc).
#
# Usage:
#   scripts/natives/build_pty.sh [DEST_DIR]
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

DEST="${1:-}"
PTY_SRC_DIR="$REPO_ROOT/packages/cc_natives/native/pty"
UMBRELLA="$PTY_SRC_DIR/flutter_pty.c" # #includes dart_api_dl.c + forkpty.c + flutter_pty_unix.c

case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    warn "build_pty.sh: unsupported platform $(uname -s) — build the PTY native on Windows via scripts/release/windows_natives.sh."
    exit 0 ;;
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
