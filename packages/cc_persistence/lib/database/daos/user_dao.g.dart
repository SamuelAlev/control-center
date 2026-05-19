// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dao.dart';

// ignore_for_file: type=lint
mixin _$UserDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $UsersTableTable get usersTable => attachedDatabase.usersTable;
  UserDaoManager get managers => UserDaoManager(this);
}

class UserDaoManager {
  final _$UserDaoMixin _db;
  UserDaoManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db.attachedDatabase, _db.usersTable);
}
