import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';

/// Persistence for [Orchestration] aggregates. Every read takes a required
/// `workspaceId` (workspace isolation invariant).
abstract interface class OrchestrationRepository {
  /// Inserts a new orchestration.
  Future<void> insert(Orchestration orchestration);

  /// Updates an existing orchestration (scoped to its workspace).
  Future<void> update(Orchestration orchestration);

  /// Fetches one by id within [workspaceId], or null.
  Future<Orchestration?> getById(String workspaceId, String id);

  /// The orchestration anchored to [ticketId] within [workspaceId], or null.
  Future<Orchestration?> forParentTicket(String workspaceId, String ticketId);

  /// The orchestration owning [pipelineRunId] within [workspaceId], or null.
  Future<Orchestration?> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  );

  /// The orchestration owning [pipelineRunId] across all workspaces (event
  /// routers that receive only a run id), or null.
  Future<Orchestration?> forPipelineRunAnyWorkspace(String pipelineRunId);

  /// Watches all orchestrations in a workspace, newest first.
  Stream<List<Orchestration>> watchForWorkspace(String workspaceId);

  /// Watches a single orchestration by id within [workspaceId].
  Stream<Orchestration?> watchById(String workspaceId, String id);

  /// Approved orchestrations with no pipeline run yet (materialization resume).
  Future<List<Orchestration>> approvedNeedingMaterialization();
}
