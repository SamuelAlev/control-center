#!/usr/bin/env bash
#
# Creates a stable, self-signed macOS code-signing certificate for LOCAL
# development and points the Runner at it via a git-ignored xcconfig.
#
# Why: flutter_secure_storage uses the macOS login keychain (see
# lib/core/providers/storage_providers.dart — the data-protection keychain needs
# an Apple-team-resolved entitlement we deliberately don't have). The login
# keychain ties each item's ACL to the app's code signature. Ad-hoc builds get a
# fresh signature every rebuild, so macOS re-prompts ("…wants to use your
# information…") forever. A stable self-signed identity makes "Always Allow"
# stick. No Apple account — paid or free — is required.
#
# Run once:   bash macos/scripts/create_local_signing_cert.sh
# Then:       flutter clean && flutter run -d macos   (Always Allow once per item)
#
# Idempotent. CI and teammates who don't run this keep building ad-hoc.
set -euo pipefail

CERT_NAME="Control Center Dev"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/../Runner/Configs" && pwd)"
LOCAL_XCCONFIG="${CONFIG_DIR}/Signing.local.xcconfig"

if security find-certificate -c "${CERT_NAME}" "${KEYCHAIN}" >/dev/null 2>&1; then
  echo "✓ Code-signing certificate '${CERT_NAME}' already exists."
else
  echo "→ Creating self-signed code-signing certificate '${CERT_NAME}'…"
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT

  cat > "${TMP}/cert.conf" <<EOF
[req]
distinguished_name = dn
x509_extensions = v3
prompt = no
[dn]
CN = ${CERT_NAME}
[v3]
basicConstraints = critical, CA:false
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, codeSigning
EOF

  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
    -keyout "${TMP}/key.pem" -out "${TMP}/cert.pem" -config "${TMP}/cert.conf"

  # Bundle into PKCS#12 for `security import`. OpenSSL 3.x defaults to AES /
  # PBMAC1, which Apple's Security framework can't verify — it fails with
  # "MAC verification failed during PKCS12 import (wrong password?)" even though
  # the password is right. Pin the key/cert PBE + MAC to the SHA1/3DES algorithms
  # macOS understands (in OpenSSL's default provider, so no -legacy/RC2 needed),
  # and use a non-empty transit password to avoid the empty-password MAC
  # ambiguity. LibreSSL (Apple's /usr/bin/openssl) already emits a compatible
  # format, so only add the flags for real OpenSSL 3.x.
  P12_PW="control-center-dev"
  P12_FLAGS=""
  if openssl version 2>/dev/null | grep -q "^OpenSSL 3"; then
    P12_FLAGS="-keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1"
  fi
  # shellcheck disable=SC2086  # P12_FLAGS is a controlled list of simple flags
  openssl pkcs12 -export ${P12_FLAGS} -name "${CERT_NAME}" \
    -inkey "${TMP}/key.pem" -in "${TMP}/cert.pem" \
    -out "${TMP}/identity.p12" -passout "pass:${P12_PW}"

  # Import cert + key; pre-authorize codesign to use the private key.
  security import "${TMP}/identity.p12" -k "${KEYCHAIN}" -P "${P12_PW}" \
    -T /usr/bin/codesign -T /usr/bin/security

  # Best-effort: stop codesign from prompting for key access. Needs the login
  # keychain password; if it can't run non-interactively you'll just get a
  # one-time "codesign wants to sign using key …" prompt — click Always Allow.
  security set-key-partition-list -S apple-tool:,apple: -s \
    -k "" "${KEYCHAIN}" >/dev/null 2>&1 \
    || echo "  (note: codesign may prompt once for key access — click Always Allow)"

  echo "✓ Certificate created."
fi

printf 'CODE_SIGN_STYLE = Manual\nCODE_SIGN_IDENTITY = %s\n' "${CERT_NAME}" \
  > "${LOCAL_XCCONFIG}"
echo "✓ Wrote ${LOCAL_XCCONFIG}"
echo
echo "Next:  flutter clean && flutter run -d macos"
echo "Then click 'Always Allow' once per keychain item — it sticks from now on."
