#!/usr/bin/env bash
#
# Builds libcc_inference — Control Center's on-device inference native — and
# installs it where the loader looks for it (the app-support root next to
# control_center.db, plus an optional explicit DEST for CI staging / bundle
# embedding).
#
# FIRST-PARTY SOURCE, in-repo (packages/cc_natives/native/inference/), cargo-
# built. The crate wraps TWO workloads behind the C ABI in cc_inference.h:
#   * speech — offline ASR (Whisper + transducer), Silero VAD, pyannote
#     diarization, WeSpeaker voiceprints, via sherpa-onnx's C API;
#   * text  — BERT sentence embeddings, via the ONNX Runtime C API.
#
# Both are STATICALLY LINKED, against ONE ONNX Runtime, producing one
# self-contained library: no loader-path search, no version skew between the
# generated headers and the runtime they call and no way for two runtimes to
# collide by base name in one process (how Windows resolves a DLL dependency).
#
# The prebuilt sherpa-onnx static archive is PRE-FETCHED here and pinned by
# sha256 in scripts/lib/native_pins.env, then handed to the crate's build script
# via SHERPA_ONNX_LIB_DIR. Left to itself that build script downloads an
# unverified archive from GitHub at build time; pre-fetching keeps the build
# reproducible, offline-capable after the first run and auditable.
#
# REQUIRED native, no fallback: semantic search and the entire speech stack are
# unavailable without it and cc_server's boot preflight refuses to start.
# build_natives.sh therefore aborts on a failure here rather than warning past
# it.
#
# Requirements: a Rust toolchain (cargo), curl, tar (with bzip2).
#
# Usage:
#   scripts/natives/build_inference.sh [DEST_DIR]
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

DEST="${1:-}"
CRATE_DIR="$REPO_ROOT/packages/cc_natives/native/inference"

case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_inference.sh does not support $(uname -s). Windows natives are built by scripts/release/windows_natives.sh." ;;
esac
native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."
require_cmd curl "Install curl and re-run."
[ -f "$CRATE_DIR/Cargo.toml" ] || die "inference crate not found: $CRATE_DIR"

load_native_pins
: "${SHERPA_ONNX_VERSION:?SHERPA_ONNX_VERSION missing from scripts/lib/native_pins.env}"

# ── Resolve the prebuilt static archive for this host ────────────────────────
# Names match the crate build script's own `archive_name()`, so the directory we
# hand it via SHERPA_ONNX_LIB_DIR is exactly what it would have downloaded.
case "$NATIVE_OS/$(uname -m)" in
  Darwin/arm64)  SHERPA_SLUG="osx-arm64"    ; SHERPA_SHA="${SHERPA_ONNX_LIB_SHA256_MACOS_ARM64:-}" ;;
  Darwin/x86_64) SHERPA_SLUG="osx-x64"      ; SHERPA_SHA="${SHERPA_ONNX_LIB_SHA256_MACOS_X64:-}" ;;
  Linux/x86_64)  SHERPA_SLUG="linux-x64"    ; SHERPA_SHA="${SHERPA_ONNX_LIB_SHA256_LINUX_X64:-}" ;;
  Linux/aarch64) SHERPA_SLUG="linux-aarch64"; SHERPA_SHA="${SHERPA_ONNX_LIB_SHA256_LINUX_ARM64:-}" ;;
  *) die "no pinned sherpa-onnx static archive for $NATIVE_OS/$(uname -m)" ;;
esac

ARCHIVE="sherpa-onnx-v${SHERPA_ONNX_VERSION}-${SHERPA_SLUG}-static-lib.tar.bz2"
URL="https://github.com/k2-fsa/sherpa-onnx/releases/download/v${SHERPA_ONNX_VERSION}/${ARCHIVE}"
CACHE="$REPO_ROOT/build/cache/sherpa-onnx"
LIB_DIR="$CACHE/sherpa-onnx-v${SHERPA_ONNX_VERSION}-${SHERPA_SLUG}-static-lib/lib"

if [ ! -d "$LIB_DIR" ]; then
  mkdir -p "$CACHE"
  tarball="$CACHE/$ARCHIVE"
  if [ ! -f "$tarball" ]; then
    log "Fetching $ARCHIVE"
    curl -fSL "$URL" -o "$tarball.part"
    mv "$tarball.part" "$tarball"
  fi
  if [ -n "$SHERPA_SHA" ]; then
    got="$(sha256_of "$tarball")"
    [ "$got" = "$SHERPA_SHA" ] || die "sherpa-onnx archive sha256 mismatch for $ARCHIVE: got $got, expected $SHERPA_SHA. Refusing to link an unverified binary; if you bumped SHERPA_ONNX_VERSION, update the checksums in scripts/lib/native_pins.env together."
  else
    # A platform we have no checksum for yet. Loud, because linking an
    # unverified third-party binary into a shipped artifact is not a default.
    log "WARNING: no pinned sha256 for $SHERPA_SLUG — add SHERPA_ONNX_LIB_SHA256_* to scripts/lib/native_pins.env (got $(sha256_of "$tarball"))"
  fi
  log "Extracting $ARCHIVE"
  tar xjf "$tarball" -C "$CACHE"
fi
[ -d "$LIB_DIR" ] || die "extracted archive has no lib/ dir: $LIB_DIR"
[ -f "$LIB_DIR/libonnxruntime.a" ] || die "archive is missing libonnxruntime.a — the embedder links the ONNX Runtime C API out of it"

# ── Build ───────────────────────────────────────────────────────────────────
LIB="libcc_inference.$NATIVE_EXT"
# NOT the crate-local `target/`: the repo-root build/ dir is gitignored and
# excluded from analysis; a stray crate-local target tree would be neither.
export CARGO_TARGET_DIR="$REPO_ROOT/build/cargo/inference"
export SHERPA_ONNX_LIB_DIR="$LIB_DIR"

log "Building cc_inference (cargo, release, static sherpa-onnx ${SHERPA_ONNX_VERSION}) for $NATIVE_OS"
cargo build --release --locked --manifest-path "$CRATE_DIR/Cargo.toml"

BUILT="$CARGO_TARGET_DIR/release/$LIB"
[ -f "$BUILT" ] || die "cargo build succeeded but $BUILT is missing"

# ── Verify the exported surface ─────────────────────────────────────────────
# Two assertions, both load-bearing:
#   1. the C ABI Dart binds against is actually present;
#   2. NOTHING from the statically linked dependencies leaks out. On Linux the
#      dynamic loader resolves symbols globally and first-loaded-wins, so an
#      exported `OrtGetApiBase`/`SherpaOnnx*` could interpose on — or be
#      interposed by — another ONNX Runtime in the same process. The export
#      restriction in build.rs is pinned here rather than trusted.
if [ "$NATIVE_OS" = "Darwin" ]; then
  exported() { nm -gU "$BUILT" | awk '{print $3}'; }
  prefix="_"
else
  exported() { nm -D --defined-only "$BUILT" | awk '{print $3}'; }
  prefix=""
fi
for sym in cc_inference_abi_version cc_inference_last_error cc_string_destroy \
           cc_embedder_create cc_embedder_run cc_embedder_destroy \
           cc_asr_create_whisper cc_asr_create_transducer cc_asr_transcribe cc_asr_destroy \
           cc_vad_create cc_vad_accept cc_vad_front cc_vad_destroy \
           cc_diar_create cc_diar_process cc_diar_segments_destroy cc_diar_destroy \
           cc_spk_create cc_spk_dim cc_spk_compute cc_spk_destroy; do
  exported | grep -qx "${prefix}${sym}" || die "built $LIB is missing the $sym symbol"
done
if leaked="$(exported | grep -E "^${prefix}(OrtGetApiBase|SherpaOnnx)" || true)"; [ -n "$leaked" ]; then
  die "built $LIB leaks statically linked symbols (export restriction in build.rs regressed): $(echo "$leaked" | tr '\n' ' ')"
fi

# Install to the app-support root (the single dev / runtime location) + the
# optional explicit DEST (CI staging — release packaging copies it into the
# bundle).
dests=("$(native_support_root)")
[ -n "$DEST" ] && dests+=("$DEST")

for d in "${dests[@]}"; do
  mkdir -p "$d"
  cp -f "$BUILT" "$d/$LIB"
  native_adhoc_sign "$d/$LIB"
  echo "  - $d/$LIB"
done

log "Done. Installed $LIB ($(du -h "$BUILT" | cut -f1)) to ${#dests[@]} location(s)."
