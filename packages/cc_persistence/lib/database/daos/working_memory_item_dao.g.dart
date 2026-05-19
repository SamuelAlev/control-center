// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'working_memory_item_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkingMemoryItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $WorkingMemoryItemsTableTable get workingMemoryItemsTable =>
      attachedDatabase.workingMemoryItemsTable;
  WorkingMemoryItemDaoManager get managers => WorkingMemoryItemDaoManager(this);
}

class WorkingMemoryItemDaoManager {
  final _$WorkingMemoryItemDaoMixin _db;
  WorkingMemoryItemDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$WorkingMemoryItemsTableTableTableManager get workingMemoryItemsTable =>
      $$WorkingMemoryItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.workingMemoryItemsTable,
      );
}
