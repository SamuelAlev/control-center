#!/usr/bin/env bash
#
# Builds libaec_ffi — a thin C ABI (packages/cc_natives/native/aec_ffi.cc) over WebRTC's AEC3
# AudioProcessing module — and installs it where AecFfiBindings looks for it
# (see core/storage/control_center_paths.dart -> aecFfiDylibCandidatePaths):
#   1. the app-support root (next to control_center.db) — the single dev /
#      runtime location, and
#   2. an optional explicit DEST ($1) — CI stages the lib there before embedding
#      it into Runner.app/Contents/Frameworks/.
#
# The meeting recorder feeds the system loopback as the AEC far-end reference and
# subtracts it from the mic before transcription, killing the speaker bleed that
# Whisper otherwise transcribes as a duplicate "me" line. The app degrades
# gracefully to the text-based MeetingEchoFilter when this lib is absent
# (AecProcessor.tryCreate -> null), so a failed/missing build is never fatal.
#
# abseil is statically linked from the meson wrap (NOT the system/Homebrew
# shared abseil) so the dylib is self-contained and embeddable in the app bundle.
#
# macOS-first: this script targets macOS (arm64/x86_64). Windows/Linux are TODO
# (the app simply runs without AEC there). Skipped (exit 0) off macOS so
# build_natives.sh stays best-effort.
#
# Source/ref (override to iterate or bump; keep WAP_REF in sync with CI):
#   WAP_REPO  default gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing
#   WAP_REF   default d0569cfa... (v2.1; Renovate-managed)
#
# Requirements: git, meson, ninja, pkg-config, a C++ compiler (c++).
#
# Usage:
#   scripts/natives/build_aec.sh [DEST_DIR]
#   WAP_REF=<sha> scripts/natives/build_aec.sh ./build/natives
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

WAP_REPO="${WAP_REPO:-https://gitlab.freedesktop.org/pulseaudio/webrtc-audio-processing.git}"
WAP_REF="${WAP_REF:-d0569cfa50c1858ee279d77b3fc8870be6902441}" # v2.1 (Renovate-managed)
DEST="${1:-}"
SHIM="$REPO_ROOT/packages/cc_natives/native/aec_ffi.cc"

native_detect_platform
if [ "$NATIVE_OS" != "Darwin" ]; then
  warn "build_aec.sh: only macOS is supported for now (got $NATIVE_OS) — the app runs without AEC and uses the text MeetingEchoFilter."
  exit 0
fi
require_cmd meson "Install via 'brew install meson'."
require_cmd ninja "Install via 'brew install ninja'."
require_cmd pkg-config "Install via 'brew install pkg-config'."
CXX="${CXX:-c++}"
require_cmd "$CXX" "Install Xcode Command Line Tools and re-run."
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

log "Compiling shim ($SHIM)"
"$CXX" -std=c++17 -O2 -fPIC \
  -DWEBRTC_POSIX -DWEBRTC_MAC -DWEBRTC_APM_DEBUG_DUMP=0 \
  -Wno-nullability-completeness \
  -I "$SRC/webrtc" -I "$ABSEIL_INC" \
  -c "$SHIM" -o "$WORK/aec_ffi.o"

# ld64 resolves static archives together (order-independent). force_load the main
# APM archive so every AEC3 object is present (some are only reached via internal
# wiring); normal-load the deps + static abseil (only referenced objects pulled).
OTHER_ARCHIVES=()
while IFS= read -r a; do
  [ "$a" = "$MAIN_AR" ] || OTHER_ARCHIVES+=("$a")
done < <(find "$SRC/build" -name '*.a')

log "Linking $LIB (force_load APM + $((${#OTHER_ARCHIVES[@]})) dep/abseil archives + CoreFoundation/Foundation)"
"$CXX" -dynamiclib -o "$WORK/$LIB" "$WORK/aec_ffi.o" \
  -Wl,-force_load,"$MAIN_AR" \
  "${OTHER_ARCHIVES[@]}" \
  -framework CoreFoundation -framework Foundation \
  -install_name "@rpath/$LIB"

# Sanity: confirm our C symbols are exported and there are no Homebrew-abseil
# runtime deps (must be self-contained).
if ! nm -gU "$WORK/$LIB" | grep -q "_aec_create"; then
  die "built $LIB is missing the aec_create symbol"
fi
if otool -L "$WORK/$LIB" | grep -qi "Cellar/abseil\|/abseil"; then
  warn "WARNING: $LIB links a non-bundled abseil — not self-contained:"
  otool -L "$WORK/$LIB" | grep -i abseil >&2 || true
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
