import 'package:cc_data/src/repositories/remote_repo_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [RepoRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's workspace-scoped `repos.*`
/// ops + the `repos.watchAll` subscription, mapping [RepoDto] back to [Repo].
/// The host owns persistence; this client never touches a database.
class RpcRepoRepository implements RepoRepository {
  /// Creates an [RpcRepoRepository] over [client].
  RpcRepoRepository(RemoteRpcClient client)
    : _remote = RemoteRepoRepository(client);

  final RemoteRepoRepository _remote;

  static Repo _fromDto(RepoDto d) {
    DateTime parse(String? iso) => iso == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(iso);
    return Repo(
      id: d.id,
      name: d.name,
      path: d.path,
      githubOwner: d.githubOwner,
      githubRepoName: d.githubRepoName,
      createdAt: parse(d.createdAt),
      updatedAt: parse(d.updatedAt),
    );
  }

  static RepoDto _toDto(Repo r) => RepoDto(
    id: r.id,
    name: r.name,
    path: r.path,
    githubOwner: r.githubOwner,
    githubRepoName: r.githubRepoName,
    createdAt: r.createdAt.toIso8601String(),
    updatedAt: r.updatedAt.toIso8601String(),
  );

  @override
  Stream<List<Repo>> watchAll(String workspaceId) =>
      _remote.watchAll(workspaceId).map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<Repo>> getAll(String workspaceId) => _remote
      .watchAll(workspaceId)
      .first
      .then((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async {
    try {
      final dto = await _remote.get(workspaceId, repoId);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<Repo?> findByPath(String workspaceId, String path) async {
    final dto = await _remote.findByPath(workspaceId, path);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<bool> exists(String workspaceId, String repoId) =>
      _remote.exists(workspaceId, repoId);

  @override
  Future<String> upsert(String workspaceId, Repo repo) =>
      _remote.upsert(workspaceId, _toDto(repo));

  @override
  Future<void> delete(String workspaceId, String repoId) =>
      _remote.delete(workspaceId, repoId);

  @override
  Future<void> reorder(String workspaceId, List<String> orderedIds) =>
      _remote.reorder(workspaceId, orderedIds);
}
