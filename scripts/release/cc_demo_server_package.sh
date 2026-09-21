#!/usr/bin/env bash
#
# Packages standalone cc_demo_server as a Linux archive (demo is hosted-only;
# no macOS signing). Same native matrix/verify as cc_server_package — preflight
# requires every native even though the demo executes nothing.
# Usage: scripts/release/cc_demo_server_package.sh <version>
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:?usage: cc_demo_server_package.sh <version>}"

OS=linux
ARCH=x64
CLI_DIR=linux_x64
LIBEXT=so
# Matches `bundledLibraryCandidates` in
# packages/cc_natives/.../native_library.dart: on Linux the resolver looks in
# `<exeDir>/lib`, and sherpa-onnx finds its onnxruntime sibling by rpath, so
# both MUST land in that one directory.
STAGE_REL=bin/lib

NATIVES="${NATIVES:-build/natives}"
BUNDLE="apps/cc_demo_server/build/cli/$CLI_DIR/bundle"
NAME="cc_demo_server-${VERSION}-${OS}-${ARCH}"
DIST="dist/$NAME"

echo "==> Packaging standalone cc_demo_server: $NAME"

# 1. Ensure the `dart build cli` bundle exists. When build/natives is staged
# BEFORE this build, apps/cc_demo_server/hook/build.dart bundles every runtime
# native into `<bundle>/lib/` as a DynamicLoadingBundled code asset — the same
# way libsqlite3 travels.
if [ ! -e "$BUNDLE/bin/cc_demo_server" ]; then
  echo "==> Building cc_demo_server cli bundle"
  DART_BIN="$REPO_ROOT/.fvm/flutter_sdk/bin/dart"
  [ -x "$DART_BIN" ] || DART_BIN="$(command -v dart)"
  ( cd apps/cc_demo_server && "$DART_BIN" build cli )
fi
test -d "$BUNDLE" || { echo "ERROR: cc_demo_server bundle not found at $BUNDLE" >&2; exit 1; }

# 2. Copy the clean bundle, then stage natives into the resolver dir so the
# original `dart build cli` output stays pristine for any later reuse.
rm -rf "$DIST"
mkdir -p "$DIST"
cp -R "$BUNDLE/." "$DIST/"

STAGE="$DIST/$STAGE_REL"
mkdir -p "$STAGE"
echo "==> Staging natives into $STAGE_REL/"
shopt -s nullglob
copied=0
for f in "$NATIVES"/*."$LIBEXT"; do
  echo "  + $(basename "$f")"
  cp -f "$f" "$STAGE/"
  copied=$((copied + 1))
done
[ "$copied" -gt 0 ] || {
  echo "ERROR: no *.$LIBEXT natives in $NATIVES — run scripts/natives/build_natives.sh first (every native is boot-required)" >&2
  exit 1
}

# Tree-sitter `.scm` queries: ship the canonical files beside the grammar libs,
# exactly as the production packager does. GrammarManager prefers the on-disk
# copy, so a demo runs the same artifacts a dev tree does.
scm_copied=0
for q in "$REPO_ROOT"/scripts/natives/queries/*.scm; do
  echo "  + $(basename "$q")"
  cp -f "$q" "$STAGE/"
  scm_copied=$((scm_copied + 1))
done
[ "$scm_copied" -gt 0 ] || {
  echo "ERROR: no .scm queries in $REPO_ROOT/scripts/natives/queries" >&2
  exit 1
}

# 3. Verify what the boot preflight requires — one matrix, one matcher, shared
# with the production packager. The libraries may live in lib/ (bundled by the
# build hook) or in the staged dir, so both are searched.
bash scripts/release/verify_natives.sh --dir "$DIST/lib" --dir "$STAGE" "$OS" server

# Drop the duplicate natives in bundle lib/ (keep staged copy — CC_NATIVE_LIB_DIR,
# queries, env resolvers). Byte-identical only.
freed=0
for f in "$STAGE"/*."$LIBEXT"; do
  dup="$DIST/lib/$(basename "$f")"
  if [ -f "$dup" ] && cmp -s "$f" "$dup"; then
    freed=$((freed + $(wc -c < "$dup")))
    rm -f "$dup"
  fi
done
echo "==> Removed duplicate natives from lib/ ($((freed / 1048576)) MiB)"

# No vendored code-server: `codeServer.*` and `/proxy/vscode/*` are absent on a
# demo host (the runtime passes null ports), so shipping the editor would be
# ~100 MB of image for a surface nothing can reach.

# 4. Archive + checksum, same format as the production Linux archive.
mkdir -p dist
ARCHIVE="${NAME}.tar.gz"
rm -f "$ARCHIVE" "$ARCHIVE.sha256"
tar czf "$ARCHIVE" -C dist "$NAME"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"
else
  shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256"
fi

echo "==> Wrote $ARCHIVE"
cat "$ARCHIVE.sha256"
