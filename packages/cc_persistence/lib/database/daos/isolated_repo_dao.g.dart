// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isolated_repo_dao.dart';

// ignore_for_file: type=lint
mixin _$IsolatedRepoDaoMixin on DatabaseAccessor<AppDatabase> {
  $IsolatedReposTableTable get isolatedReposTable =>
      attachedDatabase.isolatedReposTable;
  IsolatedRepoDaoManager get managers => IsolatedRepoDaoManager(this);
}

class IsolatedRepoDaoManager {
  final _$IsolatedRepoDaoMixin _db;
  IsolatedRepoDaoManager(this._db);
  $$IsolatedReposTableTableTableManager get isolatedReposTable =>
      $$IsolatedReposTableTableTableManager(
        _db.attachedDatabase,
        _db.isolatedReposTable,
      );
}
