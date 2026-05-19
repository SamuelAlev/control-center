/// Platform seam for the on-device embedding model (service + lifecycle).
///
/// The embedding model is on-device inference (cc_natives FFI — `dart:ffi`,
/// which dart2js cannot compile) cached to the local app-support directory. So
/// `embeddingServiceProvider` + `embeddingModelStateProvider` resolve their
/// implementations through this seam: the real cc_natives service + the
/// download/probe controller on the VM, honest "not available on web" stubs on
/// web (the controller reports a permanent desktop-only state).
library;

export 'embedding_state_bindings_io.dart'
    if (dart.library.js_interop) 'embedding_state_bindings_web.dart';
