#!/usr/bin/env bash
#
# Collects the per-platform build artifacts, writes authoritative SHA-256
# checksums and release notes (first-run trust + provenance verification), and
# creates a DRAFT GitHub Release. Review the draft, then publish.
#
# Expects the build jobs' artifacts downloaded under $ARTIFACTS (default
# ./artifacts) and the `gh` CLI authenticated (GH_TOKEN + GH_REPO).
#
# Environment:
#   VERSION              release version, e.g. 1.0.0 (required)
#   TAG                  release tag, e.g. v1.0.0 (required)
#   ARTIFACTS            downloaded-artifacts dir (default: artifacts)
#   GITHUB_SHA           commit to target if the tag doesn't exist yet
#   GITHUB_REPOSITORY    owner/repo (used for the attestation-verify hint)
#   GH_TOKEN / GH_REPO   gh CLI auth + target repo
#
# Usage:
#   VERSION=1.0.0 TAG=v1.0.0 scripts/release/make_release.sh
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

VERSION="${VERSION:?VERSION is required}"
TAG="${TAG:?TAG is required}"
ARTIFACTS="${ARTIFACTS:-artifacts}"
OWNER="${GITHUB_REPOSITORY%/*}"
# GHCR image names are lowercase — derive a lowercase owner for the image refs
# printed in the release notes (the containers job pushes under the same path).
OWNER_LC="$(printf '%s' "$OWNER" | tr '[:upper:]' '[:lower:]')"

# 1. Collect the shippable binaries: the 3 desktop installers + the 3 standalone
# cc_server archives (macOS/Linux .tar.gz, Windows .zip).
rm -rf release && mkdir -p release
find "$ARTIFACTS" -type f \( \
  -name '*.dmg' -o -name '*-setup.exe' -o -name '*.AppImage' \
  -o -name 'Control-Center-*-linux-x64.tar.gz' \
  -o -name 'cc_server-*.tar.gz' -o -name 'cc_server-*.zip' \
\) -exec cp {} release/ \;

# 2. Authoritative checksums over the binaries we actually ship.
( cd release && for f in *; do [ -f "$f" ] && sha256sum "$f"; done > SHA256SUMS.txt )
echo "==> Release files:"; ls -la release

# 3. Release notes.
cat > release/notes.md <<EOF
## Control Center ${VERSION}

Desktop apps for macOS/Windows/Linux, the standalone self-hostable \`cc_server\` backend, and Docker images.

### Desktop downloads
- **macOS** — \`Control-Center-${VERSION}-arm64.dmg\` (Apple Silicon)
- **Windows** — \`Control-Center-${VERSION}-x64-setup.exe\`
- **Linux** — \`Control-Center-${VERSION}-x86_64.AppImage\` (or the \`.tar.gz\`)

The desktop app runs the \`cc_server\` backend for you (self-managed) or connects to a remote one.

### Self-hosted server (cc_server)
The pure-Dart backend the web + phone thin clients dial. Each archive is self-contained — binary, sqlite3, the FFI natives, and the speech recognizer (meeting transcription):
- **macOS** — \`cc_server-${VERSION}-macos-arm64.tar.gz\` (Developer ID signed + notarized; a loose CLI can't be stapled, so the first launch verifies notarization online — stay connected)
- **Linux** — \`cc_server-${VERSION}-linux-x64.tar.gz\`
- **Windows** — \`cc_server-${VERSION}-windows-x64.zip\` (unsigned)

Extract, then provision a device and run it:
\`\`\`
./bin/cc_server pair --client-url https://app.usectrl.dev   # prints a pairing key + QR
./bin/cc_server --data-dir ./data --port 9030               # add --bind any (TLS) to expose it
\`\`\`

### Docker images (GHCR)
- \`ghcr.io/${OWNER_LC}/cc-server:${VERSION}\` — the self-hosted backend (\`-p 9030:9030 -v cc_data:/data\`)
- \`ghcr.io/${OWNER_LC}/control-center-web:${VERSION}\` — the web client (static nginx, \`-p 8080:80\`)
- \`ghcr.io/${OWNER_LC}/control-center-remote:${VERSION}\` — the phone PWA (static nginx, \`-p 8081:80\`)

### First-run trust
The macOS DMG is Developer ID signed + notarized, so it opens normally. Windows and Linux are not code-signed:
- **Windows:** SmartScreen → **More info** → **Run anyway**.
- **Linux:** \`chmod +x Control-Center-${VERSION}-x86_64.AppImage && ./Control-Center-${VERSION}-x86_64.AppImage\`

### Verify the download
Checksums are in \`SHA256SUMS.txt\`. Each binary also carries a signed SLSA build-provenance attestation:
\`\`\`
gh attestation verify <file> --owner ${OWNER}
\`\`\`
EOF

# 4. Draft release.
cd release
gh release create "$TAG" \
  --draft \
  --target "${GITHUB_SHA:-HEAD}" \
  --title "Control Center $VERSION" \
  --notes-file notes.md \
  $(ls Control-Center-* cc_server-* SHA256SUMS.txt)
echo "==> Draft release created for $TAG — review and publish from the Releases page."
