#!/usr/bin/env bash
#
# Builds libcc_watcher — the native recursive file watcher (FSEvents on macOS,
# ReadDirectoryChangesW on Windows, ignore-aware inotify on Linux) — and
# installs it where NativeDirectoryWatcher looks for it (the app-support root
# next to control_center.db, plus an optional explicit DEST for CI staging /
# bundle embedding).
#
# FIRST-PARTY SOURCE, in-repo (packages/cc_natives/native/watcher/), cargo-
# built — unlike rift/fff there is no upstream clone; the crate wraps the
# `notify` crate's per-OS backends behind the C ABI in cc_watcher.h.
#
# Why it exists: `package:watcher`'s DirectoryWatcher performs a full
# recursive scan of the tree on construction and cannot skip node_modules/
# build — arming a realistic worktree fleet froze the server isolate for a
# measured 65 seconds. The native watches kernel-recursively (or installs its
# Linux per-dir watches on its own thread) so arming is O(1) for the caller.
#
# REQUIRED native, no fallback: `NativeDirectoryWatcher.create` throws and
# cc_server's boot preflight refuses to start without it. `package:watcher`
# was deliberately NOT kept as a degraded path — its per-arm full-tree scan is
# the 65s freeze this native exists to remove. build_natives.sh therefore aborts
# on a failure here rather than warning past it.
#
# Requirements: a Rust toolchain (cargo).
#
# Usage:
#   scripts/natives/build_watcher.sh [DEST_DIR]
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$REPO_ROOT/scripts/natives/lib/natives_common.sh"

DEST="${1:-}"
CRATE_DIR="$REPO_ROOT/packages/cc_natives/native/watcher"

case "$(uname -s)" in
  Darwin | Linux) ;;
  *)
    die "build_watcher.sh does not support $(uname -s). Windows natives are built by scripts/release/windows_natives.sh." ;;
esac
native_detect_platform
require_cmd cargo "Install Rust via https://rustup.rs/ and re-run."
[ -f "$CRATE_DIR/Cargo.toml" ] || die "watcher crate not found: $CRATE_DIR"

LIB="libcc_watcher.$NATIVE_EXT"
# NOT the crate-local `target/`: the repo-root build/ dir is gitignored and
# excluded from analysis; a stray crate-local target tree would be neither.
export CARGO_TARGET_DIR="$REPO_ROOT/build/cargo/watcher"

log "Building cc_watcher (cargo, release) for $NATIVE_OS"
cargo build --release --locked --manifest-path "$CRATE_DIR/Cargo.toml"

BUILT="$CARGO_TARGET_DIR/release/$LIB"
[ -f "$BUILT" ] || die "cargo build succeeded but $BUILT is missing"

# Sanity: confirm the exported watcher ABI is present.
if [ "$NATIVE_OS" = "Darwin" ]; then
  for sym in _cc_watch_abi_version _cc_watch_create _cc_watch_drain _cc_watch_destroy _cc_watch_last_error; do
    nm -gU "$BUILT" | grep -q "$sym" || die "built $LIB is missing the ${sym#_} symbol"
  done
else
  for sym in cc_watch_abi_version cc_watch_create cc_watch_drain cc_watch_destroy cc_watch_last_error; do
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
