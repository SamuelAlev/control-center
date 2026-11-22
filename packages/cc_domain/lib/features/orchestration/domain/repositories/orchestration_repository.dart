import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';

/// Persistence for [Orchestration] aggregates. Every read takes a required
/// `workspaceId` (workspace isolation invariant).
abstract interface class OrchestrationRepository {
  /// Inserts a new orchestration.
  Future<void> insert(Orchestration orchestration);

  /// Writes [next] over its row (scoped to its workspace) while the row is
  /// still at the `revision` and `status` of [read], the row the writer
  /// read; false when another writer moved it, and the writer refuses or
  /// re-reads ([OrchestrationChange.change]). So a stale write never puts an
  /// older status, run link or plan back. The cost cap follows [next] only
  /// when [read] is `proposed` (nothing runs yet: a revised proposal
  /// carries its budget, an approval the budget of the revision it
  /// approves); after that it is never changed here, and a raise goes
  /// through `OrchestrationCapStore.raiseCap`.
  Future<bool> update(Orchestration next, {required Orchestration read});

  /// Fetches one by id within [workspaceId], or null.
  Future<Orchestration?> getById(String workspaceId, String id);

  /// The orchestration anchored to [ticketId] within [workspaceId], or null.
  Future<Orchestration?> forParentTicket(String workspaceId, String ticketId);

  /// The orchestration owning [pipelineRunId] within [workspaceId], or null.
  /// The server is the only writer of the link, so one run has one row; if
  /// two ever name the run, the oldest answers (never a throw).
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

/// A write that follows the row: re-read, change, write while unmoved.
extension OrchestrationChange on OrchestrationRepository {
  /// How many times [change] re-reads before it gives up.
  static const int attempts = 5;

  /// Writes [apply] of orchestration [id] of [workspaceId] over the row it
  /// was computed from, re-reading and re-applying when another writer moved
  /// the row meanwhile. [apply] returns null when there is nothing to write
  /// on the row as it is now. Returns what was written, or null (no row, or
  /// nothing to write). Throws a [StateError] when the row kept moving.
  Future<Orchestration?> change(
    String workspaceId,
    String id,
    Orchestration? Function(Orchestration current) apply,
  ) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      final current = await getById(workspaceId, id);
      if (current == null) {
        return null;
      }
      final next = apply(current);
      if (next == null) {
        return null;
      }
      if (await update(next, read: current)) {
        return next;
      }
    }
    throw StateError('Orchestration $id kept changing during a write');
  }
}
