import 'package:control_center/core/database/tables/agents.dart';
import 'package:drift/drift.dart';

/// Achievements table.
@TableIndex(name: 'idx_achievements_agent_badge', columns: {#agentId, #badgeKey}, unique: true)
class AchievementsTable extends Table {
  /// Id.
  TextColumn get id => text()();
  /// Agent id.
  TextColumn get agentId => text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();
  /// Badge key.
  TextColumn get badgeKey => text()();
  /// Unlocked at.
  DateTimeColumn get unlockedAt => dateTime().withDefault(currentDateAndTime)();
  /// Metadata.
  TextColumn get metadata => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

