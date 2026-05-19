// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_consolidation_log_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryConsolidationLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $MemoryConsolidationLogTableTable get memoryConsolidationLogTable =>
      attachedDatabase.memoryConsolidationLogTable;
  MemoryConsolidationLogDaoManager get managers =>
      MemoryConsolidationLogDaoManager(this);
}

class MemoryConsolidationLogDaoManager {
  final _$MemoryConsolidationLogDaoMixin _db;
  MemoryConsolidationLogDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$MemoryConsolidationLogTableTableTableManager
  get memoryConsolidationLogTable =>
      $$MemoryConsolidationLogTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryConsolidationLogTable,
      );
}
