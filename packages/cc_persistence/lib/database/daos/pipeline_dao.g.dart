// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pipeline_dao.dart';

// ignore_for_file: type=lint
mixin _$PipelineDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $PipelineRunSnapshotsTableTable get pipelineRunSnapshotsTable =>
      attachedDatabase.pipelineRunSnapshotsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
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
  $$PipelineRunSnapshotsTableTableTableManager get pipelineRunSnapshotsTable =>
      $$PipelineRunSnapshotsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunSnapshotsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$PipelineStepRunsTableTableTableManager get pipelineStepRunsTable =>
      $$PipelineStepRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineStepRunsTable,
      );
}
