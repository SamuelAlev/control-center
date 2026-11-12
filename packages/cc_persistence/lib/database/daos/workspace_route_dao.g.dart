// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_route_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceRouteDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $UsersTableTable get usersTable => attachedDatabase.usersTable;
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $WorkspaceRoutesTableTable get workspaceRoutesTable =>
      attachedDatabase.workspaceRoutesTable;
  $InviteSecureRoutesTableTable get inviteSecureRoutesTable =>
      attachedDatabase.inviteSecureRoutesTable;
  $ServerMetaTableTable get serverMetaTable => attachedDatabase.serverMetaTable;
  WorkspaceRouteDaoManager get managers => WorkspaceRouteDaoManager(this);
}

class WorkspaceRouteDaoManager {
  final _$WorkspaceRouteDaoMixin _db;
  WorkspaceRouteDaoManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db.attachedDatabase, _db.usersTable);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$WorkspaceRoutesTableTableTableManager get workspaceRoutesTable =>
      $$WorkspaceRoutesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceRoutesTable,
      );
  $$InviteSecureRoutesTableTableTableManager get inviteSecureRoutesTable =>
      $$InviteSecureRoutesTableTableTableManager(
        _db.attachedDatabase,
        _db.inviteSecureRoutesTable,
      );
  $$ServerMetaTableTableTableManager get serverMetaTable =>
      $$ServerMetaTableTableTableManager(
        _db.attachedDatabase,
        _db.serverMetaTable,
      );
}
