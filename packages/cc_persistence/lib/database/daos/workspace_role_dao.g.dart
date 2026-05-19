// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_role_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceRoleDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $WorkspaceRolesTableTable get workspaceRolesTable =>
      attachedDatabase.workspaceRolesTable;
  WorkspaceRoleDaoManager get managers => WorkspaceRoleDaoManager(this);
}

class WorkspaceRoleDaoManager {
  final _$WorkspaceRoleDaoMixin _db;
  WorkspaceRoleDaoManager(this._db);
  $$WorkspaceRolesTableTableTableManager get workspaceRolesTable =>
      $$WorkspaceRolesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceRolesTable,
      );
}
