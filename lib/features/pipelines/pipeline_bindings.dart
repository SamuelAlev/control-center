/// Platform seam for the pipeline engine named by the pipeline UI.
///
/// The engine is the server-side pipeline EXECUTOR (it owns run-state and drives
/// the dispatch stack), so `pipelineEngineProvider` is DECLARED in
/// `pipeline_providers.dart` (typed as the web-safe `PipelineEnginePort`) and
/// RESOLVED through the `buildPipelineEngine` factory exported here: the real
/// engine on the VM, an honest "not available on web" stub on web.
library;

export 'pipeline_bindings_io.dart'
    if (dart.library.js_interop) 'pipeline_bindings_web.dart';
