// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'runtime_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$RuntimeProfileDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  RuntimeProfileDaoManager get managers => RuntimeProfileDaoManager(this);
}

class RuntimeProfileDaoManager {
  final _$RuntimeProfileDaoMixin _db;
  RuntimeProfileDaoManager(this._db);
  $$RuntimeProfilesTableTableTableManager get runtimeProfilesTable =>
      $$RuntimeProfilesTableTableTableManager(
        _db.attachedDatabase,
        _db.runtimeProfilesTable,
      );
}
