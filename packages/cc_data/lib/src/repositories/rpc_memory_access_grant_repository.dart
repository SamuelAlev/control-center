import 'package:cc_data/src/repositories/remote_memory_access_grant_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [MemoryAccessGrantRepository] backed by the RPC client — the thin-client
/// data path.
///
/// Implements the domain interface over the host's `memory_access_grant.*` ops
/// + the `memory_access_grant.watchByWorkspace` subscription, mapping the
/// [MemoryAccessGrantDto] wire shape back to [MemoryAccessGrant]. The host owns
/// persistence; this client never touches a database. Reads, watches and the
/// upsert/upsertAll row writes are all served.
class RpcMemoryAccessGrantRepository implements MemoryAccessGrantRepository {
  /// Creates an [RpcMemoryAccessGrantRepository] over [client].
  RpcMemoryAccessGrantRepository(RemoteRpcClient client)
    : _remote = RemoteMemoryAccessGrantRepository(client);

  final RemoteMemoryAccessGrantRepository _remote;

  /// Rebuilds a [MemoryAccessGrant] from its wire DTO. Enum fields are encoded
  /// as `.name`; an unknown value falls back to a safe default so the entity
  /// stays valid.
  static MemoryAccessGrant _fromDto(MemoryAccessGrantDto d) =>
      MemoryAccessGrant(
        workspaceId: d.workspaceId,
        agentRole: _agentRoleByName[d.agentRole] ?? AgentRole.general,
        memoryDomain: d.memoryDomain,
        permission:
            _memoryPermissionByName[d.permission] ?? MemoryPermission.none,
      );

  static MemoryAccessGrantDto _toDto(MemoryAccessGrant g) =>
      MemoryAccessGrantDto(
        workspaceId: g.workspaceId,
        agentRole: g.agentRole.name,
        memoryDomain: g.memoryDomain,
        permission: g.permission.name,
      );

  @override
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId) async {
    final dtos = await _remote.getByWorkspace();
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId) =>
      _remote.watch().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<void> upsert(MemoryAccessGrant grant) => _remote.upsert(_toDto(grant));

  @override
  Future<void> upsertAll(List<MemoryAccessGrant> grants) =>
      _remote.upsertAll(grants.map(_toDto).toList());
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, AgentRole> _agentRoleByName = AgentRole.values.asNameMap();
final Map<String, MemoryPermission> _memoryPermissionByName = MemoryPermission
    .values
    .asNameMap();
