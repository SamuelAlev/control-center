import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_beliefs_workspaceId', columns: {#workspaceId})
/// Workspace-scoped harmonized beliefs emitted by cross-agent SHMR.
class MemoryBeliefsTable extends Table {
  /// Unique belief identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Topic the belief is about.
  TextColumn get topic => text()();
  /// The harmonized statement.
  TextColumn get content => text()();
  /// Corroborated confidence in `[0,1]`.
  RealColumn get confidence => real().withDefault(const Constant(0.5))();
  /// Resonance with the cluster centroid in `[0,1]`.
  RealColumn get harmonyScore => real().withDefault(const Constant(0.0))();
  /// JSON array of source fact ids.
  TextColumn get provenanceFactIds =>
      text().withDefault(const Constant('[]'))();
  /// JSON array of contributing agent ids.
  TextColumn get provenanceAgentIds =>
      text().withDefault(const Constant('[]'))();
  /// The cluster this belief came from.
  TextColumn get clusterId => text()();
  /// What harmonization did: `create`, `update`, or `dampen`.
  TextColumn get action => text().withDefault(const Constant('create'))();
  /// When created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// When last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}