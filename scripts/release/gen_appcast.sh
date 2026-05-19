#!/usr/bin/env bash
# Generates the Sparkle / WinSparkle appcasts for a release: appcast.xml
# (macOS, DMG enclosure, EdDSA) and appcast-windows.xml (Windows, Inno
# setup.exe enclosure, DSA/SHA1 — WinSparkle 0.8.x predates its EdDSA
# support).
#
# Separate files per OS on purpose: Sparkle and WinSparkle both "just take the
# newest item", so one combined feed would let a Windows install try to apply
# a DMG. The app picks its feed URL by platform (see
# lib/core/update/desktop_updater.dart):
#   macOS   → https://github.com/<repo>/releases/latest/download/appcast.xml
#   Windows → https://github.com/<repo>/releases/latest/download/appcast-windows.xml
# Both URLs redirect to the newest PUBLISHED release, so drafts stay invisible
# to the updater until a human publishes them.
#
# Enclosures (the unit each updater knows how to APPLY):
#   macOS   the notarized .dmg — Sparkle mounts it and swaps the .app.
#   Windows the Inno .exe installer — WinSparkle *launches* the enclosure as
#           an installer; it cannot unpack a zip. The portable zip stays a
#           plain download asset, never a feed enclosure.
#
# Signature schemes (fail-closed: the script refuses to emit an unsigned
# appcast — an unsigned feed is one every client rejects anyway):
#   macOS   sparkle:edSignature   detached Ed25519 over the DMG bytes, base64.
#                               Key: SPARKLE_ED25519_KEY (base64 private key
#                               from Sparkle's generate_keys / `dart run
#                               auto_updater:generate_keys` on macOS; the 32-,
#                               64- and 96-byte export forms are all accepted).
#   Windows sparkle:dsaSignature  DSA-SHA1 over the installer bytes, DER,
#                               base64. Key: SPARKLE_DSA_PRIVATE_KEY (the
#                               dsa_priv.pem from generate_keys, PEM contents).
# Neither key is the Apple Developer ID certificate — Sparkle/WinSparkle
# verify updates with their own public keys baked into the app bundle
# (macos/Runner/Info.plist SUPublicEDKey, windows/runner/Runner.rc DSAPub).
#
# Every item carries BOTH version elements, because that is what the updaters
# compare against the installed build. An item without them is unevaluable and
# is silently ignored.
#
# The two platforms deliberately put DIFFERENT things in sparkle:version, because
# they compare against different fields of the installed app — do not "fix" this
# into one value:
#   macOS    CFBundleVersion, which CI stamps from --build-number, so the item
#            carries $BUILD_NUMBER.
#   Windows  the .rc FileVersion, which Flutter sets from FLUTTER_VERSION — the
#            build NAME (see windows/runner/Runner.rc) — so the item carries
#            $VERSION.
# sparkle:shortVersionString is the human "1.2.3" on both.
#
# Usage (from the release job, with the build artifacts under artifacts/):
#   gen_appcast.sh <version> <tag> <build-number>
# Env: SPARKLE_ED25519_KEY + SPARKLE_DSA_PRIVATE_KEY (required),
#      GH_REPO (default SamuelAlev/control-center),
#      ARTIFACTS_DIR (default artifacts), OUT_DIR (default .)
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"

VERSION="${1:?usage: gen_appcast.sh <version> <tag> <build-number>}"
TAG="${2:?usage: gen_appcast.sh <version> <tag> <build-number>}"
BUILD_NUMBER="${3:?usage: gen_appcast.sh <version> <tag> <build-number>}"
REPO="${GH_REPO:-SamuelAlev/control-center}"
ARTIFACTS="${ARTIFACTS_DIR:-artifacts}"
OUT="${OUT_DIR:-.}"
# shellcheck disable=SC2034  # assigned only to trigger the `:?` guard; python reads os.environ.
ED_KEY="${SPARKLE_ED25519_KEY:?SPARKLE_ED25519_KEY (base64 Ed25519 private key) is required}"
DSA_KEY="${SPARKLE_DSA_PRIVATE_KEY:?SPARKLE_DSA_PRIVATE_KEY (dsa_priv.pem contents) is required}"
export SPARKLE_ED25519_KEY SPARKLE_DSA_PRIVATE_KEY

# Which feeds to emit follows the platforms the release actually ships
# (scripts/lib/artifact_names.sh). Windows is currently off, so no Windows
# enclosure exists to sign and no appcast-windows.xml is written — rather than
# failing on a missing artifact that was never built.
# shellcheck source=../lib/artifact_names.sh
source "$REPO_ROOT/scripts/lib/artifact_names.sh"

DMG="${ARTIFACTS}/macos/Control-Center-${VERSION}-arm64.dmg"
# WinSparkle launches the enclosure as an installer — the Inno .exe, never the
# portable zip (which it has no way to unpack).
SETUP="${ARTIFACTS}/windows/Control-Center-${VERSION}-x64-setup.exe"
if release_ships_platform macos; then
  [ -f "$DMG" ] || { echo "::error::missing macOS artifact $DMG" >&2; exit 1; }
fi
if release_ships_platform windows; then
  [ -f "$SETUP" ] || { echo "::error::missing Windows artifact $SETUP" >&2; exit 1; }
fi

# Clients fetch the feed through releases/latest/download/… (see
# desktop_update_config.dart); the enclosures are tag-pinned so an item always
# names the exact build it was signed over.
LATEST="https://github.com/${REPO}/releases/latest/download"
BASE="https://github.com/${REPO}/releases/download/${TAG}"
PUB_DATE="$(date -u '+%a, %d %b %Y %H:%M:%S +0000')"

# Signing needs python3 + the `cryptography` package. Fail here, naming the
# fix, rather than inside a heredoc with a bare ModuleNotFoundError — the
# release job installs it explicitly (and its egress allowlist has to permit
# PyPI for that to work).
if ! python3 -c 'import cryptography' >/dev/null 2>&1; then
  echo "::error::gen_appcast.sh needs python3 with the 'cryptography' package (pip install cryptography)." >&2
  exit 1
fi

#
# Sparkle's generate_keys exports the private key in one of three shapes and
# which one you get depends on the tool version — accept all rather than make
# the release depend on a hand-trimmed secret:
#   32 bytes  the raw seed
#   64 bytes  seed ‖ public key (the common `sign_update` form)
#   96 bytes  the older format (seed ‖ public ‖ trailing material)
# The seed is the leading 32 bytes in every case.
sign_ed25519() {
  python3 - "$1" <<'PYEOF'
import base64, os, sys
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

raw = base64.b64decode(os.environ["SPARKLE_ED25519_KEY"].strip())
if len(raw) not in (32, 64, 96):
    sys.exit(
        f"SPARKLE_ED25519_KEY decodes to {len(raw)} bytes; expected 32, 64 or 96 "
        "(the base64 private key printed by Sparkle's generate_keys)."
    )
key = Ed25519PrivateKey.from_private_bytes(raw[:32])
with open(sys.argv[1], "rb") as f:
    print(base64.b64encode(key.sign(f.read())).decode())
PYEOF
}

sign_dsa() {
  python3 - "$1" <<'PYEOF'
import base64, os, sys
from cryptography.hazmat.primitives import serialization, hashes

key = serialization.load_pem_private_key(
    os.environ["SPARKLE_DSA_PRIVATE_KEY"].encode(), password=None)
with open(sys.argv[1], "rb") as f:
    sig = key.sign(f.read(), hashes.SHA1())  # WinSparkle's scheme: DSA over the file, SHA1 digest
print(base64.b64encode(sig).decode())
PYEOF
}

# `stat -c` is GNU, `stat -f` is BSD/macOS — the release job runs on Linux but
# the appcast golden test runs on a developer machine.
file_size() {
  stat -c '%s' "$1" 2>/dev/null || stat -f '%z' "$1"
}

# Assert each private key matches the public half the SHIPPED app verifies with.
#
# Both public slots fail closed when unset — Sparkle refuses an update with an
# empty SUPublicEDKey, WinSparkle refuses one with no DSAPub. That is correct,
# but it is also SILENT: without this gate the release job signs a perfectly
# valid feed, publishes it and every client rejects every update forever with
# no signal anywhere in the pipeline. The same hole reopens on any key rotation
# where the secret is updated and the committed public half is not.
#
# We already hold both private keys here, so deriving the public half and
# comparing costs nothing and converts that into a named build failure.
assert_public_keys() {
  python3 - "$REPO_ROOT" <<'PYEOF'
import base64, os, plistlib, sys
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

root = sys.argv[1]
problems = []

# Two distinct failures, deliberately gated differently:
#
#   MISMATCH    a public key is configured but is not this private key's half.
#               Always fatal — it is a rotation that only got half-applied and
#               it is fatal to updates wherever it happens.
#   UNCONFIGURED  the slot is still the committed placeholder. Fatal only for a
#               real release (GITHUB_ACTIONS), because the local harness and
#               test/tooling/appcast_generation_test.dart legitimately sign with
#               throwaway keys against an unconfigured checkout.
release = bool(os.environ.get("GITHUB_ACTIONS"))

def unconfigured(msg):
    if release:
        problems.append(msg)
    else:
        print(f"gen_appcast.sh: {msg.splitlines()[0]}", file=sys.stderr)

# macOS — Info.plist SUPublicEDKey must equal the seed's public half.
raw = base64.b64decode(os.environ["SPARKLE_ED25519_KEY"].strip())
derived = base64.b64encode(
    Ed25519PrivateKey.from_private_bytes(raw[:32]).public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
).decode()
plist_path = os.path.join(root, "macos/Runner/Info.plist")
with open(plist_path, "rb") as f:
    shipped = (plistlib.load(f).get("SUPublicEDKey") or "").strip()
if not shipped:
    unconfigured(
        f"{plist_path}: SUPublicEDKey is empty, so Sparkle rejects every update.\n"
        f"    Set it to the public half of SPARKLE_ED25519_KEY:\n      {derived}"
    )
elif shipped != derived:
    problems.append(
        f"{plist_path}: SUPublicEDKey does not match SPARKLE_ED25519_KEY.\n"
        f"    shipped {shipped}\n    derived {derived}"
    )

# Windows — dsa_pub.pem must be the private key's public half.
pem_path = os.path.join(root, "dsa_pub.pem")
derived_pem = serialization.load_pem_private_key(
    os.environ["SPARKLE_DSA_PRIVATE_KEY"].encode(), password=None
).public_key().public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo,
)
try:
    with open(pem_path, "rb") as f:
        shipped_pem = f.read()
except FileNotFoundError:
    shipped_pem = b""
# PARSE it rather than grep for the armor. The committed placeholder is prose
# that both names the algorithm ("NOT A VALID DSA PUBLIC KEY") and shows an
# example -----BEGIN PUBLIC KEY----- block, so every substring test matches it.
# Whether WinSparkle can load the key is the actual question, so ask that.
try:
    shipped_key = serialization.load_pem_public_key(shipped_pem)
except Exception:
    shipped_key = None
if shipped_key is None:
    unconfigured(
        f"{pem_path}: not a loadable public key (still the placeholder?), so "
        "WinSparkle rejects every update.\n"
        f"    Replace the whole file with the public half of SPARKLE_DSA_PRIVATE_KEY:\n"
        + "".join(f"      {ln}\n" for ln in derived_pem.decode().splitlines())
    )
elif shipped_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo,
) != derived_pem:
    problems.append(
        f"{pem_path} does not match SPARKLE_DSA_PRIVATE_KEY — rotate them together."
    )

if problems:
    sys.exit(
        "the signing keys do not match the public keys baked into the app "
        "(a feed signed with them would be rejected by every client):\n\n  "
        + "\n\n  ".join(problems)
    )
PYEOF
}
# python prints the (multi-line, actionable) reason to stderr and exits 1.
assert_public_keys || { echo "::error::gen_appcast.sh: refusing to sign a feed no shipped client can verify (see above)." >&2; exit 1; }

if release_ships_platform macos; then
  DMG_SIG="$(sign_ed25519 "$DMG")"
  DMG_LEN="$(file_size "$DMG")"
fi
if release_ships_platform windows; then
  SETUP_SIG="$(sign_dsa "$SETUP")"
  SETUP_LEN="$(file_size "$SETUP")"
fi

if release_ships_platform macos; then
cat > "${OUT}/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Control Center</title>
    <link>${LATEST}/appcast.xml</link>
    <description>Most recent releases</description>
    <language>en</language>
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:channel>stable</sparkle:channel>
      <sparkle:version>${BUILD_NUMBER}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:releaseNotesLink>https://github.com/${REPO}/releases/tag/${TAG}</sparkle:releaseNotesLink>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <enclosure url="${BASE}/Control-Center-${VERSION}-arm64.dmg" sparkle:edSignature="${DMG_SIG}" length="${DMG_LEN}" type="application/octet-stream" />
    </item>
  </channel>
</rss>
EOF
fi

if release_ships_platform windows; then
# /SILENT /SP- : Inno's unattended mode with no "this will install…" prompt —
# the user already consented in WinSparkle's own dialog. WinSparkle relaunches
# the app itself after the installer exits.
cat > "${OUT}/appcast-windows.xml" <<EOF
<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>Control Center</title>
    <link>${LATEST}/appcast-windows.xml</link>
    <description>Most recent releases</description>
    <language>en</language>
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${PUB_DATE}</pubDate>
      <sparkle:version>${VERSION}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:releaseNotesLink>https://github.com/${REPO}/releases/tag/${TAG}</sparkle:releaseNotesLink>
      <enclosure url="${BASE}/Control-Center-${VERSION}-x64-setup.exe" sparkle:dsaSignature="${SETUP_SIG}" sparkle:installerArguments="/SILENT /SP-" length="${SETUP_LEN}" type="application/octet-stream" />
    </item>
  </channel>
</rss>
EOF
fi

echo "Wrote appcasts for ${TAG} into ${OUT} (platforms: ${RELEASE_PLATFORMS})."
