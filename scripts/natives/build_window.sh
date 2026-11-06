#!/usr/bin/env bash
#
# Builds libcc_window (REQUIRED on macOS and Linux): OS-level window listing,
# capture, input and accessibility for desktop apps Control Center launched.
# Needs only a C toolchain. The Linux library loads X11 at runtime, so no X
# development packages are involved and it still loads on a headless server.
# Windows is exempt in scripts/lib/natives.sh until CI builds
# cc_window_windows.cpp.
# Usage: scripts/natives/build_window.sh [DEST_DIR]
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

DEST="${1:-}"
SRC_DIR="$REPO_ROOT/packages/cc_natives/native/window"

case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_window.sh does not support $(uname -s). cc_window is exempt on Windows; see scripts/lib/natives.sh." ;;
esac
native_detect_platform
CC="${CC:-cc}"
require_cmd "$CC" "Install a C toolchain (Xcode CLT on macOS, build-essential on Linux) and re-run."

LIB="libcc_window.$NATIVE_EXT"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log "Compiling cc_window for $NATIVE_OS"
if [ "$NATIVE_OS" = "Darwin" ]; then
  # ScreenCaptureKit is weak: the app's floor is macOS 13, and screenshots need
  # 14. An older host reports that from cc_window_capture instead of failing to
  # load. No AppKit, because the boot preflight dlopens this.
  "$CC" -fobjc-arc -fvisibility=hidden -O2 -Wall -Wextra \
    -mmacosx-version-min=13.0 -dynamiclib "$SRC_DIR/cc_window_macos.m" \
    -o "$WORK/$LIB" \
    -framework Foundation -framework CoreGraphics \
    -framework ApplicationServices -framework ImageIO \
    -framework CoreServices -weak_framework ScreenCaptureKit \
    -install_name "@rpath/$LIB"
else
  "$CC" -std=c11 -O2 -Wall -Wextra -fPIC -fvisibility=hidden -shared \
    -I "$SRC_DIR" "$SRC_DIR/cc_window_linux.c" -o "$WORK/$LIB" \
    "${NATIVE_SONAME}$LIB" -ldl -lpthread
fi

# Sanity: confirm the exported ABI is present.
# `grep`, not `grep -q`: exiting at the match SIGPIPEs `nm` on a large table,
# which pipefail reports as a missing symbol (see build_aec.sh).
for sym in cc_window_abi_version cc_window_free cc_window_list cc_window_capture \
  cc_window_mouse cc_window_scroll cc_window_key cc_window_text \
  cc_window_read_ui cc_window_permissions cc_window_open_settings; do
  if [ "$NATIVE_OS" = "Darwin" ]; then
    nm -gU "$WORK/$LIB" | grep "_$sym" >/dev/null || die "built $LIB is missing the $sym symbol"
  else
    nm -D "$WORK/$LIB" | grep " $sym" >/dev/null || die "built $LIB is missing the $sym symbol"
  fi
done

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
