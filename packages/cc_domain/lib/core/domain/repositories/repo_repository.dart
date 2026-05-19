import 'package:cc_domain/core/domain/entities/repo.dart';

/// Repository interface for repo data access.
///
/// Repos are **workspace-scoped**: a checkout is registered into one workspace,
/// and every method therefore takes a required `workspaceId`. A repo id is
/// meaningful only inside its workspace — the same checkout added to two
/// workspaces is two rows with two ids and identity across workspaces is by
/// path (see [findByPath]).
abstract class RepoRepository {
  /// Watches [workspaceId]'s repos in the operator's manual drag-to-reorder
  /// order. This is the order every repo list in the product renders.
  Stream<List<Repo>> watchAll(String workspaceId);

  /// Returns [workspaceId]'s repos in the same order as [watchAll].
  Future<List<Repo>> getAll(String workspaceId);

  /// Returns the repo [repoId] within [workspaceId], or `null`.
  ///
  /// A repo id belonging to another workspace simply does not resolve.
  Future<Repo?> getById(String workspaceId, String repoId);

  /// Returns the repo registered at [path] within [workspaceId], or `null`.
  ///
  /// This is how "is this checkout already here?" is answered, since ids are
  /// per-workspace.
  Future<Repo?> findByPath(String workspaceId, String path);

  /// Whether [repoId] belongs to [workspaceId].
  ///
  /// The isolation gate for repo-scoped operations (e.g. the code-graph tools)
  /// before exposing a repo's data to a caller that supplied a workspace id.
  Future<bool> exists(String workspaceId, String repoId);

  /// Inserts or updates a repo in [workspaceId]. Returns the repo id.
  ///
  /// A newly inserted repo appends to the end of the manual order; an update
  /// leaves the order untouched.
  Future<String> upsert(String workspaceId, Repo repo);

  /// Removes [repoId] from [workspaceId], cascading its code-index rows,
  /// space links and isolated checkouts.
  Future<void> delete(String workspaceId, String repoId);

  /// Re-sequences [workspaceId]'s repos to match [orderedIds] — the
  /// drag-to-reorder write path behind [watchAll]'s order. Ids the workspace
  /// does not own are ignored.
  Future<void> reorder(String workspaceId, List<String> orderedIds);
}
