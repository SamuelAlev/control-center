import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

/// Agent daily stats table.
@TableIndex(name: 'idx_agent_daily_stats_agent_date', columns: {#agentId, #date}, unique: true)
class AgentDailyStatsTable extends Table {
  /// Id.
  TextColumn get id => text()();
  /// Agent id.
  TextColumn get agentId => text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();
  /// Date.
  DateTimeColumn get date => dateTime()();
  /// Runs completed.
  IntColumn get runsCompleted => integer().withDefault(const Constant(0))();
  /// Runs errored.
  IntColumn get runsErrored => integer().withDefault(const Constant(0))();
  /// Total run duration ms.
  IntColumn get totalRunDurationMs => integer().withDefault(const Constant(0))();
  /// Prs created.
  IntColumn get prsCreated => integer().withDefault(const Constant(0))();
  /// Prs merged.
  IntColumn get prsMerged => integer().withDefault(const Constant(0))();
  /// Reviews completed.
  IntColumn get reviewsCompleted => integer().withDefault(const Constant(0))();
  /// Blocking comments.
  IntColumn get blockingComments => integer().withDefault(const Constant(0))();
  /// Lines added.
  IntColumn get linesAdded => integer().withDefault(const Constant(0))();
  /// Lines deleted.
  IntColumn get linesDeleted => integer().withDefault(const Constant(0))();
  /// Xp earned.
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();
  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

