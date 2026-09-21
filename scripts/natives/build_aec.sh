#!/usr/bin/env bash
#
# Builds libaec_ffi over WebRTC AEC3 (REQUIRED). Installs to app-support +
# optional DEST. Pins via natives_common / native_pins.env.
# Usage: scripts/natives/build_aec.sh [DEST_DIR]
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

# Pins come from scripts/lib/native_pins.env (the only place a SHA lives; an
# env override still wins, for one-off bisects).
load_native_pins
DEST="${1:-}"
SHIM="$REPO_ROOT/packages/cc_natives/native/aec_ffi.cc"

# native_detect_platform aborts on anything but Darwin/Linux; on Windows the
# release pipeline uses scripts/release/windows_natives.sh instead.
case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_aec.sh does not support $(uname -s). Windows natives are built by scripts/release/windows_natives.sh (MSVC)." ;;
esac
native_detect_platform
require_cmd meson "Install via 'brew install meson' (macOS) or your package manager (Linux: 'pip install meson')."
require_cmd ninja "Install via 'brew install ninja' (macOS) or your package manager (Linux: 'apt install ninja-build')."
require_cmd pkg-config "Install via 'brew install pkg-config' (macOS) or 'apt install pkg-config' (Linux)."
CXX="${CXX:-c++}"
require_cmd "$CXX" "Install a C++ toolchain (Xcode CLT on macOS, build-essential on Linux) and re-run."
[ -f "$SHIM" ] || die "shim source not found: $SHIM"

LIB="libaec_ffi.$NATIVE_EXT"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

log "Cloning $WAP_REPO @ $WAP_REF"
git_clone_pinned "$WAP_REPO" "$WAP_REF" "$WORK/wap"
SRC="$WORK/wap"

log "Configuring webrtc-audio-processing (static lib, AEC3, bundled static abseil)"
( cd "$SRC" && meson setup build \
    --buildtype=release \
    --default-library=static \
    --force-fallback-for=abseil-cpp >/dev/null )

# Build all static archives. The 'examples/run-offline' target's link fails on
# macOS (upstream omits CoreFoundation/Foundation from its link line); that is
# the LAST target and every archive we need is already built by then, so the
# failure is expected and ignored.
log "Building static archives (the example target's link is expected to fail on macOS — ignored)"
( cd "$SRC" && ninja -C build || true )

MAIN_AR="$SRC/build/webrtc/modules/audio_processing/libwebrtc-audio-processing-2.a"
[ -f "$MAIN_AR" ] || die "APM static archive not built: $MAIN_AR (check the meson/ninja output above)"

ABSEIL_INC="$(find "$SRC/subprojects" -maxdepth 1 -type d -name 'abseil-cpp-*' | head -1)"
[ -n "$ABSEIL_INC" ] || die "abseil subproject not unpacked under $SRC/subprojects (force-fallback failed?)"

# Per-OS WebRTC platform define for the shim.
if [ "$NATIVE_OS" = "Darwin" ]; then
  OS_DEFINE="-DWEBRTC_MAC"
else
  OS_DEFINE="-DWEBRTC_LINUX"
fi

log "Compiling shim ($SHIM) for $NATIVE_OS"
"$CXX" -std=c++17 -O2 -fPIC \
  -DWEBRTC_POSIX "$OS_DEFINE" -DWEBRTC_APM_DEBUG_DUMP=0 \
  -Wno-nullability-completeness \
  -I "$SRC/webrtc" -I "$ABSEIL_INC" \
  -c "$SHIM" -o "$WORK/aec_ffi.o"

# Whole-archive the main APM archive so every AEC3 object is present (some are
# only reached via internal wiring); normal-load the deps + static abseil (only
# referenced objects pulled).
OTHER_ARCHIVES=()
while IFS= read -r a; do
  [ "$a" = "$MAIN_AR" ] || OTHER_ARCHIVES+=("$a")
done < <(find "$SRC/build" -name '*.a')

if [ "$NATIVE_OS" = "Darwin" ]; then
  log "Linking $LIB (force_load APM + $((${#OTHER_ARCHIVES[@]})) dep/abseil archives + CoreFoundation/Foundation)"
  "$CXX" -dynamiclib -o "$WORK/$LIB" "$WORK/aec_ffi.o" \
    -Wl,-force_load,"$MAIN_AR" \
    "${OTHER_ARCHIVES[@]}" \
    -framework CoreFoundation -framework Foundation \
    -install_name "@rpath/$LIB"
else
  # GNU ld: --whole-archive is the force_load equivalent and is order-sensitive,
  # so the deps follow inside the no-whole-archive section. -soname sets the
  # embedded name; pthread/m are the only system deps AEC3 needs on Linux.
  log "Linking $LIB (--whole-archive APM + $((${#OTHER_ARCHIVES[@]})) dep/abseil archives)"
  "$CXX" -shared -o "$WORK/$LIB" "$WORK/aec_ffi.o" \
    -Wl,--whole-archive "$MAIN_AR" -Wl,--no-whole-archive \
    "${OTHER_ARCHIVES[@]}" \
    -Wl,-soname,"$LIB" \
    -lpthread -lm
fi

# Sanity: confirm our C symbols are exported and there are no system-abseil
# runtime deps (must be self-contained).
if [ "$NATIVE_OS" = "Darwin" ]; then
  if ! nm -gU "$WORK/$LIB" | grep -q "_aec_create"; then
    die "built $LIB is missing the aec_create symbol"
  fi
  if otool -L "$WORK/$LIB" | grep -qi "Cellar/abseil\|/abseil"; then
    warn "WARNING: $LIB links a non-bundled abseil — not self-contained:"
    otool -L "$WORK/$LIB" | grep -i abseil >&2 || true
  fi
else
  if ! nm -D "$WORK/$LIB" | grep -q " aec_create"; then
    die "built $LIB is missing the aec_create symbol"
  fi
  if ldd "$WORK/$LIB" 2>/dev/null | grep -qi "abseil"; then
    warn "WARNING: $LIB links a system abseil — not self-contained:"
    ldd "$WORK/$LIB" | grep -i abseil >&2 || true
  fi
fi

# Install to: the app-support root (the single dev / runtime location) and the
# optional explicit DEST (CI staging — the macOS release packaging copies it
# from there into the app bundle). No repo-local macos/Frameworks copy.
dests=("$(native_support_root)")
[ -n "$DEST" ] && dests+=("$DEST")

for d in "${dests[@]}"; do
  mkdir -p "$d"
  cp -f "$WORK/$LIB" "$d/$LIB"
  native_adhoc_sign "$d/$LIB"
  echo "  - $d/$LIB"
done

log "Done. Installed $LIB ($(du -h "$WORK/$LIB" | cut -f1)) to ${#dests[@]} location(s)."
