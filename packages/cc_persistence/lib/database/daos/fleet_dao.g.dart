// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_dao.dart';

// ignore_for_file: type=lint
mixin _$FleetDaoMixin on DatabaseAccessor<GlobalDatabase> {
  $WorkersTableTable get workersTable => attachedDatabase.workersTable;
  $JobsTableTable get jobsTable => attachedDatabase.jobsTable;
  $PlacementLogTableTable get placementLogTable =>
      attachedDatabase.placementLogTable;
  FleetDaoManager get managers => FleetDaoManager(this);
}

class FleetDaoManager {
  final _$FleetDaoMixin _db;
  FleetDaoManager(this._db);
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
