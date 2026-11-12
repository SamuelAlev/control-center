// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_fact_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryFactDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $MemoryFactsTableTable get memoryFactsTable =>
      attachedDatabase.memoryFactsTable;
  $MemoryFactEmbeddingsTableTable get memoryFactEmbeddingsTable =>
      attachedDatabase.memoryFactEmbeddingsTable;
  MemoryFactDaoManager get managers => MemoryFactDaoManager(this);
}

class MemoryFactDaoManager {
  final _$MemoryFactDaoMixin _db;
  MemoryFactDaoManager(this._db);
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
  $$MemoryFactEmbeddingsTableTableTableManager get memoryFactEmbeddingsTable =>
      $$MemoryFactEmbeddingsTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryFactEmbeddingsTable,
      );
}
