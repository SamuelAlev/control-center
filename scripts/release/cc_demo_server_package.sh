#!/usr/bin/env bash
#
# Packages the standalone PUBLIC DEMO server (`cc_demo_server`) into a
# downloadable Linux archive — the same shape `cc_server_package.sh` produces,
# and the archive that feeds the `cc-server-demo` container image.
#
# LINUX ONLY, deliberately. The demo exists to be hosted: it ships as a
# container and nothing else. Skipping macOS means skipping the Developer-ID
# signing + notarization half of `cc_server_package.sh`, which is most of that
# script and none of what a demo needs — so this is a small script rather than
# a second set of flags on a battle-tested one.
#
# It reuses the SAME native matrix and the SAME verifier as the production
# packager (scripts/lib/natives.sh via verify_natives.sh), because the demo
# binary boots through the identical preflight: every native is required, and
# an archive that cannot start is worse than no archive.
#
# Note the demo needs those natives even though it executes nothing — the boot
# preflight probes them all regardless, and adding a demo carve-out would be a
# second boot path whose failure mode is "boots degraded". That is exactly what
# the preflight exists to prevent.
#
# Usage:
#   scripts/release/cc_demo_server_package.sh <version>
#
# Environment:
#   NATIVES   staged-natives dir (default build/natives)
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

# 3b. Drop the second copy of every native. The bundle carries each one TWICE:
# the build hook emits them as DynamicLoadingBundled code assets into
# `<bundle>/lib/`, and step 2 stages them into `bin/lib/`. Both are searched
# (`bundledLibraryCandidates` tries `<exeDir>/../lib` then `<exeDir>/lib`), so
# the second copy is pure weight — 49 MB of a 316 MB image, measured.
#
# The STAGED copy is the one kept: it is the directory `CC_NATIVE_LIB_DIR`
# names, the one the `.scm` queries sit beside, and the fallback every
# env-var-driven resolver (inference, pty, watcher, saml) lands on anyway. So
# deleting from `lib/` leaves every runtime lookup exactly where it already
# resolved. Byte-identical is the condition, which keeps the staging's original
# purpose intact: it is a safety net for a bundle built BEFORE the natives were
# staged, and in that case `lib/` holds nothing to match and nothing is removed.
# Nothing resolves these by ASSET ID (the hook says so, and no `@Native` in
# cc_natives does), which is what makes `lib/` the removable copy rather than
# the load-bearing one — unlike libsqlite3, which stays.
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
