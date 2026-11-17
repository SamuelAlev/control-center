#!/usr/bin/env bash
#
# Fails when a release artifact carries a bundled credential. Official builds
# ship zero third-party API keys or OAuth client secrets: GitHub, Google,
# Linear, Slack and Klipy run through each server's own apps or through
# Control Center Connect, never through a key compiled into a binary.
#
# Scans every regular file under each path (binaries included) for the shape
# of a real credential, not for a bare prefix: the redaction patterns the
# server and clients compile in contain `ghp_` and `xox` as regex source,
# and those must not trip the check. Also refuses the removed builtin
# credential plumbing (`CC_BUILTIN_*`, `builtinCredentials`).
#
# Usage: scripts/release/check_no_bundled_secrets.sh <file-or-dir>...
#        scripts/release/check_no_bundled_secrets.sh --self-test
#
# --self-test plants one synthetic credential of each kind (assembled at run
# time, so this file holds none) plus the redaction regex source, and checks
# that every plant is caught and the regex source is not. CI runs it before
# trusting a clean scan.
#
set -euo pipefail

usage() {
  echo "usage: check_no_bundled_secrets.sh <file-or-dir>... | --self-test" >&2
  exit 64
}
[ "$#" -gt 0 ] || usage

# name<TAB>extended regex. Each regex matches a credential's full shape.
# Prefixed tokens must start at an identifier boundary: C++ mangled names in
# the Flutter engine's dSYM contain `…force_highp_kEPKN24SkRasterPipeline…`,
# which is `ghp_` plus 36 alphanumerics.
PATTERNS=(
  $'GitHub App client id\t(^|[^A-Za-z0-9_])Iv(1\\.[0-9a-f]{16}|23[A-Za-z0-9]{16})'
  $'GitHub token\t(^|[^A-Za-z0-9_])(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}'
  $'GitHub fine-grained token\t(^|[^A-Za-z0-9_])github_pat_[A-Za-z0-9_]{60,}'
  $'Google OAuth client secret\t(^|[^A-Za-z0-9_])GOCSPX-[A-Za-z0-9_-]{28}'
  $'Google API key\t(^|[^A-Za-z0-9_])AIza[0-9A-Za-z_-]{35}'
  $'Google OAuth client id\t[0-9]{6,}-[a-z0-9]{32}\\.apps\\.googleusercontent\\.com'
  $'Google OAuth redirect scheme\tcom\\.googleusercontent\\.apps\\.[0-9]{6,}-[a-z0-9]{32}'
  $'Slack token\t(^|[^A-Za-z0-9_])xox[abposre]-[0-9]{6,}-[0-9A-Za-z-]{10,}'
  $'Slack app token\t(^|[^A-Za-z0-9_])xapp-[0-9]-[A-Z0-9]{6,}-[0-9]{6,}-[0-9a-f]{32,}'
  $'Linear key\t(^|[^A-Za-z0-9_])lin_(api|oauth)_[A-Za-z0-9]{32,}'
  $'Builtin credential plumbing\t(CC_BUILTIN_[A-Z_]+|[bB]uiltin[A-Za-z]*(Credential|ClientId|ClientSecret|ApiKey|AppKey))'
)

# Prints "<name>\t<file>" for every match under the given paths. Exits 2
# when grep cannot read something: an unscanned file is not a clean one.
scan() {
  local entry name regex file matches rc
  for entry in "${PATTERNS[@]}"; do
    name="${entry%%$'\t'*}"
    regex="${entry#*$'\t'}"
    # -a: binaries are text here; -r: walk directories; -l: one line per file.
    rc=0
    matches="$(LC_ALL=C grep -rlaE -- "$regex" "$@")" || rc=$?
    if [ "$rc" -gt 1 ]; then
      echo "check_no_bundled_secrets: could not scan every file" >&2
      exit 2
    fi
    while IFS= read -r file; do
      [ -n "$file" ] && printf '%s\t%s\n' "$name" "$file"
    done <<< "$matches"
  done
  return 0
}

if [ "$1" = "--self-test" ]; then
  dir="$(mktemp -d)"
  trap 'rm -rf "$dir"' EXIT
  plant() { printf 'pre\000%s\000post' "$2" > "$dir/$1.bin"; }
  plant github "gh""p_$(printf 'A1b2%.0s' {1..9})"
  plant github_app "Iv""23li$(printf 'Q%.0s' {1..14})"
  plant google_secret "GOC""SPX-$(printf 'a%.0s' {1..28})"
  plant google_key "AI""za$(printf 'B%.0s' {1..35})"
  plant google_client "1234567-$(printf 'a%.0s' {1..32}).apps.googleusercontent.com"
  plant google_scheme "com.google""usercontent.apps.1234567-$(printf 'b%.0s' {1..32})"
  plant slack "xo""xb-1234567890-abcdefABCDEF1234"
  plant linear "lin""_api_$(printf 'Z%.0s' {1..40})"
  plant builtin "kBuilt""inGoogleClientId"
  printf '%s' "RegExp(r'\\bghp_[A-Za-z0-9]{36}\\b') xox[abeoprs]- GOCSPX- AIza Iv23" \
    > "$dir/redaction_source.bin"
  # Skia symbol fragment from FlutterMacOS.framework.dSYM.
  printf 'pre\000%s\000post' \
    "_clamp_8888_force_hi""ghp_kEPKN24SkRasterPipelineContexts9GatherCtxEmmRP" \
    > "$dir/mangled_symbol.bin"
  found="$(scan "$dir")"
  failed=0
  for plant in github github_app google_secret google_key google_client google_scheme slack linear builtin; do
    grep -q "/$plant.bin\$" <<< "$found" || {
      echo "self-test: $plant was not caught" >&2
      failed=1
    }
  done
  if grep -q "/redaction_source.bin\$" <<< "$found"; then
    echo "self-test: redaction regex source was flagged" >&2
    failed=1
  fi
  if grep -q "/mangled_symbol.bin\$" <<< "$found"; then
    echo "self-test: mangled C++ symbol was flagged" >&2
    failed=1
  fi
  [ "$failed" -eq 0 ] || exit 1
  echo "check_no_bundled_secrets self-test passed"
  exit 0
fi

for path in "$@"; do
  [ -e "$path" ] || {
    echo "check_no_bundled_secrets: no such file or directory: $path" >&2
    exit 66
  }
done

found="$(scan "$@")" || exit 2
status=0
while IFS=$'\t' read -r name file; do
  [ -n "$file" ] || continue
  echo "bundled secret: $name in $file" >&2
  status=1
done <<< "$found"

if [ "$status" -ne 0 ]; then
  echo 'Release artifacts must not carry credentials; see RELEASING.md, "Provider credentials".' >&2
  exit 1
fi
echo "No bundled credentials in: $*"
