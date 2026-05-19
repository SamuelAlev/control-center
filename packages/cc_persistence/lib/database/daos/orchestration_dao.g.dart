// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orchestration_dao.dart';

// ignore_for_file: type=lint
mixin _$OrchestrationDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $OrchestrationsTableTable get orchestrationsTable =>
      attachedDatabase.orchestrationsTable;
  OrchestrationDaoManager get managers => OrchestrationDaoManager(this);
}

class OrchestrationDaoManager {
  final _$OrchestrationDaoMixin _db;
  OrchestrationDaoManager(this._db);
  $$OrchestrationsTableTableTableManager get orchestrationsTable =>
      $$OrchestrationsTableTableTableManager(
        _db.attachedDatabase,
        _db.orchestrationsTable,
      );
}
