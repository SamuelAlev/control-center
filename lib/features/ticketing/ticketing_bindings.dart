/// Platform seam for the ticketing write/sync services named by the ticket UI.
///
/// The ticket write services (`TicketWorkflowService` / `TicketLinkService` /
/// `ProjectService`) are pure cc_domain logic over repository interfaces, so
/// they are DECLARED in `ticketing_providers.dart` (web-safe) and RESOLVED
/// through the `build*` factories exported here: on the VM they bind to the
/// server-side Drift `dao*` repositories (the in-process host owns the DB and
/// drives the MCP write path); on web they bind to the RPC-flipped repositories
/// so ticket writes work over RPC. `triggerTicketSync` runs the remote→local
/// pull on the VM and is a no-op on web (the server owns the mirror).
library;

export 'ticketing_bindings_io.dart'
    if (dart.library.js_interop) 'ticketing_bindings_web.dart';
