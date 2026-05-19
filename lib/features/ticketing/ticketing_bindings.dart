/// Platform seam for the ticketing write/sync services named by the ticket UI.
///
/// The ticket write services (`TicketWorkflowService` / `TicketLinkService` /
/// `ProjectService`) are pure cc_domain logic over repository interfaces, so
/// they are DECLARED in `ticketing_providers.dart` (web-safe) and RESOLVED
/// through the `build*` factories exported here: both the VM and web bindings
/// construct them over the same RPC-flipped repositories, so ticket writes
/// genuinely happen on `cc_server` on every target. `triggerTicketSync` is an
/// honest no-op on both — the server owns the mirror, no client holds one.
library;

export 'ticketing_bindings_io.dart'
    if (dart.library.js_interop) 'ticketing_bindings_web.dart';
