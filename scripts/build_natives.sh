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
#   scripts/build_natives.sh [DEST_DIR]   # DEST defaults to build/natives
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-build/natives}"
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

echo "==> Staged native libraries:"
ls -la "$DEST" || true
exit 0
