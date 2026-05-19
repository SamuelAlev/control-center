// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_invite_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceInviteDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $WorkspaceInvitesTableTable get workspaceInvitesTable =>
      attachedDatabase.workspaceInvitesTable;
  WorkspaceInviteDaoManager get managers => WorkspaceInviteDaoManager(this);
}

class WorkspaceInviteDaoManager {
  final _$WorkspaceInviteDaoMixin _db;
  WorkspaceInviteDaoManager(this._db);
  $$WorkspaceInvitesTableTableTableManager get workspaceInvitesTable =>
      $$WorkspaceInvitesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceInvitesTable,
      );
}
