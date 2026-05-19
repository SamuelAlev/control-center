#!/usr/bin/env bash
# Regenerate the isolate_manager Web Workers.
#
# Compiles every `@isolateManagerWorker` / `@isolateManagerCustomWorker`
# function under lib/ to `web/<workerName>.js` via `dart compile js`. Run this
# after adding or editing any worker entry function or the (Flutter-free) code
# it pulls in — the same discipline as build_runner for *.g.dart. The generated
# `web/*.js` are committed so `flutter build web` needs no code generator.
#
# The generator (`isolate_manager_generator`) is intentionally NOT a
# dev_dependency: it pins `analyzer ^10`, which conflicts with mockito's
# `analyzer ^13`. So it runs via `dart pub global` in its own resolution.
set -euo pipefail

cd "$(dirname "$0")/.."

# Prefer the repo-pinned SDK (fvm) when present; fall back to bare dart (CI).
if command -v fvm >/dev/null 2>&1 && [ -f .fvmrc ]; then
  DART="fvm dart"
else
  DART="dart"
fi

if ! $DART pub global list 2>/dev/null | grep -q '^isolate_manager_generator '; then
  echo "==> Activating isolate_manager_generator (build-time only)…"
  $DART pub global activate isolate_manager_generator
fi

echo "==> Generating Web Workers (lib -> web)…"
$DART pub global run isolate_manager_generator:isolate_manager_generator \
  --input lib --output web --single

# Drop the dart2js sidecars: `.deps` lists absolute local input paths (noise +
# a minor path leak if deployed) and `.map` is a large source map. Only the
# `.js` is committed and served. Re-run with the generator's --debug to keep them.
rm -f web/*.js.deps web/*.js.map

# Install shiki_flutter's prebuilt tokenize Web Worker (grammar-free, ~53KB
# gz, deterministic copy from the package — no network, no codegen). It backs
# `asyncWeb` highlighting for markdown/preview surfaces; if the asset is
# missing at runtime, shiki falls back to inline main-thread tokenization.
echo "==> Installing shiki tokenize worker…"
$DART run shiki_flutter:install

echo "==> Done. Committed artifact(s):"
ls -1 web/*.js 2>/dev/null || true
