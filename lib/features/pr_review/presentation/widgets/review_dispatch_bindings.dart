/// Platform seam for dispatching an agent to address PR review findings.
///
/// Dispatch spawns a local sandboxed agent process, so it runs the real
/// `AgentDispatchService` on the VM and throws an honest "not available on web"
/// error on web — keeping the VM-only dispatch stack off the web compile graph.
library;

export 'review_dispatch_bindings_io.dart'
    if (dart.library.js_interop) 'review_dispatch_bindings_web.dart';
