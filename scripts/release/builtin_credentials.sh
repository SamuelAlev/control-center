#!/usr/bin/env bash
#
# Bakes the built-in third-party app credentials into the source constants
# `cc_server` compiles, and puts the empty defaults back afterwards.
#
# WHY A SOURCE FILE AND NOT `-D`: cc_server is built with `dart build cli`,
# which — unlike `dart compile exe` — has NO `--define`/`-D` flag, so a
# `String.fromEnvironment` value can never reach the server binary. Rewriting
# the constants before the build is the only mechanism left. The committed file
# holds empty strings, so nothing secret lives in this public repository.
#
# Run `inject` BEFORE any `dart build cli` in a release job (next to the
# sherpa/onnx staging step, which has the same ordering requirement). Absent
# secrets are NOT an error: the constants keep their empty defaults and every
# affected surface falls back the way a build from a fork does — Google Calendar
# asks for a client id + secret, and the GIF picker stays hidden.
#
# A half-configured Google pair IS an error. Both halves are required for
# Google's device-code exchange, so shipping one of them would advertise a
# "use Control Center's Google app" option that cannot work.
#
# Environment (all optional):
#   CC_BUILTIN_GOOGLE_CLIENT_ID      Google device-code ("TVs and limited input
#   CC_BUILTIN_GOOGLE_CLIENT_SECRET  devices") client. Both or neither.
#   CC_BUILTIN_KLIPY_APP_KEY         Klipy GIF app key (not a secret — it rides
#                                    in every request path — but kept out of git).
#
# Usage:
#   scripts/release/builtin_credentials.sh inject
#   scripts/release/builtin_credentials.sh restore   # undo; safe to run twice
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

TARGET="packages/cc_server_core/lib/src/builtin_credentials.dart"
# The pristine copy, so `restore` reproduces the committed bytes exactly rather
# than re-deriving a header comment that could drift out of sync with the file.
BACKUP="$TARGET.orig"

MODE="${1:?usage: builtin_credentials.sh <inject|restore>}"

case "$MODE" in
  restore)
    if [ -f "$BACKUP" ]; then
      mv -f "$BACKUP" "$TARGET"
      echo "==> Restored $TARGET"
    else
      echo "==> Nothing to restore (no $BACKUP)"
    fi
    exit 0
    ;;
  inject) ;;
  *) echo "ERROR: unknown mode '$MODE' (expected inject|restore)" >&2; exit 2 ;;
esac

test -f "$TARGET" || { echo "ERROR: $TARGET not found" >&2; exit 1; }

GOOGLE_ID="${CC_BUILTIN_GOOGLE_CLIENT_ID:-}"
GOOGLE_SECRET="${CC_BUILTIN_GOOGLE_CLIENT_SECRET:-}"
KLIPY_KEY="${CC_BUILTIN_KLIPY_APP_KEY:-}"

if { [ -n "$GOOGLE_ID" ] && [ -z "$GOOGLE_SECRET" ]; } ||
   { [ -z "$GOOGLE_ID" ] && [ -n "$GOOGLE_SECRET" ]; }; then
  echo "ERROR: CC_BUILTIN_GOOGLE_CLIENT_ID and CC_BUILTIN_GOOGLE_CLIENT_SECRET must be set together — Google's device-code exchange needs both, so half a pair ships an option that cannot work" >&2
  exit 1
fi

if [ -z "$GOOGLE_ID" ] && [ -z "$KLIPY_KEY" ]; then
  echo "::warning::no built-in credentials in the environment — this build ships none (Google Calendar will ask for a client id + secret, the GIF picker stays hidden)"
  exit 0
fi

# Renders a Dart single-quoted literal. Backslash first (so the escapes added
# below are not re-escaped), then the quote, then `$` (Dart interpolates it).
dart_literal() {
  local v="$1"
  v="${v//\\/\\\\}"
  v="${v//\'/\\\'}"
  v="${v//\$/\\\$}"
  printf "'%s'" "$v"
}

# Keep the pristine copy from the FIRST inject: a second inject in the same
# checkout (macos_package.sh then cc_server_package.sh) must not back up an
# already-injected file, or `restore` would leave the secrets behind.
[ -f "$BACKUP" ] || cp "$TARGET" "$BACKUP"

{
  echo "// GENERATED AT RELEASE BUILD TIME by scripts/release/builtin_credentials.sh."
  echo "//"
  echo "// Do NOT commit this version of the file: it holds real credentials. The"
  echo "// committed original is kept beside it as builtin_credentials.dart.orig and is"
  echo "// put back by \`builtin_credentials.sh restore\`. See that script for why these"
  echo "// are source constants rather than \`--define\` values, and see the original for"
  echo "// which credentials are eligible to live here at all."
  echo
  echo "/// The built-in Google OAuth **device-code** client id, or empty when this build"
  echo "/// carries none."
  echo "const String builtinGoogleClientId = $(dart_literal "$GOOGLE_ID");"
  echo
  echo "/// The client secret paired with [builtinGoogleClientId]."
  echo "const String builtinGoogleClientSecret = $(dart_literal "$GOOGLE_SECRET");"
  echo
  echo "/// The built-in Klipy GIF app key, or empty when this build carries none."
  echo "const String builtinKlipyAppKey = $(dart_literal "$KLIPY_KEY");"
} > "$TARGET"

# Report presence only — never the values (CI logs are readable).
echo "==> Injected built-in credentials into $TARGET"
echo "      google: $([ -n "$GOOGLE_ID" ] && echo present || echo absent)"
echo "      klipy:  $([ -n "$KLIPY_KEY" ] && echo present || echo absent)"
