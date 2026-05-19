import 'package:cc_data/src/repositories/remote_memory_policy_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MemoryPolicyRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `memory_policy.*` ops + the
/// `memory_policy.watchForWorkspace` subscription, mapping the
/// [MemoryPolicyDto] wire shape back to [MemoryPolicy]. The host owns
/// persistence; this client never touches a database. The workspace is bound
/// server-side, so the `workspaceId` parameters the interface threads are not
/// re-sent — the host injects the authoritative one. Reads, watches, and the
/// upsert/delete row writes are all served.
class RpcMemoryPolicyRepository implements MemoryPolicyRepository {
  /// Creates an [RpcMemoryPolicyRepository] over [client].
  RpcMemoryPolicyRepository(RemoteRpcClient client)
    : _remote = RemoteMemoryPolicyRepository(client);

  final RemoteMemoryPolicyRepository _remote;

  /// Rebuilds a [MemoryPolicy] from its wire DTO. The `requiredRole` enum is
  /// encoded as `.name`; missing timestamps fall back to the epoch so the
  /// entity stays valid.
  static MemoryPolicy _fromDto(MemoryPolicyDto d) => MemoryPolicy(
    id: d.id,
    workspaceId: d.workspaceId,
    domain: d.domain,
    rule: d.rule,
    sourceFactIds: d.sourceFactIds,
    requiredRole: d.requiredRole == null
        ? null
        : AgentRole.values.asNameMap()[d.requiredRole],
    active: d.active,
    createdAt: d.createdAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.createdAt!),
    updatedAt: d.updatedAt == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.parse(d.updatedAt!),
  );

  static MemoryPolicyDto _toDto(MemoryPolicy p) => MemoryPolicyDto(
    id: p.id,
    workspaceId: p.workspaceId,
    domain: p.domain,
    rule: p.rule,
    sourceFactIds: p.sourceFactIds,
    requiredRole: p.requiredRole?.name,
    active: p.active,
    createdAt: p.createdAt.toIso8601String(),
    updatedAt: p.updatedAt.toIso8601String(),
  );

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) async {
    final dtos = await _remote.getByWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) async {
    try {
      final dto = await _remote.getById(id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(
    String workspaceId, {
    String? domain,
  }) async {
    final dtos = await _remote.getActiveByWorkspace(domain: domain);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<void> upsert(MemoryPolicy policy) => _remote.upsert(_toDto(policy));

  @override
  Future<void> delete(String workspaceId, String id) => _remote.delete(id);
}
