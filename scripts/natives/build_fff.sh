#!/usr/bin/env bash
#
# Builds the fff (Fast File Finder) Rust library and its C ABI wrapper
# (libfff_c), then installs it beside control_center.db so FffFileSearch loads
# it at runtime (see FffFileSearch._openLib() — its first candidate is
# <app-support root>/libfff_c.<ext>, same dir as the grammars/ folder).
#
# Dev/dogfood tooling: the dylib is REQUIRED (FffFileSearch throws
# FffUnavailable when it cannot load — no pure-Dart degrade). A release bundles
# the dylib into the desktop bundle (macOS Contents/Frameworks/, Linux
# bundle/lib/, Windows beside control_center.exe) and into the cc_server bundle
# via apps/cc_server/hook/build.dart — see scripts/release/*_package.sh and,
# for Windows, scripts/release/windows_natives.sh.
#
# Source/refs (override to iterate or bump; keep FFF_REF in sync with CI):
#   FFF_REPO  default github.com/dmtrKovalenko/fff
#   FFF_REF   default v0.9.3 (Renovate-managed)
#
# Requirements: git, a Rust toolchain (cargo).
#
# Usage:
#   scripts/natives/build_fff.sh [DEST_DIR]   # DEST defaults to the app-support root
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

# Pins come from scripts/lib/native_pins.env (the only place a SHA lives; an
# env override still wins, for one-off bisects).
load_native_pins

native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."

LIB="libfff_c.$NATIVE_EXT"
# Explicit DEST wins (CI staging); otherwise install next to control_center.db.
DEST="${1:-$(native_support_root)}"
log "Installing $LIB into: $DEST"
mkdir -p "$DEST"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
log "Cloning $FFF_REPO @ $FFF_REF"
git_clone_pinned "$FFF_REPO" "$FFF_REF" "$WORK/fff"

log "Building crates/fff-c (release)"
( cd "$WORK/fff/crates/fff-c" && cargo build --release )

BUILT="$WORK/fff/target/release/$LIB"
[ -f "$BUILT" ] || die "expected artifact not found: $BUILT (see cargo output above)"

cp -f "$BUILT" "$DEST/$LIB"
native_adhoc_sign "$DEST/$LIB"

log "Done. Installed:"
ls -la "$DEST/$LIB"
echo "Restart Control Center — FffFileSearch will load fff from $DEST/$LIB."
