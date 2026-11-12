import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_working_memory_items_agent', columns: {#agentId})
/// The hot, session-scoped working-memory tier (TTL + count bounded), which a
/// consolidation `sleep()` pass rolls into the durable `MemoryFactsTable`.
class WorkingMemoryItemsTable extends Table {
  /// Unique item identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Agent this hot item belongs to. `ON DELETE CASCADE`: the hot tier is
  /// the agent's own scratch state.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// Optional session/run grouping key. No foreign key: a free grouping key
  /// the caller chooses.
  TextColumn get sessionId => text().nullable()();

  /// Item content.
  TextColumn get content => text()();

  /// Inferred memory type (default `observation`; `MemoryType.wireName`).
  TextColumn get memoryType => text()
      .check(
        // ignore: recursive_getters
        memoryType.isIn(SpacesStoredValues.memoryType),
      )
      .withDefault(const Constant('observation'))();

  /// Provenance (default `inferred`; `MemoryVeracity.wireName`).
  TextColumn get veracity => text()
      .check(
        // ignore: recursive_getters
        veracity.isIn(SpacesStoredValues.memoryVeracity),
      )
      .withDefault(const Constant('inferred'))();

  /// Importance in `[0,1]`; higher items survive eviction longer.
  RealColumn get importance => real().withDefault(const Constant(0.5))();

  /// When created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Optional TTL expiry; eviction drops items past this time.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  String get tableName => 'working_memory_items';

  @override
  Set<Column> get primaryKey => {id};
}
