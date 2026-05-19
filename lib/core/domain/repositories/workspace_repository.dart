import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';

/// Repository interface for workspace data access.
///
/// Features depend on this interface rather than on WorkspaceDao directly,
/// enabling testability and future implementation swaps.
abstract class WorkspaceRepository {
  /// Watches all workspaces ordered by update time.
  Stream<List<Workspace>> watchAll();

  /// Upserts a workspace row. Returns the workspace id.
  Future<String> upsert(Workspace workspace);

  /// Deletes a workspace by [id].
  Future<void> delete(String id);

  /// Watches the repos linked to [workspaceId], oldest link first.
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId);

  /// Atomically replaces the set of repos linked to [workspaceId] with
  /// [repoIds].
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds);

  /// Whether [repoId] is currently linked to [workspaceId]. Used to enforce
  /// workspace isolation before exposing repo-scoped data (e.g. the code graph)
  /// to an agent operating in a given workspace.
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId);

  /// Links [repoId] to [workspaceId] (idempotent).
  Future<void> linkRepoToWorkspace(String workspaceId, String repoId);

  /// Removes the link between [workspaceId] and [repoId], if any.
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId);
}
