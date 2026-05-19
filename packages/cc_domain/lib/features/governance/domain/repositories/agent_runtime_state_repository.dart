import 'package:cc_domain/features/governance/domain/entities/agent_runtime_state.dart';

/// Repository for per-agent runtime liveness (heartbeats). Workspace-scoped
/// reads require `workspaceId`; the GC sweep is the only cross-workspace path.
abstract interface class AgentRuntimeStateRepository {
  /// Watches all runtime-state rows for [workspaceId].
  Stream<List<AgentRuntimeState>> watchByWorkspace(String workspaceId);

  /// Returns all runtime-state rows for [workspaceId].
  Future<List<AgentRuntimeState>> listByWorkspace(String workspaceId);

  /// Returns the runtime state for [agentId] within [workspaceId], or null.
  Future<AgentRuntimeState?> getForAgent(String workspaceId, String agentId);

  /// Returns **all** runtime-state rows across every workspace.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for the runtime-health GC sweeper only. A
  /// workspace-scoped surface must use [listByWorkspace] instead.
  Future<List<AgentRuntimeState>> listAll();

  /// Inserts or updates a runtime-state row.
  Future<void> upsert(AgentRuntimeState state);

  /// Deletes the runtime state for [agentId] within [workspaceId].
  Future<void> delete(String workspaceId, String agentId);
}
