import 'package:cc_persistence/database/tables/orchestrations_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'orchestration_dao.g.dart';

/// Data access for orchestrations. Every read is workspace-scoped.
@DriftAccessor(tables: [OrchestrationsTable])
class OrchestrationDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$OrchestrationDaoMixin {
  /// Creates an [OrchestrationDao].
  OrchestrationDao(super.db);

  // --- writes ---

  /// Inserts a new orchestration row.
  Future<void> insert(OrchestrationsTableCompanion row) =>
      into(orchestrationsTable).insert(row);

  /// Updates an orchestration scoped to [workspaceId] while it is still at
  /// [revision] in [status] (what the writer read). Returns rows written
  /// (0: gone, or another writer moved it).
  Future<int> updateById(
    String id,
    String workspaceId,
    OrchestrationsTableCompanion row, {
    required int revision,
    required String status,
  }) =>
      (update(orchestrationsTable)..where(
            (o) =>
                o.id.equals(id) &
                o.workspaceId.equals(workspaceId) &
                o.revision.equals(revision) &
                o.status.equals(status),
          ))
          .write(row);

  /// Sets the cap of [id] to [to] while it is still [from]; writes that
  /// column only. Returns rows written (0: gone, or another raise won).
  Future<int> raiseCap(
    String id,
    String workspaceId, {
    required int from,
    required int to,
  }) =>
      (update(orchestrationsTable)..where(
            (o) =>
                o.id.equals(id) &
                o.workspaceId.equals(workspaceId) &
                o.maxCostMicros.equals(from),
          ))
          .write(OrchestrationsTableCompanion(maxCostMicros: Value(to)));

  // --- reads ---

  /// Fetches one orchestration by id, scoped to [workspaceId].
  Future<OrchestrationsTableData?> getById(String id, String workspaceId) =>
      (select(orchestrationsTable)
            ..where((o) => o.id.equals(id) & o.workspaceId.equals(workspaceId)))
          .getSingleOrNull();

  /// Fetches the orchestration anchored to [ticketId] within [workspaceId].
  Future<OrchestrationsTableData?> forParentTicket(
    String workspaceId,
    String ticketId,
  ) =>
      (select(orchestrationsTable)
            ..where(
              (o) =>
                  o.workspaceId.equals(workspaceId) &
                  o.parentTicketId.equals(ticketId),
            )
            ..orderBy([(o) => OrderingTerm.desc(o.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Fetches the orchestration owning [pipelineRunId] within [workspaceId]:
  /// the oldest when two name it (the server writes one, so this is a
  /// deterministic answer, never a throw).
  Future<OrchestrationsTableData?> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) =>
      (select(orchestrationsTable)
            ..where(
              (o) =>
                  o.workspaceId.equals(workspaceId) &
                  o.pipelineRunId.equals(pipelineRunId),
            )
            ..orderBy([
              (o) => OrderingTerm.asc(o.createdAt),
              (o) => OrderingTerm.asc(o.id),
            ])
            ..limit(1))
          .getSingleOrNull();

  /// Fetches the orchestration owning [pipelineRunId] across all workspaces.
  ///
  /// Event-router fallback for pipeline-run listeners that receive only a run
  /// id and must locate the orchestration to re-scope to its workspace.
  ///
  /// Answering it across the install means asking each workspace's database in
  /// turn and taking the first hit; the returned row carries the workspace the
  /// caller then acts in.
  Future<OrchestrationsTableData?> forPipelineRunAnyWorkspace(
    String pipelineRunId,
  ) =>
      (select(orchestrationsTable)
            ..where((o) => o.pipelineRunId.equals(pipelineRunId))
            ..orderBy([
              (o) => OrderingTerm.asc(o.createdAt),
              (o) => OrderingTerm.asc(o.id),
            ])
            ..limit(1))
          .getSingleOrNull();

  // --- watches ---

  /// Watches all orchestrations in a workspace, newest first.
  Stream<List<OrchestrationsTableData>> watchForWorkspace(String workspaceId) =>
      (select(orchestrationsTable)
            ..where((o) => o.workspaceId.equals(workspaceId))
            ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
          .watch();

  /// Watches a single orchestration by id, scoped to [workspaceId].
  Stream<OrchestrationsTableData?> watchById(String id, String workspaceId) =>
      (select(orchestrationsTable)
            ..where((o) => o.id.equals(id) & o.workspaceId.equals(workspaceId)))
          .watchSingleOrNull();

  /// All orchestrations in `approved` state that have no pipeline run yet —
  /// candidates for materialization resume after a crash.
  Future<List<OrchestrationsTableData>> approvedNeedingMaterialization() =>
      (select(orchestrationsTable)..where(
            (o) => o.status.equals('approved') & o.pipelineRunId.isNull(),
          ))
          .get();
}
