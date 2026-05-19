// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_transcript_dao.dart';

// ignore_for_file: type=lint
mixin _$RunTranscriptDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $AgentRunLogsTableTable get agentRunLogsTable =>
      attachedDatabase.agentRunLogsTable;
  $RunTranscriptsTableTable get runTranscriptsTable =>
      attachedDatabase.runTranscriptsTable;
  RunTranscriptDaoManager get managers => RunTranscriptDaoManager(this);
}

class RunTranscriptDaoManager {
  final _$RunTranscriptDaoMixin _db;
  RunTranscriptDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$AgentRunLogsTableTableTableManager get agentRunLogsTable =>
      $$AgentRunLogsTableTableTableManager(
        _db.attachedDatabase,
        _db.agentRunLogsTable,
      );
  $$RunTranscriptsTableTableTableManager get runTranscriptsTable =>
      $$RunTranscriptsTableTableTableManager(
        _db.attachedDatabase,
        _db.runTranscriptsTable,
      );
}
