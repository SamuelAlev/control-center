// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_studio_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewStudioDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ReviewCohortsTableTable get reviewCohortsTable =>
      attachedDatabase.reviewCohortsTable;
  $ApiContractSnapshotsTableTable get apiContractSnapshotsTable =>
      attachedDatabase.apiContractSnapshotsTable;
  $VisualDiffSnapshotsTableTable get visualDiffSnapshotsTable =>
      attachedDatabase.visualDiffSnapshotsTable;
  $ReviewAxisResultsTableTable get reviewAxisResultsTable =>
      attachedDatabase.reviewAxisResultsTable;
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
}
