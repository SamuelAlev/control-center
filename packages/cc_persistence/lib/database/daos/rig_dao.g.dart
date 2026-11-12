// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rig_dao.dart';

// ignore_for_file: type=lint
mixin _$RigDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $RigSessionsTableTable get rigSessionsTable =>
      attachedDatabase.rigSessionsTable;
  $RigActionLogTableTable get rigActionLogTable =>
      attachedDatabase.rigActionLogTable;
  RigDaoManager get managers => RigDaoManager(this);
}

class RigDaoManager {
  final _$RigDaoMixin _db;
  RigDaoManager(this._db);
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
  $$RigSessionsTableTableTableManager get rigSessionsTable =>
      $$RigSessionsTableTableTableManager(
        _db.attachedDatabase,
        _db.rigSessionsTable,
      );
  $$RigActionLogTableTableTableManager get rigActionLogTable =>
      $$RigActionLogTableTableTableManager(
        _db.attachedDatabase,
        _db.rigActionLogTable,
      );
}
