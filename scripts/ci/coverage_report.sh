#!/usr/bin/env bash
# Produce a per-package line-coverage report for the whole workspace.
#
# Usage: scripts/ci/coverage_report.sh [output-dir]
#
# NON-GATING BY DESIGN. Coverage was deliberately unmeasured because nothing
# consumed it (ci.yml says so where it drops `--coverage`), and that is a
# defensible call for a merge gate — a percentage threshold rewards testing the
# easy half. It is not a defensible call for VISIBILITY: with 20 workspace
# members and no number anywhere, a package with no tests at all
# (`cc_remote`) looks exactly like a package with good ones. This script prints
# the number and stops. It never fails on a threshold.
#
# Both runners are handled: `flutter test --coverage` writes lcov directly,
# while `dart test --coverage=<dir>` writes raw JSON that `format_coverage`
# (package:coverage, activated globally rather than added as a dev_dependency
# to 17 pubspecs) turns into the same shape.
set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 1
out_dir="${1:-build/coverage}"
mkdir -p "$out_dir"

have_format_coverage=0
if command -v format_coverage >/dev/null 2>&1; then
  have_format_coverage=1
fi

# `lines found` / `lines hit` out of an lcov file, as "hit found".
lcov_totals() {
  awk -F: '
    /^LF:/ { found += $2 }
    /^LH:/ { hit   += $2 }
    END    { printf "%d %d\n", hit + 0, found + 0 }
  ' "$1"
}

rows=()
total_hit=0
total_found=0

for dir in packages/*/ apps/*/ .; do
  pkg="${dir%/}"
  [ "$pkg" = "." ] && pkg="(root app)"
  src="${dir%/}"
  [ -d "$src/test" ] || continue
  [ -f "$src/pubspec.yaml" ] || continue

  if sed 's/#.*//' "$src/pubspec.yaml" | grep -qE '^[[:space:]]+flutter_test:'; then
    kind=flutter
  else
    kind=dart
  fi

  echo "::group::coverage $pkg ($kind)"
  lcov="$src/coverage/lcov.info"
  rm -f "$lcov"

  if [ "$kind" = flutter ]; then
    (cd "$src" && flutter test --concurrency=2 --coverage) || true
  else
    (cd "$src" && dart test --concurrency=2 --coverage=coverage) || true
    if [ "$have_format_coverage" = 1 ] && [ -d "$src/coverage" ]; then
      (cd "$src" && format_coverage \
        --lcov --in=coverage --out=coverage/lcov.info \
        --report-on=lib --packages=.dart_tool/package_config.json) || true
    fi
  fi
  echo "::endgroup::"

  if [ ! -f "$lcov" ]; then
    rows+=("$pkg|—|no coverage produced")
    continue
  fi
  read -r hit found <<<"$(lcov_totals "$lcov")"
  cp "$lcov" "$out_dir/$(echo "$pkg" | tr '/ ()' '____').lcov"
  if [ "$found" -eq 0 ]; then
    rows+=("$pkg|—|no instrumented lines")
    continue
  fi
  pct=$(awk -v h="$hit" -v f="$found" 'BEGIN { printf "%.1f", (h * 100.0) / f }')
  total_hit=$((total_hit + hit))
  total_found=$((total_found + found))
  rows+=("$pkg|${pct}%|$hit / $found lines")
done

summary="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
{
  echo "## Line coverage"
  echo
  echo "Informational only — nothing here gates a merge."
  echo
  echo "| Package | Coverage | Lines |"
  echo "| --- | ---: | ---: |"
  for row in "${rows[@]}"; do
    IFS='|' read -r a b c <<<"$row"
    echo "| \`$a\` | $b | $c |"
  done
  if [ "$total_found" -gt 0 ]; then
    overall=$(awk -v h="$total_hit" -v f="$total_found" \
      'BEGIN { printf "%.1f", (h * 100.0) / f }')
    echo
    echo "**Workspace total: ${overall}%** ($total_hit / $total_found lines)"
  fi
} >>"$summary"

echo "Wrote lcov files to $out_dir"
