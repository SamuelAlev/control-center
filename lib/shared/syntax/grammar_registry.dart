// The main-side grammar registry: which shiki grammars the running platform
// can tokenize with, and how to make one available.
//
// - Native (io): every bundled grammar is resident (`CodeLanguages.all`),
//   `ensureLanguageAvailable` completes synchronously true.
// - Web: the curated tier is resident; the rest arrive via deferred grammar
//   packs (loaded on demand by `ensureLanguageAvailable`).
//
// The diff worker does NOT use this module — it has its own eager-only pair
// (worker_grammars.dart) because deferred imports cannot enter the
// single-file `dart compile js` worker bundle.
//
// FLUTTER-FREE ON PURPOSE (pure Dart, engine types only).

export 'grammar_registry_io.dart'
    if (dart.library.js_interop) 'grammar_registry_web.dart';
