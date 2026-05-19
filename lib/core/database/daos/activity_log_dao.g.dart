// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log_dao.dart';

// ignore_for_file: type=lint
mixin _$ActivityLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $ActivityLogTableTable get activityLogTable =>
      attachedDatabase.activityLogTable;
  ActivityLogDaoManager get managers => ActivityLogDaoManager(this);
}

class ActivityLogDaoManager {
  final _$ActivityLogDaoMixin _db;
  ActivityLogDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$ActivityLogTableTableTableManager get activityLogTable =>
      $$ActivityLogTableTableTableManager(
        _db.attachedDatabase,
        _db.activityLogTable,
      );
}
