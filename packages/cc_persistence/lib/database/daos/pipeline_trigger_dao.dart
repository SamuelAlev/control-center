import 'package:cc_persistence/database/tables/pipeline_triggers_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'pipeline_trigger_dao.g.dart';

/// DAO for [PipelineTriggersTable].
@DriftAccessor(tables: [PipelineTriggersTable])
class PipelineTriggerDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$PipelineTriggerDaoMixin {
  /// Creates a [PipelineTriggerDao].
  PipelineTriggerDao(super.db);

  /// Inserts a new trigger.
  Future<void> insert(PipelineTriggersTableCompanion trigger) =>
      into(pipelineTriggersTable).insert(trigger);

  /// Updates a trigger.
  Future<void> updateTrigger(PipelineTriggersTableCompanion trigger) =>
      update(pipelineTriggersTable).replace(trigger);

  /// Deletes by ID.
  Future<void> deleteById(String id) =>
      (delete(pipelineTriggersTable)..where((t) => t.id.equals(id))).go();

  /// All triggers for a workspace.
  Future<List<PipelineTriggersTableData>> forWorkspace(String workspaceId) =>
      (select(
        pipelineTriggersTable,
      )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// This workspace's enabled triggers for an event type.
  ///
  /// The trigger dispatcher fans an event out across workspaces by asking each
  /// workspace's database in turn, then firing only the ones whose workspace
  /// matches the event's.
  Future<List<PipelineTriggersTableData>> enabledForEvent(String eventType) =>
      (select(pipelineTriggersTable)..where(
            (t) => t.enabled.equals(true) & t.eventType.equals(eventType),
          ))
          .get();

  /// Watches all triggers for a workspace.
  Stream<List<PipelineTriggersTableData>> watchForWorkspace(
    String workspaceId,
  ) => (select(
    pipelineTriggersTable,
  )..where((t) => t.workspaceId.equals(workspaceId))).watch();

  /// Gets a trigger by ID.
  Future<PipelineTriggersTableData?> getById(String id) => (select(
    pipelineTriggersTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Records that a scheduled trigger fired at [when].
  Future<void> markFired(String id, DateTime when) =>
      (update(pipelineTriggersTable)..where((t) => t.id.equals(id))).write(
        PipelineTriggersTableCompanion(lastFiredAt: Value(when)),
      );

  /// Persists a scheduled trigger's [nextRunAt] (and optionally [lastFiredAt]).
  Future<void> setSchedule(
    String id, {
    DateTime? nextRunAt,
    DateTime? lastFiredAt,
  }) => (update(pipelineTriggersTable)..where((t) => t.id.equals(id))).write(
    PipelineTriggersTableCompanion(
      nextRunAt: nextRunAt != null
          ? Value(nextRunAt.toUtc())
          : const Value.absent(),
      lastFiredAt: lastFiredAt != null
          ? Value(lastFiredAt)
          : const Value.absent(),
    ),
  );

  /// Looks up the enabled webhook trigger bound to [token], **across every
  /// workspace** — the inbound `/webhooks/<token>` URL carries only the token,
  /// and the workspace is resolved from the matched trigger.
  ///
  /// The token is a per-trigger secret. An inbound webhook carries nothing but
  /// the token, so the workspace is resolved first through the global
  /// `workspace_routes` index (`WorkspaceRouteKind.webhookToken`) and the lookup
  /// then runs against that workspace's database.
  Future<PipelineTriggersTableData?> byWebhookToken(String token) =>
      (select(pipelineTriggersTable)
            ..where(
              (t) => t.webhookToken.equals(token) & t.enabled.equals(true),
            )
            ..limit(1))
          .getSingleOrNull();
}
