// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rig_dao.dart';

// ignore_for_file: type=lint
mixin _$RigDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $RigSessionsTableTable get rigSessionsTable =>
      attachedDatabase.rigSessionsTable;
  $RigActionLogTableTable get rigActionLogTable =>
      attachedDatabase.rigActionLogTable;
  RigDaoManager get managers => RigDaoManager(this);
}

class RigDaoManager {
  final _$RigDaoMixin _db;
  RigDaoManager(this._db);
  $$RigSessionsTableTableTableManager get rigSessionsTable =>
      $$RigSessionsTableTableTableManager(
        _db.attachedDatabase,
        _db.rigSessionsTable,
      );
  $$RigActionLogTableTableTableManager get rigActionLogTable =>
      $$RigActionLogTableTableTableManager(
        _db.attachedDatabase,
        _db.rigActionLogTable,
      );
}
