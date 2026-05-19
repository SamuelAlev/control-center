// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_fact_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryFactDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $MemoryFactsTableTable get memoryFactsTable =>
      attachedDatabase.memoryFactsTable;
  MemoryFactDaoManager get managers => MemoryFactDaoManager(this);
}

class MemoryFactDaoManager {
  final _$MemoryFactDaoMixin _db;
  MemoryFactDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$MemoryFactsTableTableTableManager get memoryFactsTable =>
      $$MemoryFactsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryFactsTable,
      );
}
