import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

/// Streaks table.
@TableIndex(name: 'idx_streaks_agent_type', columns: {#agentId, #streakType}, unique: true)
class StreaksTable extends Table {
  /// Id.
  TextColumn get id => text()();
  /// Agent id.
  TextColumn get agentId => text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();
  /// Streak type.
  TextColumn get streakType => text()();
  /// Current count.
  IntColumn get currentCount => integer().withDefault(const Constant(0))();
  /// Best count.
  IntColumn get bestCount => integer().withDefault(const Constant(0))();
  /// Last date.
  DateTimeColumn get lastDate => dateTime().nullable()();
  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

