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

# The REVERSE direction: a worker that was removed or renamed leaves its stale
# committed `web/<old>.js` behind forever, and the loop above never looks at
# files the generator no longer produces. A stale worker asset is dead weight
# in every web bundle and, worse, reads as a live worker to anyone grepping.
#
# Only generator-produced names are checked; hand-maintained and copied assets
# (diffWorker.js is compiled by tool/gen_workers.sh, the shiki worker is copied
# from the package) are listed here so they are never mistaken for orphans.
KNOWN_NON_GENERATED="diffWorker.js shiki_tokenize_worker.js flutter_service_worker.js"
for f in web/*.js; do
  [ -e "$f" ] || continue
  name="$(basename "$f")"
  case " $KNOWN_NON_GENERATED " in
    *" $name "*) continue ;;
  esac
  if [ ! -e "$TMP/$name" ]; then
    echo "ORPHAN: web/$name is no longer produced by the generator." >&2
    echo "  Delete it, or add it to KNOWN_NON_GENERATED in $0 if it is a" >&2
    echo "  hand-maintained/copied asset." >&2
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
