/// Web side of the `provider.dart` database/DAO seam.
///
/// Intentionally empty: the web build owns no Drift database, and no
/// web-reachable code references the DAO/database providers (they are read only
/// by the VM-only composition root and the server/remote-control providers,
/// which are excluded from the web graph). Naming a single DAO type here would
/// drag `cc_persistence` (drift + sqlite3, `dart:ffi`) into the web compilation
/// graph and break `flutter build web`, which is exactly what the seam avoids.
library;
