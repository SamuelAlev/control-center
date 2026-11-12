// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_dao.dart';

// ignore_for_file: type=lint
mixin _$EnvironmentDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ReposTableTable get reposTable => attachedDatabase.reposTable;
  $EnvironmentDefinitionsTableTable get environmentDefinitionsTable =>
      attachedDatabase.environmentDefinitionsTable;
  $BudgetPolicyTableTable get budgetPolicyTable =>
      attachedDatabase.budgetPolicyTable;
  $RuntimeProfilesTableTable get runtimeProfilesTable =>
      attachedDatabase.runtimeProfilesTable;
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $RigSessionsTableTable get rigSessionsTable =>
      attachedDatabase.rigSessionsTable;
  $SpaceEnvironmentsTableTable get spaceEnvironmentsTable =>
      attachedDatabase.spaceEnvironmentsTable;
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $EnvironmentRunsTableTable get environmentRunsTable =>
      attachedDatabase.environmentRunsTable;
  EnvironmentDaoManager get managers => EnvironmentDaoManager(this);
}

class EnvironmentDaoManager {
  final _$EnvironmentDaoMixin _db;
  EnvironmentDaoManager(this._db);
  $$ReposTableTableTableManager get reposTable =>
      $$ReposTableTableTableManager(_db.attachedDatabase, _db.reposTable);
  $$EnvironmentDefinitionsTableTableTableManager
  get environmentDefinitionsTable =>
      $$EnvironmentDefinitionsTableTableTableManager(
        _db.attachedDatabase,
        _db.environmentDefinitionsTable,
      );
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
  $$SpaceEnvironmentsTableTableTableManager get spaceEnvironmentsTable =>
      $$SpaceEnvironmentsTableTableTableManager(
        _db.attachedDatabase,
        _db.spaceEnvironmentsTable,
      );
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$EnvironmentRunsTableTableTableManager get environmentRunsTable =>
      $$EnvironmentRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.environmentRunsTable,
      );
}
