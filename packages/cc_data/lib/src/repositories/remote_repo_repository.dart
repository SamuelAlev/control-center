import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates Git-repo registrations over the RPC client.
///
/// Repos are global (not workspace-scoped); the host owns persistence. Mirrors
/// the `repos.*` ops + the `repos.watchAll` subscription in the host catalog.
class RemoteRepoRepository {
  /// Creates a [RemoteRepoRepository] over [_client].
  RemoteRepoRepository(this._client);

  final RemoteRpcClient _client;

  /// A single repo by id, or null.
  Future<RepoDto?> get(String id) async {
    final data = await _client.call('repos.get', {'repo_id': id});
    final repo = data['repo'];
    return repo is Map ? RepoDto.fromJson(repo.cast<String, dynamic>()) : null;
  }

  /// Inserts or updates [repo]; returns the persisted id.
  Future<String> upsert(RepoDto repo) async {
    final data = await _client.call('repos.upsert', {'repo': repo.toJson()});
    return data['repo_id'] as String? ?? repo.id;
  }

  /// Deletes the repo [id].
  Future<void> delete(String id) =>
      _client.call('repos.delete', {'repo_id': id});

  /// Registers a repo by inspecting a git checkout at [path] on the SERVER's
  /// filesystem (`git remote get-url origin` etc.), returning the persisted
  /// repo. The session's bound workspace is injected host-side, so the new repo
  /// is scoped + indexed in that workspace. Throws [RemoteRpcException] with
  /// `RpcErrorCodes.validation` when the path is not a GitHub working tree.
  Future<RepoDto> addFromPath(String path) async {
    final data = await _client.call('repos.addFromPath', {'path': path});
    return RepoDto.fromJson((data['repo'] as Map).cast<String, dynamic>());
  }

  /// Live repos — a fresh snapshot on every change.
  Stream<List<RepoDto>> watchAll() =>
      _client.subscribe('repos.watchAll', const {}).map(_repos);

  List<RepoDto> _repos(Map<String, dynamic> data) =>
      ((data['repos'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => RepoDto.fromJson(r.cast<String, dynamic>()))
          .toList();
}
