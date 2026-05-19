// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_activity_dao.dart';

// ignore_for_file: type=lint
mixin _$TeamActivityDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $TeamActivityLogTableTable get teamActivityLogTable =>
      attachedDatabase.teamActivityLogTable;
  TeamActivityDaoManager get managers => TeamActivityDaoManager(this);
}

class TeamActivityDaoManager {
  final _$TeamActivityDaoMixin _db;
  TeamActivityDaoManager(this._db);
  $$TeamActivityLogTableTableTableManager get teamActivityLogTable =>
      $$TeamActivityLogTableTableTableManager(
        _db.attachedDatabase,
        _db.teamActivityLogTable,
      );
}
