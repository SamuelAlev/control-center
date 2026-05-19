// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preference_dao.dart';

// ignore_for_file: type=lint
mixin _$UserPreferenceDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $UsersTableTable get usersTable => attachedDatabase.usersTable;
  $UserPreferencesTableTable get userPreferencesTable =>
      attachedDatabase.userPreferencesTable;
  UserPreferenceDaoManager get managers => UserPreferenceDaoManager(this);
}

class UserPreferenceDaoManager {
  final _$UserPreferenceDaoMixin _db;
  UserPreferenceDaoManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db.attachedDatabase, _db.usersTable);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(
        _db.attachedDatabase,
        _db.userPreferencesTable,
      );
}
