// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_dao.dart';

// ignore_for_file: type=lint
mixin _$CacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachesTableTable get cachesTable => attachedDatabase.cachesTable;
  CacheDaoManager get managers => CacheDaoManager(this);
}

class CacheDaoManager {
  final _$CacheDaoMixin _db;
  CacheDaoManager(this._db);
  $$CachesTableTableTableManager get cachesTable =>
      $$CachesTableTableTableManager(_db.attachedDatabase, _db.cachesTable);
}
