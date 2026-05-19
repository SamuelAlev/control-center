// Grammar surface of the PR-diff worker core. A SEPARATE pair from
// grammar_registry.dart on purpose: the worker is compiled to a single-file
// JS bundle (`dart compile js` via isolate_manager, `--single`), where
// deferred imports must never appear — so the worker always resolves from an
// eager set. Native worker isolates share the app binary and index
// `CodeLanguages.all`; the web worker bundle carries the curated tier.
//
// FLUTTER-FREE ON PURPOSE (enforced by the "Web Worker cores are
// Flutter-free" group in test/core/architecture_constraints_test.dart).

export 'worker_grammars_io.dart'
    if (dart.library.js_interop) 'worker_grammars_web.dart';
