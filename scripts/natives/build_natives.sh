#!/usr/bin/env bash
#
# Builds every REQUIRED native for this host into build/natives/ (or DEST).
# Aborts on first failure. Windows: use windows_natives.sh instead.
# Usage: scripts/natives/build_natives.sh [DEST_DIR]
#
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
