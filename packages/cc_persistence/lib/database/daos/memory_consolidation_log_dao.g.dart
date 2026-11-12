// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_consolidation_log_dao.dart';

// ignore_for_file: type=lint
mixin _$MemoryConsolidationLogDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $MemoryConsolidationLogTableTable get memoryConsolidationLogTable =>
      attachedDatabase.memoryConsolidationLogTable;
  MemoryConsolidationLogDaoManager get managers =>
      MemoryConsolidationLogDaoManager(this);
}

class MemoryConsolidationLogDaoManager {
  final _$MemoryConsolidationLogDaoMixin _db;
  MemoryConsolidationLogDaoManager(this._db);
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
  $$MemoryConsolidationLogTableTableTableManager
  get memoryConsolidationLogTable =>
      $$MemoryConsolidationLogTableTableTableManager(
        _db.attachedDatabase,
        _db.memoryConsolidationLogTable,
      );
}
