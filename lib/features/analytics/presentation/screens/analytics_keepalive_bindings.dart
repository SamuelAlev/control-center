/// Platform seam for the analytics-snapshot aggregator keepalive.
///
/// The aggregator rolls up the local analytics database (desktop-only), so the
/// analytics screen keeps it alive via this seam: a real watch on the VM, a
/// no-op on web (no local DB) — keeping the VM-only provider off the web graph.
library;

export 'analytics_keepalive_bindings_io.dart'
    if (dart.library.js_interop) 'analytics_keepalive_bindings_web.dart';
