// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workspace_setting_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkspaceSettingDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $WorkspaceSettingsTableTable get workspaceSettingsTable =>
      attachedDatabase.workspaceSettingsTable;
  WorkspaceSettingDaoManager get managers => WorkspaceSettingDaoManager(this);
}

class WorkspaceSettingDaoManager {
  final _$WorkspaceSettingDaoMixin _db;
  WorkspaceSettingDaoManager(this._db);
  $$WorkspaceSettingsTableTableTableManager get workspaceSettingsTable =>
      $$WorkspaceSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.workspaceSettingsTable,
      );
}
