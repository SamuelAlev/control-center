/// Pure-Dart persistence layer for Control Center.
///
/// Holds the Drift schema — `AppDatabase`, all tables and DAOs, the migration
/// steps — plus the connection factories. It depends only on `drift` +
/// `sqlite3` + `cc_domain` (no Flutter, no `path_provider`), so the SAME
/// database runs on the Flutter desktop app (which injects
/// `openDesktopConnection()`) and on a `dart build cli` headless server (which
/// injects `openServerDatabase(dataDir:)`).
library;

export 'database/app_database.dart';
export 'database/daos/daos.dart';
export 'database/migration_steps.dart';
export 'repositories/repositories.dart';
export 'src/log/cc_persistence_log.dart';
export 'src/server_database.dart';
