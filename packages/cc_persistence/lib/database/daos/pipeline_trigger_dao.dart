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

  /// The enabled webhook trigger whose token is stored under [ref].
  ///
  /// An inbound `/webhooks/<token>` carries nothing but the token: the global
  /// `workspace_routes` index resolves its route key to a workspace first, and
  /// the reference derived from that key finds the row here.
  Future<PipelineTriggersTableData?> byWebhookTokenRef(String ref) =>
      (select(pipelineTriggersTable)..where(
            (t) => t.webhookTokenRef.equals(ref) & t.enabled.equals(true),
          ))
          .getSingleOrNull();

  /// The trigger (enabled or not) whose token is stored under [ref].
  Future<PipelineTriggersTableData?> anyByWebhookTokenRef(String ref) =>
      (select(
        pipelineTriggersTable,
      )..where((t) => t.webhookTokenRef.equals(ref))).getSingleOrNull();
}
