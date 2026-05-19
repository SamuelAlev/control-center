// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SyncChangesTableTable get syncChangesTable =>
      attachedDatabase.syncChangesTable;
  $SyncSequencesTableTable get syncSequencesTable =>
      attachedDatabase.syncSequencesTable;
  SyncDaoManager get managers => SyncDaoManager(this);
}

class SyncDaoManager {
  final _$SyncDaoMixin _db;
  SyncDaoManager(this._db);
  $$SyncChangesTableTableTableManager get syncChangesTable =>
      $$SyncChangesTableTableTableManager(
        _db.attachedDatabase,
        _db.syncChangesTable,
      );
  $$SyncSequencesTableTableTableManager get syncSequencesTable =>
      $$SyncSequencesTableTableTableManager(
        _db.attachedDatabase,
        _db.syncSequencesTable,
      );
}
