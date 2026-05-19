// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_dao.dart';

// ignore_for_file: type=lint
mixin _$RepoDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReposTableTable get reposTable => attachedDatabase.reposTable;
  RepoDaoManager get managers => RepoDaoManager(this);
}

class RepoDaoManager {
  final _$RepoDaoMixin _db;
  RepoDaoManager(this._db);
  $$ReposTableTableTableManager get reposTable =>
      $$ReposTableTableTableManager(_db.attachedDatabase, _db.reposTable);
}
