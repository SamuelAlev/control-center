import 'package:cc_persistence/database/tables/projects_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'project_dao.g.dart';

/// Data access for projects. Deleting a project leaves its tickets in place
/// (the ticket key is `SET NULL`).
@DriftAccessor(tables: [ProjectsTable])
class ProjectDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ProjectDaoMixin {
  /// Creates a [ProjectDao].
  ProjectDao(super.db);

  // --- writes ---

  /// Inserts a new project row.
  Future<void> insert(ProjectsTableCompanion project) =>
      into(projectsTable).insert(project);

  /// Updates a project, scoped to [workspaceId]. A project from another
  /// workspace is simply not matched. Returns the number of rows written.
  Future<int> updateById(
    String id,
    String workspaceId,
    ProjectsTableCompanion project,
  ) =>
      (update(projectsTable)
            ..where((p) => p.id.equals(id) & p.workspaceId.equals(workspaceId)))
          .write(project);

  /// Deletes a project scoped to [workspaceId]; its tickets stay and lose the
  /// project (`tickets.project_id` is `ON DELETE SET NULL`). Scoping by
  /// `workspaceId` means a project from another workspace is not matched.
  /// Returns the number of project rows deleted.
  Future<int> deleteProject(String id, String workspaceId) => (delete(
    projectsTable,
  )..where((p) => p.id.equals(id) & p.workspaceId.equals(workspaceId))).go();

  // --- reads ---

  /// Fetches a project by id.
  Future<ProjectsTableData?> getById(String id) =>
      (select(projectsTable)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// All projects in a workspace, newest first.
  Future<List<ProjectsTableData>> getForWorkspace(String workspaceId) =>
      (select(projectsTable)
            ..where((p) => p.workspaceId.equals(workspaceId))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

  // --- watches ---

  /// Watches all projects in a workspace, newest first.
  Stream<List<ProjectsTableData>> watchForWorkspace(String workspaceId) =>
      (select(projectsTable)
            ..where((p) => p.workspaceId.equals(workspaceId))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .watch();
}
