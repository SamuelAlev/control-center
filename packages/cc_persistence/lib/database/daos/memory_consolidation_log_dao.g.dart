// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_consolidation_log_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryConsolidationLogDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $MemoryConsolidationLogTableTable get memoryConsolidationLogTable =>
      attachedDatabase.memoryConsolidationLogTable;
  MemoryConsolidationLogDaoManager get managers =>
      MemoryConsolidationLogDaoManager(this);
}

class MemoryConsolidationLogDaoManager {
  final _$MemoryConsolidationLogDaoMixin _db;
  MemoryConsolidationLogDaoManager(this._db);
  $$MemoryConsolidationLogTableTableTableManager
  get memoryConsolidationLogTable =>
      $$MemoryConsolidationLogTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryConsolidationLogTable,
      );
}
