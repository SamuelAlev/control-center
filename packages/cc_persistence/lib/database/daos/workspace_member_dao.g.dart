// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_member_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceMemberDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $WorkspaceMembersTableTable get workspaceMembersTable =>
      attachedDatabase.workspaceMembersTable;
  $ReposTableTable get reposTable => attachedDatabase.reposTable;
  $WorkspaceMemberRepoGrantsTableTable get workspaceMemberRepoGrantsTable =>
      attachedDatabase.workspaceMemberRepoGrantsTable;
  WorkspaceMemberDaoManager get managers => WorkspaceMemberDaoManager(this);
}

class WorkspaceMemberDaoManager {
  final _$WorkspaceMemberDaoMixin _db;
  WorkspaceMemberDaoManager(this._db);
  $$WorkspaceMembersTableTableTableManager get workspaceMembersTable =>
      $$WorkspaceMembersTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceMembersTable,
      );
  $$ReposTableTableTableManager get reposTable =>
      $$ReposTableTableTableManager(_db.attachedDatabase, _db.reposTable);
  $$WorkspaceMemberRepoGrantsTableTableTableManager
  get workspaceMemberRepoGrantsTable =>
      $$WorkspaceMemberRepoGrantsTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceMemberRepoGrantsTable,
      );
}
