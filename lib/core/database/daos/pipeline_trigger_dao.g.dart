// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_trigger_dao.dart';

// ignore_for_file: type=lint
mixin _$PipelineTriggerDaoMixin on DatabaseAccessor<AppDatabase> {
  $PipelineTriggersTableTable get pipelineTriggersTable =>
      attachedDatabase.pipelineTriggersTable;
  PipelineTriggerDaoManager get managers => PipelineTriggerDaoManager(this);
}

class PipelineTriggerDaoManager {
  final _$PipelineTriggerDaoMixin _db;
  PipelineTriggerDaoManager(this._db);
  $$PipelineTriggersTableTableTableManager get pipelineTriggersTable =>
      $$PipelineTriggersTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineTriggersTable,
      );
}
