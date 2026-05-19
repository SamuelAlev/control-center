// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_dao.dart';

// ignore_for_file: type=lint
mixin _$PipelineDaoMixin on DatabaseAccessor<AppDatabase> {
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $PipelineStepRunsTableTable get pipelineStepRunsTable =>
      attachedDatabase.pipelineStepRunsTable;
  PipelineDaoManager get managers => PipelineDaoManager(this);
}

class PipelineDaoManager {
  final _$PipelineDaoMixin _db;
  PipelineDaoManager(this._db);
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$PipelineStepRunsTableTableTableManager get pipelineStepRunsTable =>
      $$PipelineStepRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineStepRunsTable,
      );
}
