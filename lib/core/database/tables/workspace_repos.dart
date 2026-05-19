import 'package:drift/drift.dart';

/// Many-to-many join between workspaces and repos.
///
/// A row `(workspaceId, repoId)` declares that the workspace targets that
/// repository. Deleting either side cascades to remove the link.
class WorkspaceReposTable extends Table {
  /// Workspace side of the link.
  TextColumn get workspaceId => text().customConstraint(
    'NOT NULL REFERENCES workspaces (id) ON DELETE CASCADE',
  )();

  /// Repo side of the link.
  TextColumn get repoId => text().customConstraint(
    'NOT NULL REFERENCES repos (id) ON DELETE CASCADE',
  )();

  /// When the link was created (drives ordering in repo pickers).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'workspace_repos';

  @override
  Set<Column> get primaryKey => {workspaceId, repoId};
}
