import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/projects_table.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:drift/drift.dart';

part 'project_dao.g.dart';

/// Data access for projects. Also touches [TicketsTable] so that deleting a
/// project orphans (rather than removes) its tickets in a single transaction.
@DriftAccessor(tables: [ProjectsTable, TicketsTable])
class ProjectDao extends DatabaseAccessor<AppDatabase> with _$ProjectDaoMixin {
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

  /// Deletes a project scoped to [workspaceId] and orphans its tickets (sets
  /// their `project_id` to null) in one transaction. Scoping by `workspaceId`
  /// means a project from another workspace is not matched. Returns the number
  /// of project rows deleted.
  Future<int> deleteProject(String id, String workspaceId) {
    return transaction(() async {
      await (update(ticketsTable)
            ..where((t) =>
                t.projectId.equals(id) & t.workspaceId.equals(workspaceId)))
          .write(const TicketsTableCompanion(projectId: Value(null)));
      return (delete(projectsTable)
            ..where((p) => p.id.equals(id) & p.workspaceId.equals(workspaceId)))
          .go();
    });
  }

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
