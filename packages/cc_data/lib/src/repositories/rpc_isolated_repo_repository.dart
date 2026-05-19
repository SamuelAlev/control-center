import 'package:cc_data/src/repositories/remote_isolated_repo_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [IsolatedRepoRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `isolated_repo.*` ops + the
/// `isolated_repo.watchForWorkspace` subscription, mapping the [IsolatedRepoDto]
/// wire shape back to [IsolatedRepo]. The host owns persistence; this client
/// never touches a database. Reads, the watch, and the upsert/delete row writes
/// are served. The two cross-workspace teardown lookups source no workspace and
/// each returned row carries its own — mirrors the documented exemption.
class RpcIsolatedRepoRepository implements IsolatedRepoRepository {
  /// Creates an [RpcIsolatedRepoRepository] over [client].
  RpcIsolatedRepoRepository(RemoteRpcClient client)
    : _remote = RemoteIsolatedRepoRepository(client);

  final RemoteIsolatedRepoRepository _remote;

  /// Rebuilds an [IsolatedRepo] from its wire DTO. The enum [backend] is encoded
  /// as `.name`; a missing `createdAt` falls back to the epoch so the entity
  /// stays valid.
  static IsolatedRepo _fromDto(IsolatedRepoDto d) => IsolatedRepo(
    id: d.id,
    workspaceId: d.workspaceId,
    channelId: d.channelId,
    repoId: d.repoId,
    path: d.path,
    branch: d.branch,
    backend:
        RepoIsolationBackend.values.asNameMap()[d.backend] ??
        RepoIsolationBackend.rift,
    sourcePath: d.sourcePath,
    ticketId: d.ticketId,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
  );

  static IsolatedRepoDto _toDto(IsolatedRepo r) => IsolatedRepoDto(
    id: r.id,
    workspaceId: r.workspaceId,
    channelId: r.channelId,
    repoId: r.repoId,
    path: r.path,
    branch: r.branch,
    backend: r.backend.name,
    sourcePath: r.sourcePath,
    ticketId: r.ticketId,
    createdAt: r.createdAt.toIso8601String(),
  );

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String channelId,
    String repoId,
  ) async {
    final dto = await _remote.forUnitRepo(channelId, repoId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<List<IsolatedRepo>> forChannel(
    String workspaceId,
    String channelId,
  ) async {
    final dtos = await _remote.forChannel(channelId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final dtos = await _remote.forTicket(ticketId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<IsolatedRepo>> forChannelAcrossWorkspaces(
    String channelId,
  ) async {
    final dtos = await _remote.forChannelAcrossWorkspaces(channelId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async {
    final dtos = await _remote.forTicketAcrossWorkspaces(ticketId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<void> upsert(IsolatedRepo repo) => _remote.upsert(_toDto(repo));

  @override
  Future<void> deleteById(String id) => _remote.deleteById(id);
}
