// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paired_device_dao.dart';

// ignore_for_file: type=lint
mixin _$PairedDeviceDaoMixin on DatabaseAccessor<AppDatabase> {
  $PairedDevicesTableTable get pairedDevicesTable =>
      attachedDatabase.pairedDevicesTable;
  PairedDeviceDaoManager get managers => PairedDeviceDaoManager(this);
}

class PairedDeviceDaoManager {
  final _$PairedDeviceDaoMixin _db;
  PairedDeviceDaoManager(this._db);
  $$PairedDevicesTableTableTableManager get pairedDevicesTable =>
      $$PairedDevicesTableTableTableManager(
        _db.attachedDatabase,
        _db.pairedDevicesTable,
      );
}
