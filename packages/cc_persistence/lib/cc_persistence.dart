/// Pure-Dart persistence layer for Control Center.
///
/// Holds the Drift schema in two halves — `GlobalDatabase` (`global.db`: the
/// workspace registry, identity, repos-free server state, the fleet queue) and
/// `WorkspaceDatabase` (one `workspaces/<id>.db` per workspace, holding
/// everything else) — plus all tables, DAOs and the connection factories.
///
/// Splitting the file is what makes workspace isolation structural instead of a
/// WHERE-clause convention: a `WorkspaceDatabase` does not declare another
/// workspace's tables, so a cross-workspace read does not compile.
/// `WorkspaceDatabaseManager` hands out the per-workspace databases and
/// `CrossWorkspaceQueries` is the only sanctioned way to span them.
///
/// It depends only on `drift` + `sqlite3` + `cc_domain` (no Flutter, no
/// `path_provider`), so it runs inside a `dart build cli` headless server
/// binary.
library;

// `Value` is drift's insert-token type every companion field wraps, so it is
// part of the public insertion API. Re-exporting it lets consumers build
// companions (e.g. seeding a workspace in an integration test) without taking a
// direct `package:drift` dependency — the desktop/web app must NOT import drift.
export 'package:drift/drift.dart' show Value;

export 'database/cross_workspace_queries.dart';
export 'database/daos/daos.dart';
export 'database/database_backup_service.dart';
export 'database/database_retention_service.dart';
export 'database/global/global_database.dart';
export 'database/migration_steps.dart';
export 'database/tables/server_meta_table.dart';
export 'database/tables/workspace_meta_table.dart';
export 'database/tables/workspace_routes_table.dart';
export 'database/workspace/workspace_database.dart';
export 'database/workspace_database_manager.dart';
export 'repositories/repositories.dart';
export 'src/log/cc_persistence_log.dart';
export 'src/server_database.dart';
