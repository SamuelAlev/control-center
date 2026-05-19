/// Selects the platform's database/DAO provider graph.
///
/// On the VM (desktop) this exports the real Drift [databaseProvider] and the
/// full set of DAO providers (`provider_io.dart`), which pull `cc_persistence`
/// (drift + sqlite3, `dart:ffi`). On web it exports nothing (`provider_web.dart`
/// is empty): the web build owns no database and reaches data over RPC, so no
/// web-reachable code references these symbols — the only importers (the
/// composition root's VM half + the VM-only server/remote-control providers)
/// are themselves excluded from the web graph via the `di/providers.dart` seam.
library;

export 'provider_io.dart'
    if (dart.library.js_interop) 'provider_web.dart';
