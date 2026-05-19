import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/pipeline_triggers_table.dart';
import 'package:drift/drift.dart';

part 'pipeline_trigger_dao.g.dart';

/// DAO for [PipelineTriggersTable].
@DriftAccessor(tables: [PipelineTriggersTable])
class PipelineTriggerDao extends DatabaseAccessor<AppDatabase>
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
      (select(pipelineTriggersTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .get();

  /// All enabled triggers for an event type, **across every workspace**.
  ///
  /// CROSS-WORKSPACE BY DESIGN — the trigger dispatcher fans an event out to
  /// every workspace's matching triggers, then filters each candidate by the
  /// event's own `workspaceId` before firing. Do not use this as a
  /// workspace-scoped read; use [forWorkspace] / [watchForWorkspace] for that.
  Future<List<PipelineTriggersTableData>> enabledForEvent(String eventType) =>
      (select(pipelineTriggersTable)
            ..where((t) => t.enabled.equals(true) & t.eventType.equals(eventType)))
          .get();

  /// Watches all triggers for a workspace.
  Stream<List<PipelineTriggersTableData>> watchForWorkspace(
          String workspaceId) =>
      (select(pipelineTriggersTable)
            ..where((t) => t.workspaceId.equals(workspaceId)))
          .watch();

  /// Gets a trigger by ID.
  Future<PipelineTriggersTableData?> getById(String id) =>
      (select(pipelineTriggersTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Records that a scheduled trigger fired at [when].
  Future<void> markFired(String id, DateTime when) =>
      (update(pipelineTriggersTable)..where((t) => t.id.equals(id)))
          .write(PipelineTriggersTableCompanion(lastFiredAt: Value(when)));
}
