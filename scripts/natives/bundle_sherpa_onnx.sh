#!/usr/bin/env bash
#
# Copies the PREBUILT sherpa-onnx + onnxruntime dynamic libraries out of the
# resolved `sherpa_onnx_{macos,linux,windows}` pub package into a staging dir,
# so a STANDALONE `cc_server` (one no Flutter app spawns) can load the speech
# recognizer.
#
# Unlike the other natives, sherpa/onnx are NOT built from source here — the
# plugin packages ship prebuilt libs. A Flutter app bundles them into its
# Frameworks automatically; a `dart build cli` cc_server does not, so a remote /
# headless / containerised server must carry them itself. Drop the output where
# `resolveSherpaLibraryDir` looks (cc_natives/sherpa_bindings.dart):
#   * beside the binary  — macOS `<bundle>/Frameworks`, Linux `<bundle>/lib`,
#     Windows next to the .exe  (a self-contained server), OR
#   * in the server's --data-dir  (next to the models it already hosts), OR
#   * any dir, then point CC_NATIVE_LIB_DIR at it.
#
# The c-api dylib finds its onnxruntime sibling via its own @loader_path/rpath,
# so both MUST land in the SAME directory.
#
# Usage:
#   scripts/natives/bundle_sherpa_onnx.sh [DEST_DIR]   # DEST defaults to <repo>/build/natives
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
DEST="${1:-$REPO_ROOT/build/natives}"
mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"

case "$(uname -s)" in
  Darwin)  PKG=sherpa_onnx_macos;   SUBDIR=macos;   GLOB='libsherpa-onnx-c-api.dylib libonnxruntime*.dylib' ;;
  Linux)   PKG=sherpa_onnx_linux;   SUBDIR=linux;   GLOB='libsherpa-onnx-c-api.so libonnxruntime.so*' ;;
  *)       PKG=sherpa_onnx_windows; SUBDIR=windows; GLOB='sherpa-onnx-c-api.dll onnxruntime*.dll' ;;
esac

# Resolve the plugin package's root from the authoritative package_config.json
# (the EXACT version pub resolved), falling back to the newest in the pub cache.
PKG_ROOT="$(python3 - "$REPO_ROOT/.dart_tool/package_config.json" "$PKG" <<'PY' 2>/dev/null || true
import json, sys, urllib.parse, urllib.request
cfg, name = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(cfg))
except Exception:
    sys.exit(0)
for p in data.get("packages", []):
    if p.get("name") == name:
        root = urllib.parse.urlparse(p["rootUri"]).path
        print(urllib.request.url2pathname(root))
        break
PY
)"
if [ -z "${PKG_ROOT:-}" ] || [ ! -d "$PKG_ROOT" ]; then
  PKG_ROOT="$(find "${PUB_CACHE:-$HOME/.pub-cache}/hosted" -maxdepth 2 -type d -name "$PKG-*" 2>/dev/null | sort -V | tail -1)"
fi
if [ -z "${PKG_ROOT:-}" ] || [ ! -d "$PKG_ROOT/$SUBDIR" ]; then
  echo "::warning::could not locate $PKG in the pub cache — run 'dart pub get' first; meeting transcription will be unavailable on a server that uses this bundle"
  exit 0
fi

echo "==> Staging sherpa-onnx + onnxruntime from $PKG_ROOT/$SUBDIR into: $DEST"
copied=0
for g in $GLOB; do
  for f in "$PKG_ROOT/$SUBDIR"/$g; do
    [ -e "$f" ] || continue
    cp -f "$f" "$DEST/" && copied=$((copied + 1))
  done
done

if [ "$copied" -eq 0 ]; then
  echo "::warning::no sherpa/onnx libraries matched in $PKG_ROOT/$SUBDIR"
fi

# ── Also stage the EMBEDDER's onnxruntime (the `onnxruntime_v2` plugin) ──
# Semantic memory / code / conversation search uses `onnxruntime_v2`, which
# ships its OWN prebuilt onnxruntime — a DIFFERENT version than sherpa's, with a
# distinct filename, so the two coexist in the same dir. A Flutter app gets it
# via CocoaPods; a `dart build cli` cc_server does not. onnxruntime_v2 opens it
# by a BARE leaf name, which a hardened server rejects, so the server pre-loads
# it by full path from this dir (see cc_natives `ensureOnnxRuntimeLoaded`).
# Without this, embeddings silently degrade to keyword on a standalone server.
case "$(uname -s)" in
  Darwin)  OV2_SUB=macos;   OV2_GLOB='libonnxruntime*.dylib' ;;
  Linux)   OV2_SUB=linux;   OV2_GLOB='libonnxruntime.so*' ;;
  *)       OV2_SUB=windows; OV2_GLOB='onnxruntime*.dll' ;;
esac
OV2_ROOT="$(python3 - "$REPO_ROOT/.dart_tool/package_config.json" onnxruntime_v2 <<'PY' 2>/dev/null || true
import json, os, sys, urllib.parse, urllib.request
cfg, name = sys.argv[1], sys.argv[2]
base = os.path.dirname(os.path.abspath(cfg))  # the .dart_tool dir
try:
    data = json.load(open(cfg))
except Exception:
    sys.exit(0)
for p in data.get("packages", []):
    if p.get("name") == name:
        uri = p["rootUri"]
        if uri.startswith("file:"):
            path = urllib.request.url2pathname(urllib.parse.urlparse(uri).path)
        else:
            # A path-override (e.g. the patchwork) is relative to the
            # package_config.json directory, not cwd.
            path = os.path.normpath(os.path.join(base, urllib.request.url2pathname(uri)))
        print(path)
        break
PY
)"
if [ -n "${OV2_ROOT:-}" ] && [ -d "$OV2_ROOT/$OV2_SUB" ]; then
  echo "==> Staging embedder onnxruntime from $OV2_ROOT/$OV2_SUB into: $DEST"
  for f in "$OV2_ROOT/$OV2_SUB"/$OV2_GLOB; do
    [ -e "$f" ] || continue
    cp -f "$f" "$DEST/" && copied=$((copied + 1))
  done
else
  echo "::warning::could not locate onnxruntime_v2 in the pub cache — semantic embeddings will be unavailable on a server that uses this bundle"
fi

if [ "$copied" -eq 0 ]; then
  exit 0
fi
echo "==> Staged $copied sherpa/onnx + embedder onnxruntime libraries:"
ls -la "$DEST"/*sherpa* "$DEST"/*onnxruntime* 2>/dev/null || true
exit 0
