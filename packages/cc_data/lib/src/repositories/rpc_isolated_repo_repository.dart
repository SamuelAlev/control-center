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
/// never touches a database. Reads, the watch and row deletion are served;
/// only the server's provisioner writes a row, since its path and source
/// path are what release later archives and destroys. The two cross-workspace teardown lookups source no workspace and
/// each returned row carries its own — mirrors the documented exemption.
class RpcIsolatedRepoRepository implements IsolatedRepoRepository {
  /// Creates an [RpcIsolatedRepoRepository] over [client].
  RpcIsolatedRepoRepository(RemoteRpcClient client)
    : _remote = RemoteIsolatedRepoRepository(client);

  final RemoteIsolatedRepoRepository _remote;

  /// Rebuilds an [IsolatedRepo] from its wire DTO. The enum `backend` is encoded
  /// as `.name`; a missing `createdAt` falls back to the epoch so the entity
  /// stays valid.
  static IsolatedRepo _fromDto(IsolatedRepoDto d) => IsolatedRepo(
    id: d.id,
    workspaceId: d.workspaceId,
    spaceId: d.spaceId,
    repoId: d.repoId,
    path: d.path,
    branch: d.branch,
    backend:
        _repoIsolationBackendByName[d.backend] ?? RepoIsolationBackend.rift,
    sourcePath: d.sourcePath,
    ticketId: d.ticketId,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
  );

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    final dto = await _remote.forUnitRepo(workspaceId, spaceId, repoId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async {
    final dtos = await _remote.forSpace(workspaceId, spaceId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final dtos = await _remote.forTicket(workspaceId, ticketId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<IsolatedRepo>> forSpaceAcrossWorkspaces(String spaceId) async {
    final dtos = await _remote.forSpaceAcrossWorkspaces(spaceId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async {
    final dtos = await _remote.forTicketAcrossWorkspaces(ticketId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) =>
      _remote.watch(workspaceId).map((dtos) => dtos.map(_fromDto).toList());

  /// Refused: a worktree row is written only by the server's provisioner.
  @override
  Future<void> upsert(IsolatedRepo repo) => throw UnsupportedError(
    'Worktree rows are written by the server that provisions them',
  );

  @override
  Future<void> deleteById(String workspaceId, String id) =>
      _remote.deleteById(workspaceId, id);
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, RepoIsolationBackend> _repoIsolationBackendByName =
    RepoIsolationBackend.values.asNameMap();
