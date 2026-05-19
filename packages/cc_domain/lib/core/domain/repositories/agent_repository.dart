import 'package:cc_domain/core/domain/entities/agent.dart';

/// Repository interface for agent data access.
abstract class AgentRepository {
  /// Watches all agents ordered by name.
  Stream<List<Agent>> watchAll();

  /// Watches agents for a specific workspace ordered by name.
  Stream<List<Agent>> watchByWorkspace(String workspaceId);

  /// Returns a single agent by [id], or null.
  Future<Agent?> getById(String id);

  /// Returns the agent with [name] inside [workspaceId], or null.
  Future<Agent?> findByWorkspaceAndName(String workspaceId, String name);

  /// Upserts an agent.
  Future<void> upsert(Agent agent);

  /// Deletes an agent by [id].
  Future<void> delete(String id);
}
