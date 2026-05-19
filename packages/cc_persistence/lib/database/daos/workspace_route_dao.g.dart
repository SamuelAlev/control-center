// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_route_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceRouteDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $WorkspaceRoutesTableTable get workspaceRoutesTable =>
      attachedDatabase.workspaceRoutesTable;
  $ServerMetaTableTable get serverMetaTable => attachedDatabase.serverMetaTable;
  WorkspaceRouteDaoManager get managers => WorkspaceRouteDaoManager(this);
}

class WorkspaceRouteDaoManager {
  final _$WorkspaceRouteDaoMixin _db;
  WorkspaceRouteDaoManager(this._db);
  $$WorkspaceRoutesTableTableTableManager get workspaceRoutesTable =>
      $$WorkspaceRoutesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceRoutesTable,
      );
  $$ServerMetaTableTableTableManager get serverMetaTable =>
      $$ServerMetaTableTableTableManager(
        _db.attachedDatabase,
        _db.serverMetaTable,
      );
}
