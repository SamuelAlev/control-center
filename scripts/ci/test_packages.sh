#!/usr/bin/env bash
#
# CI: run package test suites with capped concurrency.
# Usage: scripts/ci/test_packages.sh
#
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

# Git Bash on windows-latest otherwise hands Flutter GNU tar, which treats
# C:\ as a remote host when unpacking SDK zips. No-op on Linux/macOS.
# shellcheck source=prefer_windows_tar.sh
. "$(dirname "${BASH_SOURCE[0]}")/prefer_windows_tar.sh"

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
