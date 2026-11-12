/// Pure-Dart persistence: `GlobalDatabase` (`global.db`) + one
/// `WorkspaceDatabase` per `<dataDir>/<workspaceId>/workspace.db` and its
/// `CodeIndexDatabase` (`code_index.db` beside it), plus tables, DAOs and
/// connection factories.
///
/// Isolation is structural — a workspace DB does not declare another
/// workspace's tables. Repositories resolve DAOs via
/// `WorkspaceDatabaseManager` per call (never cache a DAO).
library;

// `Value` is drift's insert-token type every companion field wraps, so it is
// part of the public insertion API. Re-exporting it lets consumers build
// companions (e.g. seeding a workspace in an integration test) without taking a
// direct `package:drift` dependency — the desktop/web app must NOT import drift.
export 'package:drift/drift.dart' show Value;

export 'database/code_index/code_index_database.dart';
export 'database/cross_workspace_queries.dart';
export 'database/daos/daos.dart';
export 'database/database_backup_service.dart';
export 'database/database_retention_service.dart';
export 'database/global/global_database.dart';
export 'database/schema/converged_database.dart';
export 'database/schema/schema_converge.dart';
export 'database/tables/server_meta_table.dart';
export 'database/tables/workspace_meta_table.dart';
export 'database/tables/workspace_routes_table.dart';
export 'database/workspace/workspace_database.dart';
export 'database/workspace_database_manager.dart';
export 'database/workspace_route_reconciler.dart';
export 'repositories/repositories.dart';
export 'src/log/cc_persistence_log.dart';
export 'src/server_database.dart';
