#!/usr/bin/env bash
#
# Builds all bundled native FFI libraries (rift + fff + tree-sitter + grammars +
# aec + lame + pty + watcher + inference + saml) into a single staging directory
# by invoking the per-library build scripts.
#
# Used by the macOS and Linux release jobs (see .github/workflows/release.yml)
# and handy locally to populate everything at once.
#
# FAIL-HARD: every library here is REQUIRED. `cc_server`'s boot preflight refuses
# to start when one cannot be loaded and the packaging scripts refuse to produce
# an artifact without it, so there is no degraded mode left for a warning to
# describe — the first failure aborts the whole run.
#
# (`build_pty.sh` still exits 0 on a platform it does not handle; that is a
# platform SKIP, not a failure. Windows builds every native through
# scripts/release/windows_natives.sh instead, except rift — no MSVC
# copy-on-write backend exists, so `git worktree` is the backend there.)
#
# Usage:
#   scripts/natives/build_natives.sh [DEST_DIR]   # DEST defaults to <repo>/build/natives
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
# Default the staging dir to the repo-root build/natives (gitignored via
# `/build/`), NOT a cwd-relative `build/natives` — running this from anywhere
# but the repo root (e.g. apps/) would otherwise scatter ~16 MB of dylibs into
# a non-ignored `<cwd>/build/natives` that could get committed by accident.
DEST="${1:-$REPO_ROOT/build/natives}"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

echo "==> Building native libraries into: $DEST"

bash "$SCRIPT_DIR/build_rift.sh" "$DEST"
bash "$SCRIPT_DIR/build_fff.sh" "$DEST"
bash "$SCRIPT_DIR/build_tree_sitter.sh" "$DEST"
bash "$SCRIPT_DIR/build_aec.sh" "$DEST"
bash "$SCRIPT_DIR/build_lame.sh" "$DEST"
bash "$SCRIPT_DIR/build_pty.sh" "$DEST"
bash "$SCRIPT_DIR/build_watcher.sh" "$DEST"
# Speech + embeddings, statically linked against ONE onnxruntime.
bash "$SCRIPT_DIR/build_inference.sh" "$DEST"
# SAML SSO (pure-Rust; no C toolchain beyond cargo itself).
bash "$SCRIPT_DIR/build_saml.sh" "$DEST"

echo "==> Staged native libraries:"
ls -la "$DEST"
