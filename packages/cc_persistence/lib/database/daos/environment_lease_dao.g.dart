// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environment_lease_dao.dart';

// ignore_for_file: type=lint
mixin _$EnvironmentLeaseDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $EnvironmentSlotLeasesTableTable get environmentSlotLeasesTable =>
      attachedDatabase.environmentSlotLeasesTable;
  EnvironmentLeaseDaoManager get managers => EnvironmentLeaseDaoManager(this);
}

class EnvironmentLeaseDaoManager {
  final _$EnvironmentLeaseDaoMixin _db;
  EnvironmentLeaseDaoManager(this._db);
  $$EnvironmentSlotLeasesTableTableTableManager
  get environmentSlotLeasesTable =>
      $$EnvironmentSlotLeasesTableTableTableManager(
        _db.attachedDatabase,
        _db.environmentSlotLeasesTable,
      );
}
