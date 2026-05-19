// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_dao.dart';

// ignore_for_file: type=lint
mixin _$ProjectDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTableTable get projectsTable => attachedDatabase.projectsTable;
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $TicketsTableTable get ticketsTable => attachedDatabase.ticketsTable;
  ProjectDaoManager get managers => ProjectDaoManager(this);
}

class ProjectDaoManager {
  final _$ProjectDaoMixin _db;
  ProjectDaoManager(this._db);
  $$ProjectsTableTableTableManager get projectsTable =>
      $$ProjectsTableTableTableManager(_db.attachedDatabase, _db.projectsTable);
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$TicketsTableTableTableManager get ticketsTable =>
      $$TicketsTableTableTableManager(_db.attachedDatabase, _db.ticketsTable);
}
