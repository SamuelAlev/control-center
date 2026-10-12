#!/usr/bin/env bash
#
# Builds librhttp (rhttp's Rust HTTP engine; REQUIRED). Cargo, from the pub
# archive pinned by version + checksum in scripts/lib/native_pins.env.
# Usage: scripts/natives/build_rhttp.sh [DEST_DIR]
#
# rhttp is consumed as a pure-Dart pub dependency — patches/rhttp@0.18.0.patch
# drops its Flutter plugin registration and its last `package:flutter` import —
# so its native is built HERE, beside every other runtime-loaded library,
# instead of by cargokit inside `flutter build`.
#
# The crate is taken from the PUBLISHED ARCHIVE rather than a checkout of the
# upstream repo: pub.dev's artifact is the source pub itself verifies against
# pubspec.lock and the exact revision the Dart bindings were generated from, and
# it carries the `rust/Cargo.lock` that --locked needs. It is checksum-verified
# before anything is compiled, like the LAME and sherpa-onnx archives.
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

# Pins (RHTTP_URL / RHTTP_SHA256) come from scripts/lib/native_pins.env. An env
# override still wins, for one-off bisects.
load_native_pins

native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."

# Not the crate-local `target/`: the repo-root build/ dir is gitignored and
# excluded from analysis; a stray crate-local target tree would be neither.
export CARGO_TARGET_DIR="$REPO_ROOT/build/cargo/rhttp"

DEST="${1:-}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

SRC="$WORK/rhttp-$RHTTP_VERSION"
mkdir -p "$SRC"
fetch_pinned "${RHTTP_URL:?RHTTP_URL unset}" "${RHTTP_SHA256:?RHTTP_SHA256 unset}" \
  "$WORK/rhttp.tar.gz"
# The archive holds the package contents at its root (pubspec.yaml + rust/), not
# under a wrapper directory.
tar xz -C "$SRC" <"$WORK/rhttp.tar.gz"
[ -f "$SRC/rust/Cargo.toml" ] \
  || die "the pinned rhttp archive carries no rust/Cargo.toml — is $RHTTP_URL the package archive?"

log "Building rhttp $RHTTP_VERSION (cargo, release, locked) for $NATIVE_OS"
# `--cfg reqwest_unstable` is the flag rhttp's own Flutter build sets: reqwest's
# http3 surface is cfg-gated on it and the shipped codegen was generated with it
# (see the crate's CONTRIBUTE.md). Any RUSTFLAGS the caller set are preserved.
RUSTFLAGS="${RUSTFLAGS:-} --cfg reqwest_unstable" \
  cargo build --release --locked --manifest-path "$SRC/rust/Cargo.toml"

LIB="librhttp.$NATIVE_EXT"
BUILT="$CARGO_TARGET_DIR/release/$LIB"
[ -f "$BUILT" ] || die "cargo build succeeded but $BUILT is missing"

# Sanity: flutter_rust_bridge's entry point must be exported. A cdylib that lost
# its exports still links and still loads — the failure would only appear as a
# lookupFunction miss on the first HTTP request.
assert_exports "$BUILT" frb_get_rust_content_hash

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
