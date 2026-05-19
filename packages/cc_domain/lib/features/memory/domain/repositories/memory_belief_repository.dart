import 'package:cc_domain/core/domain/entities/memory_belief.dart';

/// Repository for harmonized [MemoryBelief]s (workspace-scoped).
abstract class MemoryBeliefRepository {
  /// Replaces all beliefs for a workspace with [beliefs] (a harmonization pass
  /// recomputes the full set).
  Future<void> replaceWorkspace(String workspaceId, List<MemoryBelief> beliefs);

  /// Watches beliefs in a workspace, strongest first.
  Stream<List<MemoryBelief>> watchByWorkspace(String workspaceId);

  /// Reads beliefs in a workspace, strongest first.
  Future<List<MemoryBelief>> getByWorkspace(String workspaceId);
}