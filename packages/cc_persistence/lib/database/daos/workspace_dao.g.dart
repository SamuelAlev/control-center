// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $WorkspaceReposTableTable get workspaceReposTable =>
      attachedDatabase.workspaceReposTable;
  $ReposTableTable get reposTable => attachedDatabase.reposTable;
  WorkspaceDaoManager get managers => WorkspaceDaoManager(this);
}

class WorkspaceDaoManager {
  final _$WorkspaceDaoMixin _db;
  WorkspaceDaoManager(this._db);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$WorkspaceReposTableTableTableManager get workspaceReposTable =>
      $$WorkspaceReposTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceReposTable,
      );
  $$ReposTableTableTableManager get reposTable =>
      $$ReposTableTableTableManager(_db.attachedDatabase, _db.reposTable);
}
