// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_dao.dart';

// ignore_for_file: type=lint
mixin _$FleetDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $UsersTableTable get usersTable => attachedDatabase.usersTable;
  $WorkspacesTableTable get workspacesTable => attachedDatabase.workspacesTable;
  $PairedDevicesTableTable get pairedDevicesTable =>
      attachedDatabase.pairedDevicesTable;
  $WorkersTableTable get workersTable => attachedDatabase.workersTable;
  $JobsTableTable get jobsTable => attachedDatabase.jobsTable;
  $PlacementLogTableTable get placementLogTable =>
      attachedDatabase.placementLogTable;
  FleetDaoManager get managers => FleetDaoManager(this);
}

class FleetDaoManager {
  final _$FleetDaoMixin _db;
  FleetDaoManager(this._db);
  $$UsersTableTableTableManager get usersTable =>
      $$UsersTableTableTableManager(_db.attachedDatabase, _db.usersTable);
  $$WorkspacesTableTableTableManager get workspacesTable =>
      $$WorkspacesTableTableTableManager(
        _db.attachedDatabase,
        _db.workspacesTable,
      );
  $$PairedDevicesTableTableTableManager get pairedDevicesTable =>
      $$PairedDevicesTableTableTableManager(
        _db.attachedDatabase,
        _db.pairedDevicesTable,
      );
  $$WorkersTableTableTableManager get workersTable =>
      $$WorkersTableTableTableManager(_db.attachedDatabase, _db.workersTable);
  $$JobsTableTableTableManager get jobsTable =>
      $$JobsTableTableTableManager(_db.attachedDatabase, _db.jobsTable);
  $$PlacementLogTableTableTableManager get placementLogTable =>
      $$PlacementLogTableTableTableManager(
        _db.attachedDatabase,
        _db.placementLogTable,
      );
}
