// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_studio_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewStudioDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ReviewCohortsTableTable get reviewCohortsTable =>
      attachedDatabase.reviewCohortsTable;
  $ReposTableTable get reposTable => attachedDatabase.reposTable;
  $ApiContractSnapshotsTableTable get apiContractSnapshotsTable =>
      attachedDatabase.apiContractSnapshotsTable;
  $VisualDiffSnapshotsTableTable get visualDiffSnapshotsTable =>
      attachedDatabase.visualDiffSnapshotsTable;
  $ReviewAxisResultsTableTable get reviewAxisResultsTable =>
      attachedDatabase.reviewAxisResultsTable;
  $ReviewDependencyDiffsTableTable get reviewDependencyDiffsTable =>
      attachedDatabase.reviewDependencyDiffsTable;
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $ReviewRunSnapshotsTableTable get reviewRunSnapshotsTable =>
      attachedDatabase.reviewRunSnapshotsTable;
  ReviewStudioDaoManager get managers => ReviewStudioDaoManager(this);
}

class ReviewStudioDaoManager {
  final _$ReviewStudioDaoMixin _db;
  ReviewStudioDaoManager(this._db);
  $$ReviewCohortsTableTableTableManager get reviewCohortsTable =>
      $$ReviewCohortsTableTableTableManager(
        _db.attachedDatabase,
        _db.reviewCohortsTable,
      );
  $$ReposTableTableTableManager get reposTable =>
      $$ReposTableTableTableManager(_db.attachedDatabase, _db.reposTable);
  $$ApiContractSnapshotsTableTableTableManager get apiContractSnapshotsTable =>
      $$ApiContractSnapshotsTableTableTableManager(
        _db.attachedDatabase,
        _db.apiContractSnapshotsTable,
      );
  $$VisualDiffSnapshotsTableTableTableManager get visualDiffSnapshotsTable =>
      $$VisualDiffSnapshotsTableTableTableManager(
        _db.attachedDatabase,
        _db.visualDiffSnapshotsTable,
      );
  $$ReviewAxisResultsTableTableTableManager get reviewAxisResultsTable =>
      $$ReviewAxisResultsTableTableTableManager(
        _db.attachedDatabase,
        _db.reviewAxisResultsTable,
      );
  $$ReviewDependencyDiffsTableTableTableManager
  get reviewDependencyDiffsTable =>
      $$ReviewDependencyDiffsTableTableTableManager(
        _db.attachedDatabase,
        _db.reviewDependencyDiffsTable,
      );
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$ReviewRunSnapshotsTableTableTableManager get reviewRunSnapshotsTable =>
      $$ReviewRunSnapshotsTableTableTableManager(
        _db.attachedDatabase,
        _db.reviewRunSnapshotsTable,
      );
}
