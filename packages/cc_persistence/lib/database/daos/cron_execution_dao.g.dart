// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cron_execution_dao.dart';

// ignore_for_file: type=lint
mixin _$CronExecutionDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $PipelineTemplatesTableTable get pipelineTemplatesTable =>
      attachedDatabase.pipelineTemplatesTable;
  $PipelineTriggersTableTable get pipelineTriggersTable =>
      attachedDatabase.pipelineTriggersTable;
  $CronExecutionsTableTable get cronExecutionsTable =>
      attachedDatabase.cronExecutionsTable;
  CronExecutionDaoManager get managers => CronExecutionDaoManager(this);
}

class CronExecutionDaoManager {
  final _$CronExecutionDaoMixin _db;
  CronExecutionDaoManager(this._db);
  $$PipelineTemplatesTableTableTableManager get pipelineTemplatesTable =>
      $$PipelineTemplatesTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineTemplatesTable,
      );
  $$PipelineTriggersTableTableTableManager get pipelineTriggersTable =>
      $$PipelineTriggersTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineTriggersTable,
      );
  $$CronExecutionsTableTableTableManager get cronExecutionsTable =>
      $$CronExecutionsTableTableTableManager(
        _db.attachedDatabase,
        _db.cronExecutionsTable,
      );
}
