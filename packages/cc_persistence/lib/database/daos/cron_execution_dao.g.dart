// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cron_execution_dao.dart';

// ignore_for_file: type=lint
mixin _$CronExecutionDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $CronExecutionsTableTable get cronExecutionsTable =>
      attachedDatabase.cronExecutionsTable;
  CronExecutionDaoManager get managers => CronExecutionDaoManager(this);
}

class CronExecutionDaoManager {
  final _$CronExecutionDaoMixin _db;
  CronExecutionDaoManager(this._db);
  $$CronExecutionsTableTableTableManager get cronExecutionsTable =>
      $$CronExecutionsTableTableTableManager(
        _db.attachedDatabase,
        _db.cronExecutionsTable,
      );
}
