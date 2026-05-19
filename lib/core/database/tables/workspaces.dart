import 'package:drift/drift.dart';

/// Drift table definition for workspaces.
///
/// A workspace is a user-named container with an optional custom logo. It is
/// decoupled from any specific repository — see `repos` and `workspace_repos`
/// for the many-to-many link.
class WorkspacesTable extends Table {
  /// Unique workspace identifier.
  TextColumn get id => text()();

  /// Workspace display name (user-supplied at creation).
  TextColumn get name => text()();

  /// Optional path to a local image file used as the workspace logo.
  TextColumn get logoPath => text().nullable()();

  /// Default fan-out for parallel reviewer dispatch on this workspace.
  /// `dispatch_reviewers` MCP tool uses this when no explicit `concurrency`
  /// argument is provided.
  IntColumn get reviewConcurrency =>
      integer().withDefault(const Constant(3))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last update timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  /// Soft-delete timestamp. When non-null, the workspace is considered deleted.
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  String get tableName => 'workspaces';

  @override
  Set<Column> get primaryKey => {id};
}
