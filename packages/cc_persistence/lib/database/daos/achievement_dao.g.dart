// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_dao.dart';

// ignore_for_file: type=lint
mixin _$AchievementDaoMixin on DatabaseAccessor<AppDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $AchievementsTableTable get achievementsTable =>
      attachedDatabase.achievementsTable;
  AchievementDaoManager get managers => AchievementDaoManager(this);
}

class AchievementDaoManager {
  final _$AchievementDaoMixin _db;
  AchievementDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$AchievementsTableTableTableManager get achievementsTable =>
      $$AchievementsTableTableTableManager(
        _db.attachedDatabase,
        _db.achievementsTable,
      );
}
