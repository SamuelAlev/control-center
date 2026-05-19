/// Platform seam for the orchestration approve/cancel actions invoked by the
/// proposal bubble's notifier.
///
/// The actions are server-side execution (hire agents, start/cancel pipelines),
/// so they run the real use cases on the VM and throw an honest "not available
/// on web" error on web — keeping the VM-only orchestration server providers
/// (dao* + concrete `PipelineEngine`) off the web compile graph.
library;

export 'orchestration_action_bindings_io.dart'
    if (dart.library.js_interop) 'orchestration_action_bindings_web.dart';
