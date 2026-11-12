// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_conflict_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryConflictDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $MemoryFactsTableTable get memoryFactsTable =>
      attachedDatabase.memoryFactsTable;
  $MemoryConflictsTableTable get memoryConflictsTable =>
      attachedDatabase.memoryConflictsTable;
  MemoryConflictDaoManager get managers => MemoryConflictDaoManager(this);
}

class MemoryConflictDaoManager {
  final _$MemoryConflictDaoMixin _db;
  MemoryConflictDaoManager(this._db);
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
  $$MemoryFactsTableTableTableManager get memoryFactsTable =>
      $$MemoryFactsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryFactsTable,
      );
  $$MemoryConflictsTableTableTableManager get memoryConflictsTable =>
      $$MemoryConflictsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryConflictsTable,
      );
}
