// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evals_dao.dart';

// ignore_for_file: type=lint
mixin _$EvalsDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SessionRecordingsTableTable get sessionRecordingsTable =>
      attachedDatabase.sessionRecordingsTable;
  $GoldenSessionsTableTable get goldenSessionsTable =>
      attachedDatabase.goldenSessionsTable;
  $EvalSuitesTableTable get evalSuitesTable => attachedDatabase.evalSuitesTable;
  $EvalRunsTableTable get evalRunsTable => attachedDatabase.evalRunsTable;
  $AgentConfigVersionsTableTable get agentConfigVersionsTable =>
      attachedDatabase.agentConfigVersionsTable;
  $SkillEvalCampaignsTableTable get skillEvalCampaignsTable =>
      attachedDatabase.skillEvalCampaignsTable;
  $SkillEvalAttemptsTableTable get skillEvalAttemptsTable =>
      attachedDatabase.skillEvalAttemptsTable;
  $SkillEvalPoliciesTableTable get skillEvalPoliciesTable =>
      attachedDatabase.skillEvalPoliciesTable;
  EvalsDaoManager get managers => EvalsDaoManager(this);
}

class EvalsDaoManager {
  final _$EvalsDaoMixin _db;
  EvalsDaoManager(this._db);
  $$SessionRecordingsTableTableTableManager get sessionRecordingsTable =>
      $$SessionRecordingsTableTableTableManager(
        _db.attachedDatabase,
        _db.sessionRecordingsTable,
      );
  $$GoldenSessionsTableTableTableManager get goldenSessionsTable =>
      $$GoldenSessionsTableTableTableManager(
        _db.attachedDatabase,
        _db.goldenSessionsTable,
      );
  $$EvalSuitesTableTableTableManager get evalSuitesTable =>
      $$EvalSuitesTableTableTableManager(
        _db.attachedDatabase,
        _db.evalSuitesTable,
      );
  $$EvalRunsTableTableTableManager get evalRunsTable =>
      $$EvalRunsTableTableTableManager(_db.attachedDatabase, _db.evalRunsTable);
  $$AgentConfigVersionsTableTableTableManager get agentConfigVersionsTable =>
      $$AgentConfigVersionsTableTableTableManager(
        _db.attachedDatabase,
        _db.agentConfigVersionsTable,
      );
  $$SkillEvalCampaignsTableTableTableManager get skillEvalCampaignsTable =>
      $$SkillEvalCampaignsTableTableTableManager(
        _db.attachedDatabase,
        _db.skillEvalCampaignsTable,
      );
  $$SkillEvalAttemptsTableTableTableManager get skillEvalAttemptsTable =>
      $$SkillEvalAttemptsTableTableTableManager(
        _db.attachedDatabase,
        _db.skillEvalAttemptsTable,
      );
  $$SkillEvalPoliciesTableTableTableManager get skillEvalPoliciesTable =>
      $$SkillEvalPoliciesTableTableTableManager(
        _db.attachedDatabase,
        _db.skillEvalPoliciesTable,
      );
}
