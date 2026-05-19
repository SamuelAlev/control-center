/// Selects the platform's database/DAO provider graph.
///
/// Intentionally empty on BOTH targets: the desktop and web are both thin
/// clients that own no database and reach all data over `rpcClientProvider`
/// (the connected `cc_server`). Neither `provider_io.dart` nor
/// `provider_web.dart` references `cc_persistence` — keeping this seam means
/// any future code that genuinely needs a local DAO graph has an obvious,
/// already-load-bearing place to plug it back in.
library;

export 'provider_io.dart' if (dart.library.js_interop) 'provider_web.dart';
