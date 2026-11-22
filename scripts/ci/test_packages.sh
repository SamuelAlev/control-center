#!/usr/bin/env bash
#
# CI: run package test suites with capped concurrency.
# Usage: scripts/ci/test_packages.sh <dart|flutter> [all|rest|<package dir>]
#
# The shard picks which packages of that kind run:
#   all (default)  every package
#   <package dir>  one of the packages in own_job below, alone
#   rest           every package NOT in own_job, so a new package always runs
#
set -uo pipefail

kind="${1:?usage: test_packages.sh <dart|flutter> [all|rest|<package dir>]}"
shard="${2:-all}"
case "$kind" in
dart | flutter) ;;
*)
  echo "unknown runner kind: $kind" >&2
  exit 64
  ;;
esac

# Suites slow enough to get a CI job each (about 4 min apiece on Linux, as
# long as every other dart package together). ci.yml lists the same dirs.
own_job=(packages/cc_infra packages/cc_server_core)

in_own_job() {
  local candidate
  for candidate in "${own_job[@]}"; do
    [ "$candidate" = "$1" ] && return 0
  done
  return 1
}

case "$shard" in
all | rest) ;;
*)
  if ! in_own_job "$shard"; then
    echo "unknown shard: $shard (expected all, rest or one of: ${own_job[*]})" >&2
    exit 64
  fi
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
  case "$shard" in
  all) ;;
  rest) in_own_job "$pkg" && continue ;;
  *) [ "$pkg" = "$shard" ] || continue ;;
  esac
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
  echo "No $kind packages discovered for shard $shard — discovery is broken."
  exit 1
fi
echo "Ran $ran $kind package(s) (shard $shard)."
if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed: ${failed[*]}"
  exit 1
fi
