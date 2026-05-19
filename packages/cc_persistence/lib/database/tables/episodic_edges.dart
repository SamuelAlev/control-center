import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_episodic_edges_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_episodic_edges_source', columns: {#sourceFactId})
@TableIndex(name: 'idx_episodic_edges_target', columns: {#targetFactId})
@TableIndex(
  name: 'uq_episodic_edges_triple',
  columns: {#workspaceId, #sourceFactId, #targetFactId, #edgeType},
  unique: true,
)
/// Workspace-scoped typed semantic edges between memory facts (the episodic
/// knowledge graph the graph voice traverses).
class EpisodicEdgesTable extends Table {
  /// Unique edge identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Source fact id.
  TextColumn get sourceFactId => text()();
  /// Target fact id.
  TextColumn get targetFactId => text()();
  /// Edge type slug (`related_to`, `references`, `contextual`).
  TextColumn get edgeType => text()();
  /// Relatedness weight in `[0,1]`.
  RealColumn get weight => real().withDefault(const Constant(1.0))();
  /// When the edge was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}