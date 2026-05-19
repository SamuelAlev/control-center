import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_consolidation_log_workspaceId', columns: {#workspaceId})
/// One row per consolidation (`sleep`) pass: a workspace-scoped audit of how
/// many hot items were considered, rolled to durable facts, and evicted.
class MemoryConsolidationLogTable extends Table {
  /// Unique pass identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Agent whose working memory was consolidated, when scoped to one.
  TextColumn get agentId => text().nullable()();
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
  Set<Column> get primaryKey => {id};
}