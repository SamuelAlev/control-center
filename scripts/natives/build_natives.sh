#!/usr/bin/env bash
#
# Builds all bundled native FFI libraries (rift + fff + tree-sitter + grammars +
# aec) into a single staging directory by invoking the per-library build scripts.
#
# Used by the macOS and Linux release jobs (see .github/workflows/release.yml)
# and handy locally to populate everything at once. Best-effort: each library
# is independent and the app degrades gracefully if one is missing, so a single
# failure is reported as a warning and never aborts the run (exit 0 always).
#
# Usage:
#   scripts/natives/build_natives.sh [DEST_DIR]   # DEST defaults to <repo>/build/natives
set -uo pipefail

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

bash "$SCRIPT_DIR/build_rift.sh" "$DEST" \
  || echo "::warning::rift build failed — CoW worktrees degrade to git worktree"
bash "$SCRIPT_DIR/build_fff.sh" "$DEST" \
  || echo "::warning::fff build failed — file search degrades to Dart"
bash "$SCRIPT_DIR/build_tree_sitter.sh" "$DEST" \
  || echo "::warning::tree-sitter build failed — code graph unavailable"
bash "$SCRIPT_DIR/build_aec.sh" "$DEST" \
  || echo "::warning::AEC build failed — meeting mic echo cancellation degrades to the text filter"
bash "$SCRIPT_DIR/build_pty.sh" "$DEST" \
  || echo "::warning::PTY build failed — the headless cc_server agent executor (claude-relay / terminal) is unavailable"

echo "==> Staged native libraries:"
ls -la "$DEST" || true
exit 0
