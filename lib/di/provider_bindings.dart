/// Platform seam for the "VM-backed but UI-read" provider bodies.
///
/// `providers.dart` (web-safe) DECLARES these providers, typed as a `cc_domain`
/// interface/service, and resolves each body through a `build*` factory exported
/// here. On the VM this resolves to `provider_bindings_io.dart` (the real
/// `server_providers.dart` Drift/native/CLI implementation); on web it resolves
/// to `provider_bindings_web.dart` (an honest "not available on web" stub). This
/// keeps `providers.dart` free of any VM-only import while still exposing the
/// same provider symbols to every screen.
library;

export 'provider_bindings_io.dart'
    if (dart.library.js_interop) 'provider_bindings_web.dart';
