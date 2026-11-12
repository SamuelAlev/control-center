import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/memory_facts.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_episodic_edges_target', columns: {#targetFactId})
@TableIndex(
  name: 'uq_episodic_edges_triple',
  columns: {#sourceFactId, #targetFactId, #edgeType},
  unique: true,
)
/// Workspace-scoped typed semantic edges between memory facts (the episodic
/// knowledge graph the graph voice traverses).
class EpisodicEdgesTable extends Table {
  /// Unique edge identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Source fact id. `ON DELETE CASCADE`: an edge is part of both facts.
  @ReferenceName('edgesOut')
  TextColumn get sourceFactId =>
      text().references(MemoryFactsTable, #id, onDelete: KeyAction.cascade)();

  /// Target fact id. `ON DELETE CASCADE`, as [sourceFactId].
  @ReferenceName('edgesIn')
  TextColumn get targetFactId =>
      text().references(MemoryFactsTable, #id, onDelete: KeyAction.cascade)();

  /// Edge type slug (`related_to`, `references`, `contextual`;
  /// `EpisodicEdgeTypes.all`).
  TextColumn get edgeType => text().check(
    // ignore: recursive_getters
    edgeType.isIn(SpacesStoredValues.edgeType),
  )();

  /// Relatedness weight in `[0,1]`.
  RealColumn get weight => real().withDefault(const Constant(1.0))();

  /// When the edge was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'episodic_edges';

  @override
  Set<Column> get primaryKey => {id};
}
