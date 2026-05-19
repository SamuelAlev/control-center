import 'package:cc_domain/features/ticketing/domain/entities/project.dart';

/// Persistence boundary for projects (workspace-scoped groupings of tickets).
abstract interface class ProjectRepository {
  /// Inserts a new project.
  Future<void> insert(Project project);

  /// Updates a project, scoped to its workspace. Returns the rows written.
  Future<int> update(Project project);

  /// Deletes a project and orphans its tickets (their `projectId` is cleared),
  /// scoped to [workspaceId]. A project from another workspace is not matched.
  /// Returns the number of project rows deleted.
  Future<int> delete(String projectId, {required String workspaceId});

  /// Fetches a project by id, or null.
  Future<Project?> getById(String id);

  /// All projects in a workspace, newest first.
  Future<List<Project>> getForWorkspace(String workspaceId);

  /// Watches all projects in a workspace, newest first.
  Stream<List<Project>> watchForWorkspace(String workspaceId);
}
