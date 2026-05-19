/// Desktop side of the `provider.dart` database/DAO seam.
///
/// Intentionally empty: the desktop is a thin client exactly like web — it
/// opens no Drift database, it spawns/connects to a `cc_server` that owns the
/// data and reaches it exclusively over `rpcClientProvider`. Naming a single
/// DAO type here would drag `cc_persistence` (drift + sqlite3, `dart:ffi`)
/// into the desktop compilation graph, which is exactly what the seam avoids
/// — mirroring why `provider_web.dart` is empty for the web build.
library;
