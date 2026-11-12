// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'working_memory_item_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkingMemoryItemDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $WorkingMemoryItemsTableTable get workingMemoryItemsTable =>
      attachedDatabase.workingMemoryItemsTable;
  WorkingMemoryItemDaoManager get managers => WorkingMemoryItemDaoManager(this);
}

class WorkingMemoryItemDaoManager {
  final _$WorkingMemoryItemDaoMixin _db;
  WorkingMemoryItemDaoManager(this._db);
  $$BudgetPolicyTableTableTableManager get budgetPolicyTable =>
      $$BudgetPolicyTableTableTableManager(
        _db.attachedDatabase,
        _db.budgetPolicyTable,
      );
  $$RuntimeProfilesTableTableTableManager get runtimeProfilesTable =>
      $$RuntimeProfilesTableTableTableManager(
        _db.attachedDatabase,
        _db.runtimeProfilesTable,
      );
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$WorkingMemoryItemsTableTableTableManager get workingMemoryItemsTable =>
      $$WorkingMemoryItemsTableTableTableManager(
        _db.attachedDatabase,
        _db.workingMemoryItemsTable,
      );
}
