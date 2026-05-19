import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';

/// Repository interface for workspace data access.
///
/// Features depend on this interface rather than on the DAOs directly, enabling
/// testability and future implementation swaps.
///
/// It spans both halves of the split database, and it is the only repository
/// that does. The workspace *registry* (name, logo, order, owner) is global so
/// the switcher can list every workspace without opening a single workspace
/// file; a workspace's repos live inside that workspace's own file. Callers ask
/// a workspace question and get an answer — which file it came from is the
/// implementation's business.
abstract class WorkspaceRepository {
  /// Watches all workspaces in the operator's manual order (the sequence set by
  /// drag-to-reorder in "manage workspaces"). Every workspace list in the
  /// product — switcher popover, manager rail, phone picker — renders this
  /// order, so it is stable across clients.
  Stream<List<Workspace>> watchAll();

  /// Returns all live workspaces in the same order as [watchAll], for one-shot
  /// readers (startup resolvers, the phone's picker, maintenance fan-out).
  Future<List<Workspace>> getAll();

  /// Returns a single workspace by [id], or `null` when it does not exist or has
  /// been soft-deleted.
  Future<Workspace?> getById(String id);

  /// Upserts a workspace row. Returns the workspace id. A newly created
  /// workspace appends to the end of the manual order; an update leaves the
  /// order untouched.
  ///
  /// Creating a workspace also materialises its database file, so the schema
  /// exists before any reader touches it.
  Future<String> upsert(Workspace workspace);

  /// Soft-deletes the workspace [id] and drops its database file.
  Future<void> delete(String id);

  /// Re-sequences the workspaces to match [orderedIds] — the drag-to-reorder
  /// write path behind [watchAll]'s order. Callers pass the full displayed
  /// list.
  Future<void> reorderWorkspaces(List<String> orderedIds);

  /// Watches the repos belonging to [workspaceId], in the operator's manual
  /// drag-to-reorder order.
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId);

  /// Re-sequences [workspaceId]'s repos to match [repoIds] — the
  /// drag-to-reorder write path behind [watchReposForWorkspace]'s order.
  ///
  /// Ids the workspace does not own are ignored: a repo cannot be conjured from
  /// an id, because ids are per-workspace. Repos are registered from a path
  /// (`RepoRepository.upsert` / the `repos.addFromPath` op).
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds);

  /// Whether [repoId] belongs to [workspaceId]. Used to enforce workspace
  /// isolation before exposing repo-scoped data (e.g. the code graph) to a
  /// caller operating in a given workspace.
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId);

  /// Removes [repoId] from [workspaceId], cascading its code-index rows,
  /// channel links and isolated checkouts.
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId);
}
