#!/usr/bin/env bash
#
# Collects the per-platform build artifacts, writes authoritative SHA-256
# checksums and release notes (first-run trust + provenance verification) and
# creates a DRAFT GitHub Release. Review the draft, then publish.
#
# Expects the build jobs' artifacts downloaded under $ARTIFACTS (default
# ./artifacts), the two Sparkle feeds written by gen_appcast.sh and the `gh`
# CLI authenticated (GH_TOKEN + GH_REPO).
#
# The shipped asset set is EXACT, not a pattern match. Every name comes from
# scripts/lib/artifact_names.sh and a missing OR unexpected file fails the job:
#   * a silently short release used to be possible — an unquoted `$(ls …)` let a
#     missing file print a warning to stderr while `gh` still succeeded — and
#   * `cc_server update` treats a missing SHA256SUMS.txt entry as a hard
#     refusal, so a dropped asset bricks self-update for that platform on a
#     user's machine instead of failing here.
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
#   VERSION=1.0.0 TAG=v1.0.0 scripts/release/make_release.sh --dry-run
#
# --dry-run does everything except `gh release create`, printing the argv it
# would have used. This is the only script in the pipeline that cannot be safely
# exercised for real, which is why it is the only one carrying a flag.
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"
source "$REPO_ROOT/scripts/lib/common.sh"
source "$REPO_ROOT/scripts/lib/artifact_names.sh"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

VERSION="${VERSION:?VERSION is required}"
TAG="${TAG:?TAG is required}"
ARTIFACTS="${ARTIFACTS:-artifacts}"
# Not a bare `${GITHUB_REPOSITORY%/*}`: under `set -u` that aborts with an
# opaque "unbound variable" on a local run, while VERSION/TAG give a usable
# message. The default matters only for the notes' `--owner` hint.
OWNER="${GITHUB_REPOSITORY:-SamuelAlev/control-center}"
OWNER="${OWNER%/*}"
# GHCR image names are lowercase — derive a lowercase owner for the image refs
# printed in the release notes (the containers job pushes under the same path).
OWNER_LC="$(printf '%s' "$OWNER" | tr '[:upper:]' '[:lower:]')"

# The COMPLETE set this release ships, derived from RELEASE_PLATFORMS: each
# platform's desktop artifacts + its standalone cc_server archive, plus the
# Sparkle feed for each platform that has an in-app updater.
EXPECTED=()
while IFS= read -r name; do EXPECTED+=("$name"); done < <(release_asset_names "$VERSION")

# 1. Collect by exact name. The desktop/server artifacts arrive under
# $ARTIFACTS/<job>/…; the two feeds are written into the working directory by
# gen_appcast.sh, so both roots are searched.
rm -rf release && mkdir -p release
missing=()
for name in "${EXPECTED[@]}"; do
  src="$(find "$ARTIFACTS" . -maxdepth 3 -type f -name "$name" -print -quit 2>/dev/null || true)"
  if [ -n "$src" ]; then
    cp "$src" "release/$name"
  else
    missing+=("$name")
  fi
done
if [ "${#missing[@]}" -gt 0 ]; then
  die "the release is incomplete — these artifacts were never produced:
  - ${missing[*]}
A build job failed or was skipped. Refusing to publish a partial release."
fi

# An UNEXPECTED file is loud too: a renamed artifact should fail visibly here,
# not quietly stop being shipped.
actual_count="$(find release -maxdepth 1 -type f | wc -l | tr -d ' ')"
[ "$actual_count" -eq "${#EXPECTED[@]}" ] \
  || die "release/ holds $actual_count files but ${#EXPECTED[@]} were expected. Reconcile scripts/lib/artifact_names.sh with what the build jobs produce."

# 2. Authoritative checksums, written OUTSIDE the directory being summed.
#
# Writing them in place used to corrupt the file: bash applies a compound
# command's redirection BEFORE the `for` word list is expanded, so
# `for f in *; do …; done > SHA256SUMS.txt` saw a zero-byte SHA256SUMS.txt in
# its own glob and hashed it — partially written, hence non-deterministically.
# `sha256sum -c` then failed on the very file users are told to verify with.
SUMS_TMP="$(mktemp)"
( cd release && sha256sum -- "${EXPECTED[@]}" ) > "$SUMS_TMP"
mv "$SUMS_TMP" release/SHA256SUMS.txt
chmod 644 release/SHA256SUMS.txt  # mktemp creates 0600; this one ships.
# Self-verify: one line and it permanently closes the class of bug above.
( cd release && sha256sum -c --quiet SHA256SUMS.txt )
log "Release files:"; ls -la release

# 3. Release notes.
#
# The platform-varying lines are composed here rather than written inline, so a
# release that does not ship a platform never advertises a download that does
# not exist. Everything follows RELEASE_PLATFORMS in scripts/lib/artifact_names.sh.
desktop_downloads=""
server_downloads=""
first_run=""
updater_note="Linux is notify-only: the About page's \"Check for updates\" opens this release page."
if release_ships_platform macos; then
  desktop_downloads+="- **macOS** — \`$(release_asset_name dmg "$VERSION")\` (Apple Silicon)"$'\n'
  server_downloads+="- **macOS** — \`$(release_asset_name server-macos "$VERSION")\` (Developer ID signed + notarized; a loose CLI can't be stapled, so the first launch verifies notarization online — stay connected)"$'\n'
  first_run+="The macOS DMG is Developer ID signed + notarized, so it opens normally."$'\n'
fi
if release_ships_platform windows; then
  desktop_downloads+="- **Windows** — \`$(release_asset_name win-setup "$VERSION")\`"$'\n'
  server_downloads+="- **Windows** — \`$(release_asset_name server-windows "$VERSION")\` (unsigned)"$'\n'
  first_run+="- **Windows:** SmartScreen → **More info** → **Run anyway**."$'\n'
  updater_note="macOS and Windows update IN APP (Sparkle / WinSparkle — the app checks on launch, daily and from Settings → Advanced → About; updates verify a signature before applying). $updater_note"
else
  updater_note="macOS updates IN APP (Sparkle — the app checks on launch, daily and from Settings → Advanced → About; updates verify an EdDSA signature before applying). $updater_note"
fi
if release_ships_platform linux; then
  desktop_downloads+="- **Linux** — \`$(release_asset_name appimage "$VERSION")\` (or the \`.tar.gz\`)"$'\n'
  server_downloads+="- **Linux** — \`$(release_asset_name server-linux "$VERSION")\`"$'\n'
  first_run+="- **Linux:** \`chmod +x $(release_asset_name appimage "$VERSION") && ./$(release_asset_name appimage "$VERSION")\`"$'\n'
fi
cat > release/notes.md <<EOF
## Control Center ${VERSION}

Desktop apps, the standalone self-hostable \`cc_server\` backend and Docker images.

### Desktop downloads
${desktop_downloads}

The desktop app runs the \`cc_server\` backend for you (self-managed) or connects to a remote one.

${updater_note}

### Self-hosted server (cc_server)
The pure-Dart backend the web + phone thin clients dial. Each archive is self-contained — binary, sqlite3, the FFI natives and the speech recognizer (meeting transcription):
${server_downloads}

Extract, then provision a device and run it:
\`\`\`
./bin/cc_server pair --client-url https://app.usectrl.dev   # prints a pairing key + QR
./bin/cc_server --data-dir ./data --port 9030               # add --bind any (TLS) to expose it
\`\`\`

### Docker images (GHCR)
- \`ghcr.io/${OWNER_LC}/cc-server:${VERSION}\` — the self-hosted backend (\`-p 9030:9030 -v cc_data:/data\`)
- \`ghcr.io/${OWNER_LC}/cc-webapp:${VERSION}\` — the web client (static nginx, \`-p 8080:8080\`)
- \`ghcr.io/${OWNER_LC}/cc-remote:${VERSION}\` — the phone PWA (static nginx, \`-p 8081:8080\`)
- \`ghcr.io/${OWNER_LC}/cc-signaling-server:${VERSION}\` — the WebRTC pairing relay for the phone (\`-p 8788:8788\`, optional)

### First-run trust
${first_run}

### Verify the download
Checksums are in \`SHA256SUMS.txt\`. Each binary also carries a signed SLSA build-provenance attestation:
\`\`\`
gh attestation verify <file> --owner ${OWNER}
\`\`\`
EOF

# 4. Draft release. Quoted argv — no \`ls\`, no word splitting.
cd release
if [ "$DRY_RUN" -eq 1 ]; then
  log "[dry run] would create draft release $TAG with:"
  printf '    %s\n' "${EXPECTED[@]}" SHA256SUMS.txt
  exit 0
fi
gh release create "$TAG" \
  --draft \
  --target "${GITHUB_SHA:-HEAD}" \
  --title "Control Center $VERSION" \
  --notes-file notes.md \
  "${EXPECTED[@]}" SHA256SUMS.txt
log "Draft release created for $TAG — review and publish from the Releases page."
