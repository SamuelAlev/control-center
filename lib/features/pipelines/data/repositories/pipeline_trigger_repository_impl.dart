import 'package:control_center/core/database/daos/pipeline_trigger_dao.dart';
import 'package:control_center/features/pipelines/data/mappers/pipeline_trigger_mappers.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';

/// Drift-backed implementation of [PipelineTriggerRepository].
class PipelineTriggerRepositoryImpl implements PipelineTriggerRepository {
  /// Creates a [PipelineTriggerRepositoryImpl].
  PipelineTriggerRepositoryImpl(this._dao);

  final PipelineTriggerDao _dao;

  @override
  Future<void> insert(PipelineTrigger trigger) async {
    await _dao.insert(triggerToCompanion(trigger));
  }

  @override
  Future<void> update(PipelineTrigger trigger) async {
    await _dao.updateTrigger(triggerToCompanion(trigger));
  }

  @override
  Future<void> deleteById(String id) async {
    await _dao.deleteById(id);
  }

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async {
    final rows = await _dao.forWorkspace(workspaceId);
    return rows.map(triggerFromRow).toList();
  }

  @override
  Future<List<PipelineTrigger>> enabledForEvent(String eventType) async {
    final rows = await _dao.enabledForEvent(eventType);
    return rows.map(triggerFromRow).toList();
  }

  @override
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId) {
    return _dao
        .watchForWorkspace(workspaceId)
        .map((rows) => rows.map(triggerFromRow).toList());
  }

  @override
  Future<PipelineTrigger?> getById(String id) async {
    final row = await _dao.getById(id);
    return row != null ? triggerFromRow(row) : null;
  }

  @override
  Future<List<PipelineTrigger>> scheduled() async {
    final rows = await _dao.enabledForEvent(PipelineTrigger.scheduleEventType);
    return rows.map(triggerFromRow).toList();
  }

  @override
  Future<void> markFired(String id, DateTime when) =>
      _dao.markFired(id, when);
}
