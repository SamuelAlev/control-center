// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodic_edge_dao.dart';

// ignore_for_file: type=lint
mixin _$EpisodicEdgeDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $MemoryFactsTableTable get memoryFactsTable =>
      attachedDatabase.memoryFactsTable;
  $EpisodicEdgesTableTable get episodicEdgesTable =>
      attachedDatabase.episodicEdgesTable;
  EpisodicEdgeDaoManager get managers => EpisodicEdgeDaoManager(this);
}

class EpisodicEdgeDaoManager {
  final _$EpisodicEdgeDaoMixin _db;
  EpisodicEdgeDaoManager(this._db);
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
  $$EpisodicEdgesTableTableTableManager get episodicEdgesTable =>
      $$EpisodicEdgesTableTableTableManager(
        _db.attachedDatabase,
        _db.episodicEdgesTable,
      );
}
