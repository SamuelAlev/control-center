import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_working_memory_items_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_working_memory_items_agent', columns: {#agentId})
/// The hot, session-scoped working-memory tier (TTL + count bounded), which a
/// consolidation `sleep()` pass rolls into the durable `MemoryFactsTable`.
class WorkingMemoryItemsTable extends Table {
  /// Unique item identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Agent this hot item belongs to.
  TextColumn get agentId => text()();
  /// Optional session/run grouping key.
  TextColumn get sessionId => text().nullable()();
  /// Item content.
  TextColumn get content => text()();
  /// Inferred memory type (default `observation`).
  TextColumn get memoryType =>
      text().withDefault(const Constant('observation'))();
  /// Provenance (default `inferred`).
  TextColumn get veracity => text().withDefault(const Constant('inferred'))();
  /// Importance in `[0,1]`; higher items survive eviction longer.
  RealColumn get importance => real().withDefault(const Constant(0.5))();
  /// When created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Optional TTL expiry; eviction drops items past this time.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}