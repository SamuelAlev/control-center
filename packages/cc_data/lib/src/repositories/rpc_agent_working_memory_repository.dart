import 'package:cc_data/src/repositories/remote_agent_working_memory_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/features/memory/domain/repositories/agent_working_memory_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AgentWorkingMemoryRepository] backed by the RPC client — the thin-client
/// data path.
///
/// Implements the domain interface over the host's `agent_working_memory.*` ops
/// + the `agent_working_memory.watchByAgent` /
/// `agent_working_memory.watchByWorkspace` subscriptions, mapping the
/// [AgentWorkingMemoryDto] wire shape back to [AgentWorkingMemory]. The host
/// owns persistence; this client never touches a database. Reads, watches, and
/// the direct upsert row write are served.
class RpcAgentWorkingMemoryRepository implements AgentWorkingMemoryRepository {
  /// Creates an [RpcAgentWorkingMemoryRepository] over [client].
  RpcAgentWorkingMemoryRepository(RemoteRpcClient client)
    : _remote = RemoteAgentWorkingMemoryRepository(client);

  final RemoteAgentWorkingMemoryRepository _remote;

  /// Rebuilds an [AgentWorkingMemory] from its wire DTO. A missing `updatedAt`
  /// falls back to the epoch so the entity stays valid.
  static AgentWorkingMemory _fromDto(AgentWorkingMemoryDto d) =>
      AgentWorkingMemory(
        id: d.id,
        workspaceId: d.workspaceId,
        agentId: d.agentId,
        content: d.content,
        updatedAt: d.updatedAt == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.parse(d.updatedAt!),
      );

  static AgentWorkingMemoryDto _toDto(AgentWorkingMemory m) =>
      AgentWorkingMemoryDto(
        id: m.id,
        workspaceId: m.workspaceId,
        agentId: m.agentId,
        content: m.content,
        updatedAt: m.updatedAt.toIso8601String(),
      );

  @override
  Stream<AgentWorkingMemory?> watchByAgent(String workspaceId, String agentId) =>
      _remote
          .watchByAgent(agentId)
          .map((dto) => dto == null ? null : _fromDto(dto));

  @override
  Future<AgentWorkingMemory?> getByAgent(
    String workspaceId,
    String agentId,
  ) async {
    final dto = await _remote.getByAgent(agentId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Stream<List<AgentWorkingMemory>> watchByWorkspace(String workspaceId) =>
      _remote.watchByWorkspace().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<void> upsert(AgentWorkingMemory memory) =>
      _remote.upsert(_toDto(memory));
}
