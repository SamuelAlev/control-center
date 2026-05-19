import 'package:drift/drift.dart';

/// Drift table for projects — a workspace-scoped grouping of tickets (e.g.
/// "Make auth work", "Go-to-market"). A Control-Center-only concept: projects
/// are local metadata and are never pushed to a remote ticket provider.
///
/// Tickets reference a project through `tickets.project_id` (nullable, set to
/// null when the project is deleted), so deleting a project orphans its tickets
/// rather than removing them.
@TableIndex(name: 'idx_projects_workspace_status', columns: {#workspaceId, #status})
class ProjectsTable extends Table {
  /// Unique project id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Short human-readable name.
  TextColumn get name => text()();

  /// Optional longer description / goal.
  TextColumn get description => text().nullable()();

  /// Color token key (see `ProjectColor`). Paired with the name in the UI —
  /// never status-by-color-alone.
  TextColumn get color => text().withDefault(const Constant('gray'))();

  /// Lifecycle status: `active` | `completed` | `archived`.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'projects';

  @override
  Set<Column> get primaryKey => {id};
}
