import 'package:cc_domain/core/domain/entities/agent.dart';

/// Repository interface for agent data access.
abstract class AgentRepository {
  /// Watches all agents across every workspace, ordered by name.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for the dashboard's all-agents view, process
  /// detection and the startup reconcilers. A workspace-scoped surface must use
  /// [watchByWorkspace].
  Stream<List<Agent>> watchAll();

  /// Watches agents for a specific workspace ordered by name.
  Stream<List<Agent>> watchByWorkspace(String workspaceId);

  /// Returns the agent [id] within [workspaceId], or null.
  ///
  /// The id resolves only inside [workspaceId]: an agent belonging to another
  /// workspace is simply not found, so an id alone can never reach across the
  /// isolation boundary.
  Future<Agent?> getById(String workspaceId, String id);

  /// Returns the agent with [name] inside [workspaceId], or null.
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name);

  /// Upserts an agent. The workspace comes from [Agent.workspaceId], which is
  /// non-null: every agent belongs to exactly one workspace.
  Future<void> upsert(Agent agent);

  /// Deletes the agent [id] within [workspaceId].
  ///
  /// Scoped like [getById]: an id that belongs to another workspace matches
  /// nothing rather than deleting a foreign row.
  Future<void> delete(String workspaceId, String id);
}
