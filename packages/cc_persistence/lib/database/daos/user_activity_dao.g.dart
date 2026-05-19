// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_activity_dao.dart';

// ignore_for_file: type=lint
mixin _$UserActivityDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $UserActivityTableTable get userActivityTable =>
      attachedDatabase.userActivityTable;
  UserActivityDaoManager get managers => UserActivityDaoManager(this);
}

class UserActivityDaoManager {
  final _$UserActivityDaoMixin _db;
  UserActivityDaoManager(this._db);
  $$UserActivityTableTableTableManager get userActivityTable =>
      $$UserActivityTableTableTableManager(
        _db.attachedDatabase,
        _db.userActivityTable,
      );
}
