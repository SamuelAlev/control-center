// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_setting_dao.dart';

// ignore_for_file: type=lint
mixin _$ServerSettingDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $ServerSettingsTableTable get serverSettingsTable =>
      attachedDatabase.serverSettingsTable;
  ServerSettingDaoManager get managers => ServerSettingDaoManager(this);
}

class ServerSettingDaoManager {
  final _$ServerSettingDaoMixin _db;
  ServerSettingDaoManager(this._db);
  $$ServerSettingsTableTableTableManager get serverSettingsTable =>
      $$ServerSettingsTableTableTableManager(
        _db.attachedDatabase,
        _db.serverSettingsTable,
      );
}
