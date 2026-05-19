import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_facts_supersededBy', columns: {#supersededBy})
@TableIndex(name: 'idx_memory_facts_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_memory_facts_topic', columns: {#topic})
@TableIndex(name: 'idx_memory_facts_domain', columns: {#domain})
/// Drift table for memory facts.
class MemoryFactsTable extends Table {
  /// Unique fact identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Domain this fact belongs to.
  TextColumn get domain => text()();
  /// Topic this fact is about.
  TextColumn get topic => text()();
  /// Fact content text.
  TextColumn get content => text()();
  /// JSON array of source observation ids.
  TextColumn get sourceObservationIds => text().withDefault(const Constant('[]'))();
  /// Confidence score (0.0–1.0).
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  /// Id of the fact that supersedes this one.
  TextColumn get supersededBy => text().nullable()();
  /// Id of the agent that authored this fact.
  TextColumn get authoredByAgentId => text().nullable()();
  /// Role that authored this fact.
  TextColumn get authoredByRole => text().nullable()();
  /// Vector embedding for semantic search.
  BlobColumn get embedding => blob().nullable()();
  /// When this fact was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// When this fact was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
