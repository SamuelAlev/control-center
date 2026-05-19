#!/usr/bin/env bash
# Run every workspace package's test suite under ONE runner kind.
#
# Usage: scripts/ci/test_packages.sh <dart|flutter>
#
# Packages are DISCOVERED, not listed, so a new package that ships tests cannot
# be silently left out of CI. A `flutter_test` dev_dependency is what decides
# the runner — it is exactly the question being asked ("do these tests need the
# Flutter harness?"). Everything else runs under plain `dart test`, which skips
# flutter_tester entirely and is far faster. Comments are stripped before
# matching: cc_natives is pure Dart but mentions `sdk: flutter` in a prose
# comment.
#
# Every package runs even after one fails, so a single break does not hide the
# rest; the script still exits non-zero at the end.
#
# This lives in a script rather than inline in ci.yml because two jobs run it:
# the Linux matrix on every push and PR, and the macOS/Windows matrix on the
# default branch. A copy-pasted second version of the discovery loop is a
# guarantee that the two axes eventually disagree about what CI covers.
set -uo pipefail

kind="${1:?usage: test_packages.sh <dart|flutter>}"
case "$kind" in
dart | flutter) ;;
*)
  echo "unknown runner kind: $kind" >&2
  exit 64
  ;;
esac

# The repo root, so the script works from anywhere.
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1

failed=()
ran=0
for dir in packages/*/ apps/*/; do
  pkg="${dir%/}"
  [ -d "$pkg/test" ] || continue
  [ -f "$pkg/pubspec.yaml" ] || continue
  if sed 's/#.*//' "$pkg/pubspec.yaml" | grep -qE '^[[:space:]]+flutter_test:'; then
    pkg_kind=flutter
  else
    pkg_kind=dart
  fi
  [ "$pkg_kind" = "$kind" ] || continue
  ran=$((ran + 1))
  echo "::group::$pkg"
  if (cd "$pkg" && "$kind" test --concurrency=2); then
    echo "PASS $pkg"
  else
    echo "FAIL $pkg"
    failed+=("$pkg")
  fi
  echo "::endgroup::"
done

# A discovery bug would otherwise pass as a silently empty green job.
if [ "$ran" -eq 0 ]; then
  echo "No $kind packages discovered — discovery is broken."
  exit 1
fi
echo "Ran $ran $kind package(s)."
if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed: ${failed[*]}"
  exit 1
fi
