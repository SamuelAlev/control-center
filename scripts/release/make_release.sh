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

# 1. Collect the shippable binaries.
rm -rf release && mkdir -p release
find "$ARTIFACTS" -type f \( \
  -name '*.dmg' -o -name '*-setup.exe' -o -name '*.AppImage' -o -name '*-linux-x64.tar.gz' \
\) -exec cp {} release/ \;

# 2. Authoritative checksums over the binaries we actually ship.
( cd release && for f in *; do [ -f "$f" ] && sha256sum "$f"; done > SHA256SUMS.txt )
echo "==> Release files:"; ls -la release

# 3. Release notes.
cat > release/notes.md <<EOF
## Control Center ${VERSION}

Desktop builds for macOS (Apple Silicon), Windows and Linux.

### Downloads
- **macOS** — \`Control-Center-${VERSION}-arm64.dmg\` (Apple Silicon)
- **Windows** — \`Control-Center-${VERSION}-x64-setup.exe\`
- **Linux** — \`Control-Center-${VERSION}-x86_64.AppImage\` (or the \`.tar.gz\`)

### First-run trust (these builds are not signed by a paid developer cert)
- **macOS:** right-click the app → **Open** (or System Settings → Privacy & Security → **Open Anyway**). If it says "damaged", run:
  \`xattr -dr com.apple.quarantine "/Applications/Control Center.app"\`
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
  $(ls Control-Center-* SHA256SUMS.txt)
echo "==> Draft release created for $TAG — review and publish from the Releases page."
