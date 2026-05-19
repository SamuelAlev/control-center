import 'package:cc_domain/core/domain/entities/working_memory_item.dart';

/// Audit summary of a single consolidation (`sleep`) pass.
class ConsolidationPassReport {
  /// Creates a [ConsolidationPassReport].
  const ConsolidationPassReport({
    required this.workspaceId,
    this.agentId,
    this.itemsConsidered = 0,
    this.factsCreated = 0,
    this.factsUpdated = 0,
    this.conflictsDetected = 0,
    this.evicted = 0,
    required this.startedAt,
    required this.finishedAt,
  });

  /// Workspace the pass ran in.
  final String workspaceId;
  /// Agent whose working memory was consolidated, if scoped.
  final String? agentId;
  /// Working items examined.
  final int itemsConsidered;
  /// Durable facts created.
  final int factsCreated;
  /// Durable facts re-asserted.
  final int factsUpdated;
  /// Conflicts detected.
  final int conflictsDetected;
  /// Hot items evicted by TTL/limit.
  final int evicted;
  /// When the pass started.
  final DateTime startedAt;
  /// When the pass finished.
  final DateTime finishedAt;
}

/// Repository for the hot working-memory tier (workspace-scoped).
abstract class WorkingMemoryItemRepository {
  /// Adds a hot item.
  Future<void> add(WorkingMemoryItem item);

  /// Hot items for an agent, newest first.
  Future<List<WorkingMemoryItem>> getForAgent(String workspaceId, String agentId);

  /// All hot items in a workspace, newest first.
  Future<List<WorkingMemoryItem>> getForWorkspace(String workspaceId);

  /// Watches the hot items for an agent.
  Stream<List<WorkingMemoryItem>> watchForAgent(String workspaceId, String agentId);

  /// Deletes hot items by id after they consolidate (scoped).
  Future<void> deleteByIds(String workspaceId, List<String> ids);

  /// Evicts hot items whose TTL has passed [now]; returns rows removed.
  Future<int> deleteExpired(String workspaceId, DateTime now);

  /// Persists a consolidation-pass audit row.
  Future<void> recordConsolidationPass(ConsolidationPassReport report);
}