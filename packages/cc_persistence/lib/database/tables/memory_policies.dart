import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for memory policies.
class MemoryPoliciesTable extends Table {
  /// Unique policy identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Domain this policy applies to. No foreign key: a domain slug.
  TextColumn get domain => text()();

  /// Policy rule text.
  TextColumn get rule => text()();

  /// JSON array of source fact ids.
  TextColumn get sourceFactIds => text()
      .check(
        // ignore: recursive_getters
        isJsonArray(sourceFactIds),
      )
      .withDefault(const Constant('[]'))();

  /// Optional role required by this policy (`AgentRole.name`).
  TextColumn get requiredRole => text().nullable().check(
    // ignore: recursive_getters
    requiredRole.isIn(SpacesStoredValues.agentRole),
  )();

  /// Whether this policy is active.
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  /// When this policy was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this policy was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'memory_policies';

  @override
  Set<Column> get primaryKey => {id};
}
