import 'package:cc_data/src/repositories/remote_memory_domain_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/memory/domain/entities/memory_domain.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MemoryDomainRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `memory_domain.*` ops + the
/// `memory_domain.watchForWorkspace` subscription, mapping the
/// [MemoryDomainDto] wire shape back to [MemoryDomain]. The host owns
/// persistence; this client never touches a database. Reads, the watch, and the
/// upsert row write are served.
class RpcMemoryDomainRepository implements MemoryDomainRepository {
  /// Creates an [RpcMemoryDomainRepository] over [client].
  RpcMemoryDomainRepository(RemoteRpcClient client)
    : _remote = RemoteMemoryDomainRepository(client);

  final RemoteMemoryDomainRepository _remote;

  /// Rebuilds a [MemoryDomain] from its wire DTO. A missing `createdAt` falls
  /// back to the epoch so the entity stays valid.
  static MemoryDomain _fromDto(MemoryDomainDto d) => MemoryDomain(
    id: d.id,
    workspaceId: d.workspaceId,
    name: d.name,
    label: d.label,
    description: d.description,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
    createdByRole: d.createdByRole,
  );

  static MemoryDomainDto _toDto(MemoryDomain d) => MemoryDomainDto(
    id: d.id,
    workspaceId: d.workspaceId,
    name: d.name,
    label: d.label,
    description: d.description,
    createdAt: d.createdAt.toIso8601String(),
    createdByRole: d.createdByRole,
  );

  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId) async {
    final dtos = await _remote.getByWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<MemoryDomain?> findByName(String workspaceId, String name) async {
    final dto = await _remote.findByName(name);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<void> upsert(MemoryDomain domain) => _remote.upsert(_toDto(domain));
}
