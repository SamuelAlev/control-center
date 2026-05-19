// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_access_grant_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryAccessGrantDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $MemoryAccessGrantsTableTable get memoryAccessGrantsTable =>
      attachedDatabase.memoryAccessGrantsTable;
  MemoryAccessGrantDaoManager get managers => MemoryAccessGrantDaoManager(this);
}

class MemoryAccessGrantDaoManager {
  final _$MemoryAccessGrantDaoMixin _db;
  MemoryAccessGrantDaoManager(this._db);
  $$MemoryAccessGrantsTableTableTableManager get memoryAccessGrantsTable =>
      $$MemoryAccessGrantsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryAccessGrantsTable,
      );
}
