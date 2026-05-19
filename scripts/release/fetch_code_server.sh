#!/usr/bin/env bash
#
# Fetches + extracts the PINNED code-server (coder/code-server) standalone
# archive (Node bundled; no source build) for the host platform into
# build/code-server/<platform>/ — the managed install dir CodeServerService
# resolves before PATH.
#
# Same pin-a-git-ref-in-CI convention cc_natives uses: the version is pinned in
# packages/cc_infra/lib/src/ide/code_server_service.dart (codeServerVersion)
# and here. Keep the two in sync (Renovate-tracked). Bump both together.
#
# code-server ships NO native Windows host, so this script is a no-op (with a
# warning) on Windows — the Windows-local story is WSL/remote-only (see the
# plan's Risks).
#
# Output layout — this is what cc_server_package.sh reads when it stages the
# archive into the bundle's data layout so a bundled server is offline-first:
#   build/code-server/<platform>/bin/code-server           (the binary)
#   build/code-server/<platform>/lib/...                   (Node + VS Code bits)
#
# Usage:
#   scripts/release/fetch_code_server.sh            # host platform
#   scripts/release/fetch_code_server.sh <version>  # override the pin (testing)
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# The pin lives in the Dart source; a single grep keeps this script honest.
# (Pass $1 to override for a one-off CI matrix test against a different tag.)
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  VERSION="$(grep -m1 'const String codeServerVersion' \
    packages/cc_infra/lib/src/ide/code_server_service.dart \
    | sed -E "s/.*'([^']+)'.*/\1/")"
fi
[ -n "$VERSION" ] || { echo "ERROR: could not resolve code-server version pin"; exit 2; }

OS_TAG=""
ARCH_TAG=""
PLATFORM=""
case "$(uname -s)" in
  Darwin)
    OS_TAG=macos
    # code-server names arm64 builds "arm64"; amd64 builds "amd64".
    ARCH_TAG="$(uname -m)"
    [ "$ARCH_TAG" = "arm64" ] || ARCH_TAG="amd64"
    # Matches CodeServerService._platformTag (darwin/linux + arm64/x64).
    PLATFORM="darwin-$([ "$ARCH_TAG" = "arm64" ] && echo arm64 || echo x64)"
    ;;
  Linux)
    OS_TAG=linux
    # Not `[ … ] && a || b`: that reads as if/else but silently runs BOTH
    # branches whenever the first assignment fails.
    if [ "$(uname -m)" = "aarch64" ]; then ARCH_TAG="arm64"; else ARCH_TAG="amd64"; fi
    PLATFORM="linux-$([ "$ARCH_TAG" = "arm64" ] && echo arm64 || echo x64)"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    # code-server ships no native Windows host — WSL/remote only.
    echo "::warning::code-server has no native Windows build; skipping fetch (Windows-local is WSL/remote-only)."
    exit 0
    ;;
  *) echo "ERROR: unsupported OS $(uname -s)"; exit 2 ;;
esac

OUT="build/code-server/$PLATFORM"
# The GitHub release asset is code-server-<version>-<os>-<arch>.tar.gz
# (release dirs use the OS-tag the upstream uses: macos/linux + arm64/amd64).
TARBALL_NAME="code-server-${VERSION}-${OS_TAG}-${ARCH_TAG}"
URL="https://github.com/coder/code-server/releases/download/v${VERSION}/${TARBALL_NAME}.tar.gz"

echo "==> Fetching code-server v${VERSION} for ${PLATFORM}"
echo "    $URL"

# Reuse a cached fetch, keyed on the VERSION as well as the platform.
#
# $OUT is platform-only, so testing for the binary alone made a version bump a
# silent no-op on any machine that had fetched before: the release then shipped
# the stale code-server with no diagnostic. CI never saw it (cold runners);
# a developer would. The stamp file is what makes the key honest.
STAMP="$OUT/.code-server-version"
if [ -x "$OUT/bin/code-server" ] && [ "$(cat "$STAMP" 2>/dev/null || true)" = "$VERSION" ]; then
  echo "==> code-server v$VERSION already present at $OUT/bin/code-server — skipping"
  exit 0
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "$URL" -o "$TMP/$TARBALL_NAME.tar.gz"
rm -rf "$OUT"
mkdir -p "$OUT"
# The archive's top dir is code-server-<version>-<os>-<arch>/ ; strip it so its
# bin/code-server + lib/… land directly in $OUT (the layout CodeServerService
# probes at <installDir>/bin/code-server).
tar -xzf "$TMP/$TARBALL_NAME.tar.gz" -C "$OUT" --strip-components=1

# The wrapper (bin/code-server) execs the bundled Node (lib/node); BOTH must
# stay executable. `tar` preserves the archive's modes, but a later `cp` that
# stages this into a bundle can drop them — force both here (belt-and-suspenders,
# mirrors CodeServerService._forceExecutable on the on-demand download path).
chmod 755 "$OUT/bin/code-server" "$OUT/lib/node"
test -x "$OUT/bin/code-server" || { echo "ERROR: $OUT/bin/code-server is not executable after extract"; exit 1; }
test -x "$OUT/lib/node" || { echo "ERROR: $OUT/lib/node is not executable after extract"; exit 1; }
# Stamp last, so an interrupted extract is never mistaken for a complete one.
printf '%s\n' "$VERSION" > "$STAMP"
echo "==> code-server staged at $OUT/bin/code-server"
