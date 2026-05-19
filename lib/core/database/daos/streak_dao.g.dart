// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_dao.dart';

// ignore_for_file: type=lint
mixin _$StreakDaoMixin on DatabaseAccessor<AppDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $StreaksTableTable get streaksTable => attachedDatabase.streaksTable;
  StreakDaoManager get managers => StreakDaoManager(this);
}

class StreakDaoManager {
  final _$StreakDaoMixin _db;
  StreakDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$StreaksTableTableTableManager get streaksTable =>
      $$StreaksTableTableTableManager(_db.attachedDatabase, _db.streaksTable);
}
