// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_dao.dart';

// ignore_for_file: type=lint
mixin _$AnalyticsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AgentsTableTable get agentsTable => attachedDatabase.agentsTable;
  $AgentDailyStatsTableTable get agentDailyStatsTable =>
      attachedDatabase.agentDailyStatsTable;
  AnalyticsDaoManager get managers => AnalyticsDaoManager(this);
}

class AnalyticsDaoManager {
  final _$AnalyticsDaoMixin _db;
  AnalyticsDaoManager(this._db);
  $$AgentsTableTableTableManager get agentsTable =>
      $$AgentsTableTableTableManager(_db.attachedDatabase, _db.agentsTable);
  $$AgentDailyStatsTableTableTableManager get agentDailyStatsTable =>
      $$AgentDailyStatsTableTableTableManager(
        _db.attachedDatabase,
        _db.agentDailyStatsTable,
      );
}
