#!/usr/bin/env bash
#
# Builds libcc_saml — the SAML 2.0 service-provider crypto native — and
# installs it where the Dart FFI bindings look for it (the app-support root,
# plus an optional explicit DEST for CI staging / bundle embedding).
#
# FIRST-PARTY SOURCE, in-repo (packages/cc_natives/native/saml/), cargo-
# built. The crate is a thin, stateless C-ABI seam over the pinned pure-Rust
# `saml` crate (quick-xml + RustCrypto): NO libxml2 / xmlsec1 / openssl C
# toolchain, no bindgen, no libclang — a plain `cargo build` on every
# platform including Windows MSVC.
#
# REQUIRED native, no fallback: SAML SSO login refuses to start and the boot
# preflight names this library when it is missing. There is deliberately no
# pure-Dart degraded path — hand-rolling XML-DSig/canonicalization is where
# SAML signature-wrapping vulnerabilities live.
#
# Requirements: a Rust toolchain (cargo).
#
# Usage:
#   scripts/natives/build_saml.sh [DEST_DIR]
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

DEST="${1:-}"
CRATE_DIR="$REPO_ROOT/packages/cc_natives/native/saml"

case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_saml.sh does not support $(uname -s). Windows natives are built by scripts/release/windows_natives.sh." ;;
esac
native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."
[ -f "$CRATE_DIR/Cargo.toml" ] || die "saml crate not found: $CRATE_DIR"

LIB="libcc_saml.$NATIVE_EXT"
# NOT the crate-local `target/`: the repo-root build/ dir is gitignored and
# excluded from analysis; a stray crate-local target tree would be neither.
export CARGO_TARGET_DIR="$REPO_ROOT/build/cargo/saml"

log "Building cc_saml (cargo, release) for $NATIVE_OS"
cargo build --release --locked --manifest-path "$CRATE_DIR/Cargo.toml"

BUILT="$CARGO_TARGET_DIR/release/$LIB"
[ -f "$BUILT" ] || die "cargo build succeeded but $BUILT is missing"

# Sanity: confirm the exported saml ABI is present.
if [ "$NATIVE_OS" = "Darwin" ]; then
  for sym in _cc_saml_abi_version _cc_saml_last_error _cc_saml_free_string _cc_saml_parse_idp_metadata _cc_saml_build_authn_request _cc_saml_verify_response _cc_saml_sp_metadata; do
    nm -gU "$BUILT" | grep -q "$sym" || die "built $LIB is missing the ${sym#_} symbol"
  done
else
  for sym in cc_saml_abi_version cc_saml_last_error cc_saml_free_string cc_saml_parse_idp_metadata cc_saml_build_authn_request cc_saml_verify_response cc_saml_sp_metadata; do
    nm -D "$BUILT" | grep -q " $sym" || die "built $LIB is missing the $sym symbol"
  done
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
