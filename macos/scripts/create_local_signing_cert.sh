#!/usr/bin/env bash
#
# Configures local macOS code signing so dev builds are signed with a trusted,
# team-prefixed identity — required for the data-protection keychain (secrets)
# to work without prompts. Writes a git-ignored Signing.local.xcconfig that
# overrides the ad-hoc default in AppInfo.xcconfig.
#
# Local dev always uses AUTOMATIC signing (the Apple-trusted "Apple Development"
# identity), for both free and paid Apple accounts. Manual / Developer ID can't
# be used locally: the keychain-access-groups ("Keychain Sharing") entitlement
# is a profile-managed capability, so under manual signing Xcode demands a
# provisioning profile — and `flutter run`'s xcodebuild can't mint one. With
# automatic signing Xcode auto-provisions Keychain Sharing into a dev profile.
# (Developer ID stays the CI/release path; macos_package.sh re-signs directly
# with codesign, which has no such gate.)
#
# The debug entitlement uses $(DEVELOPMENT_TEAM), so whichever team you sign
# with becomes the keychain access group automatically — no source edits.
#
# Prereq: add your Apple ID in Xcode → Settings → Accounts (free is fine).
#
# Run once:   bash macos/scripts/create_local_signing_cert.sh [TEAM_ID]
# Then mint the dev profile once (flutter run can't) — the commands are printed
# at the end — and `flutter run -d macos` works.
#
# Idempotent. CI and teammates who don't run this keep building ad-hoc.
set -euo pipefail

TEAM_ID="${1:-${DEVELOPMENT_TEAM:-}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/../Runner/Configs" && pwd)"
LOCAL_XCCONFIG="${CONFIG_DIR}/Signing.local.xcconfig"

if [ -z "$TEAM_ID" ]; then
  ids="$(security find-identity -v -p codesigning 2>/dev/null || true)"
  team_of() { printf '%s\n' "$ids" | sed -n "s/.*$1: .*(\([A-Z0-9]\{10\}\)).*/\1/p" | head -1; }
  TEAM_ID="$(team_of 'Apple Development')"
  [ -z "$TEAM_ID" ] && TEAM_ID="$(team_of 'Developer ID Application')"
fi

if [ -z "$TEAM_ID" ]; then
  echo "✗ No Apple team found in your keychain." >&2
  echo "  Add your Apple ID in Xcode → Settings → Accounts (free works), then" >&2
  echo "  re-run — or pass your Team ID explicitly:" >&2
  echo "      bash macos/scripts/create_local_signing_cert.sh <TEAM_ID>" >&2
  echo "  (find it at developer.apple.com → Membership)" >&2
  exit 1
fi

{
  echo "// Local, per-developer macOS signing override (git-ignored; written by"
  echo "// create_local_signing_cert.sh). AUTOMATIC signing under your Apple team;"
  echo "// the trusted \"Apple Development\" identity lets the data-protection keychain"
  echo "// read secrets with no prompt. Manual/Developer ID can't be used locally —"
  echo "// the keychain-access-groups capability forces a provisioning profile that"
  echo "// flutter run can't mint. CI ignores this file (re-signs Developer ID)."
  echo "CODE_SIGN_STYLE = Automatic"
  echo "DEVELOPMENT_TEAM = ${TEAM_ID}"
  echo "CODE_SIGN_IDENTITY = Apple Development"
} > "${LOCAL_XCCONFIG}"

echo "✓ Wrote ${LOCAL_XCCONFIG}  (automatic signing, team ${TEAM_ID})"
echo
echo "Mint the dev provisioning profile ONCE (flutter run can't — it doesn't pass"
echo "-allowProvisioningUpdates). This also creates your Apple Development cert if"
echo "you don't have one yet:"
echo
echo "    flutter build macos --config-only"
echo "    xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \\"
echo "      -configuration Debug -allowProvisioningUpdates build"
echo
echo "(Or open macos/Runner.xcworkspace in Xcode and build once with Cmd+R.)"
echo "Afterwards:  flutter run -d macos"
