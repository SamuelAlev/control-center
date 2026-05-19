// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_studio_dao.dart';

// ignore_for_file: type=lint
mixin _$PlanStudioDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $OrchestrationsTableTable get orchestrationsTable =>
      attachedDatabase.orchestrationsTable;
  $OrchestrationRevisionsTableTable get orchestrationRevisionsTable =>
      attachedDatabase.orchestrationRevisionsTable;
  $PlanDocumentsTableTable get planDocumentsTable =>
      attachedDatabase.planDocumentsTable;
  $PlaybooksTableTable get playbooksTable => attachedDatabase.playbooksTable;
  PlanStudioDaoManager get managers => PlanStudioDaoManager(this);
}

class PlanStudioDaoManager {
  final _$PlanStudioDaoMixin _db;
  PlanStudioDaoManager(this._db);
  $$OrchestrationsTableTableTableManager get orchestrationsTable =>
      $$OrchestrationsTableTableTableManager(
        _db.attachedDatabase,
        _db.orchestrationsTable,
      );
  $$OrchestrationRevisionsTableTableTableManager
  get orchestrationRevisionsTable =>
      $$OrchestrationRevisionsTableTableTableManager(
        _db.attachedDatabase,
        _db.orchestrationRevisionsTable,
      );
  $$PlanDocumentsTableTableTableManager get planDocumentsTable =>
      $$PlanDocumentsTableTableTableManager(
        _db.attachedDatabase,
        _db.planDocumentsTable,
      );
  $$PlaybooksTableTableTableManager get playbooksTable =>
      $$PlaybooksTableTableTableManager(
        _db.attachedDatabase,
        _db.playbooksTable,
      );
}
