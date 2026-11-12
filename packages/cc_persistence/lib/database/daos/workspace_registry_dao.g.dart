// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_registry_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceRegistryDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $UsersTableTable get usersTable => attachedDatabase.usersTable;
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  WorkspaceRegistryDaoManager get managers => WorkspaceRegistryDaoManager(this);
}

class WorkspaceRegistryDaoManager {
  final _$WorkspaceRegistryDaoMixin _db;
  WorkspaceRegistryDaoManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db.attachedDatabase, _db.usersTable);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
}
