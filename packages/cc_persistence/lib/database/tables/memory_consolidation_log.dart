import 'package:cc_persistence/database/tables/agents.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_consolidation_log_agent', columns: {#agentId})
/// One row per consolidation (`sleep`) pass: a workspace-scoped audit of how
/// many hot items were considered, rolled to durable facts and evicted.
class MemoryConsolidationLogTable extends Table {
  /// Unique pass identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Agent whose working memory was consolidated, when scoped to one.
  /// `ON DELETE SET NULL`: the pass stays in the audit after its agent goes.
  TextColumn get agentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Working items examined.
  IntColumn get itemsConsidered => integer().withDefault(const Constant(0))();

  /// Durable facts created.
  IntColumn get factsCreated => integer().withDefault(const Constant(0))();

  /// Durable facts re-asserted (Bayesian update / dedup).
  IntColumn get factsUpdated => integer().withDefault(const Constant(0))();

  /// Conflicts detected during the pass.
  IntColumn get conflictsDetected => integer().withDefault(const Constant(0))();

  /// Hot items evicted by TTL/limit without consolidation.
  IntColumn get evicted => integer().withDefault(const Constant(0))();

  /// When the pass started.
  DateTimeColumn get startedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the pass finished.
  DateTimeColumn get finishedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'memory_consolidation_log';

  @override
  Set<Column> get primaryKey => {id};
}
