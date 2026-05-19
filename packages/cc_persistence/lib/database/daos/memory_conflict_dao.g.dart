// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_conflict_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryConflictDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $MemoryConflictsTableTable get memoryConflictsTable =>
      attachedDatabase.memoryConflictsTable;
  MemoryConflictDaoManager get managers => MemoryConflictDaoManager(this);
}

class MemoryConflictDaoManager {
  final _$MemoryConflictDaoMixin _db;
  MemoryConflictDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$MemoryConflictsTableTableTableManager get memoryConflictsTable =>
      $$MemoryConflictsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryConflictsTable,
      );
}
