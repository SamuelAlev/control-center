import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

/// Workspace-scoped harmonized beliefs emitted by cross-agent SHMR.
class MemoryBeliefsTable extends Table {
  /// Unique belief identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Topic the belief is about.
  TextColumn get topic => text()();

  /// The harmonized statement.
  TextColumn get content => text()();

  /// Corroborated confidence in `[0,1]`.
  RealColumn get confidence => real().withDefault(const Constant(0.5))();

  /// Resonance with the cluster centroid in `[0,1]`.
  RealColumn get harmonyScore => real().withDefault(const Constant(0.0))();

  /// JSON array of source fact ids.
  TextColumn get provenanceFactIds => text()
      .check(
        // ignore: recursive_getters
        isJsonArray(provenanceFactIds),
      )
      .withDefault(const Constant('[]'))();

  /// JSON array of contributing agent ids.
  TextColumn get provenanceAgentIds => text()
      .check(
        // ignore: recursive_getters
        isJsonArray(provenanceAgentIds),
      )
      .withDefault(const Constant('[]'))();

  /// The cluster this belief came from. No foreign key: clusters exist only
  /// for the length of a harmonization pass.
  TextColumn get clusterId => text()();

  /// What harmonization did: `create`, `update`, or `dampen`
  /// (`MemoryBelief.actions`).
  TextColumn get action => text()
      .check(
        // ignore: recursive_getters
        action.isIn(SpacesStoredValues.beliefAction),
      )
      .withDefault(const Constant('create'))();

  /// When created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'memory_beliefs';

  @override
  Set<Column> get primaryKey => {id};
}
