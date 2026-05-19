#!/usr/bin/env bash
# Drift guard: fail if the committed web/*.js Web Workers are out of sync with
# the worker source under lib/. Regenerates into a temp dir and diffs against
# the committed artifacts, so it never mutates the working tree.
#
# Complements test/tooling/web_workers_test.dart (which asserts every annotated
# worker has *some* committed asset); this catches a stale asset whose source
# changed without a `tool/gen_workers.sh` re-run.
set -euo pipefail

cd "$(dirname "$0")/.."

if command -v fvm >/dev/null 2>&1 && [ -f .fvmrc ]; then
  DART="fvm dart"
else
  DART="dart"
fi

if ! $DART pub global list 2>/dev/null | grep -q '^isolate_manager_generator '; then
  $DART pub global activate isolate_manager_generator
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

$DART pub global run isolate_manager_generator:isolate_manager_generator \
  --input lib --output "$TMP" --single >/dev/null

status=0
for f in "$TMP"/*.js; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  if ! cmp -s "$f" "web/$name"; then
    echo "DRIFT: web/$name differs from freshly generated output." >&2
    status=1
  fi
done

# The shiki tokenize worker is a prebuilt asset copied verbatim from the
# resolved package (tool/gen_workers.sh runs `dart run shiki_flutter:install`).
# Byte-compare against the package so a shiki upgrade can't silently leave a
# stale copy in web/.
SHIKI_ROOT="$(python3 -c '
import json
try:
    d = json.load(open(".dart_tool/package_config.json"))
    uri = next(p["rootUri"] for p in d["packages"] if p["name"] == "shiki_flutter")
    print(uri.removeprefix("file://") if uri.startswith("file://") else "")
except (OSError, StopIteration, KeyError):
    print("")
' 2>/dev/null || true)"
if [ -n "$SHIKI_ROOT" ] && [ -f "$SHIKI_ROOT/lib/src/async/web/prebuilt/shiki_tokenize_worker.js" ]; then
  if ! cmp -s "$SHIKI_ROOT/lib/src/async/web/prebuilt/shiki_tokenize_worker.js" \
      "web/shiki_tokenize_worker.js"; then
    echo "DRIFT: web/shiki_tokenize_worker.js differs from the shiki_flutter package prebuilt." >&2
    status=1
  fi
else
  echo "WARN: could not resolve shiki_flutter package root; skipping shiki worker check." >&2
fi

if [ "$status" -ne 0 ]; then
  echo "" >&2
  echo "Web Workers are stale. Run: tool/gen_workers.sh, then commit web/*.js" >&2
  exit 1
fi

echo "Web Workers are up to date."
