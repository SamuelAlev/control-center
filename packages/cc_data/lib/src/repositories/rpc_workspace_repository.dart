import 'package:cc_data/src/repositories/remote_workspace_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [WorkspaceRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `workspace.*` ops + the
/// `workspace.watchAll` / `workspace.watchReposForWorkspace` subscriptions,
/// mapping the [WorkspaceDto] / [RepoDto] wire shapes back to entities. The host
/// owns persistence; this client never touches a database.
///
/// The workspace entity is itself the unit of isolation, so its CRUD + the
/// switcher list legitimately span workspaces (the `create_workspace` /
/// `list_workspaces` exemptions). Every repo read and write names its workspace
/// explicitly, because repos live inside one.
class RpcWorkspaceRepository implements WorkspaceRepository {
  /// Creates an [RpcWorkspaceRepository] over [client].
  RpcWorkspaceRepository(RemoteRpcClient client)
    : _remote = RemoteWorkspaceRepository(client);

  final RemoteWorkspaceRepository _remote;

  /// Rebuilds a [Workspace] from its wire DTO. A workspace name must be
  /// non-empty (entity invariant); missing timestamps fall back to the epoch.
  ///
  /// [Workspace.secretExcludeGlobs] MUST be carried in both directions.
  /// `WorkspaceDto.toJson` writes `secret_exclude_globs` unconditionally (unlike
  /// its null-guarded neighbours) and the host decodes a missing/empty list as
  /// "no custom exclusions" — so dropping it here does not merely omit the
  /// field, it makes every client-side `workspace.upsert` (a rename, a new logo)
  /// send `[]` and wipe the operator's secret-path exclusions for viewers and
  /// guests.
  static Workspace _workspaceFromDto(WorkspaceDto d) => Workspace(
    id: d.id,
    name: d.name,
    logoPath: d.logoPath,
    ownerUserId: d.ownerUserId,
    secretExcludeGlobs: d.secretExcludeGlobs,
    reviewConcurrency: d.reviewConcurrency ?? 3,
    autoPublishReview: d.autoPublishReview ?? false,
    deletedAt: d.deletedAt,
    createdAt: d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        d.updatedAt ?? d.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Maps an entity back to the wire shape.
  ///
  /// [Workspace.ownerUserId] is deliberately NOT sent: the host stamps it on
  /// create and carries the stored value over on update, so ownership stays
  /// server-authoritative and a client never asserts who owns a workspace.
  /// [Workspace.secretExcludeGlobs] IS sent and must be — see above.
  static WorkspaceDto _toDto(Workspace w) => WorkspaceDto(
    id: w.id,
    name: w.name,
    logoPath: w.logoPath,
    secretExcludeGlobs: w.secretExcludeGlobs,
    reviewConcurrency: w.reviewConcurrency,
    autoPublishReview: w.autoPublishReview,
    deletedAt: w.deletedAt,
    createdAt: w.createdAt,
    updatedAt: w.updatedAt,
  );

  static Repo _repoFromDto(RepoDto d) => Repo(
    id: d.id,
    name: d.name,
    path: d.path,
    remoteOwner: d.remoteOwner,
    remoteName: d.remoteName,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
    updatedAt: d.updatedAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.updatedAt!),
  );

  @override
  Stream<List<Workspace>> watchAll() =>
      _remote.watchAll().map((dtos) => dtos.map(_workspaceFromDto).toList());

  @override
  Future<List<Workspace>> getAll() => watchAll().first;

  @override
  Future<Workspace?> getById(String id) async {
    final all = await getAll();
    for (final w in all) {
      if (w.id == id) {
        return w;
      }
    }
    return null;
  }

  @override
  Future<String> upsert(Workspace workspace) =>
      _remote.upsert(_toDto(workspace));

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) =>
      _remote.reorderWorkspaces(orderedIds);

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) => _remote
      .watchReposForWorkspace(workspaceId)
      .map((dtos) => dtos.map(_repoFromDto).toList());

  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      _remote.setReposForWorkspace(workspaceId, repoIds);

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      _remote.isRepoLinkedToWorkspace(workspaceId, repoId);

  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      _remote.unlinkRepoFromWorkspace(workspaceId, repoId);
}
