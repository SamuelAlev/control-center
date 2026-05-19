import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_policies_workspaceId', columns: {#workspaceId})
/// Drift table for memory policies.
class MemoryPoliciesTable extends Table {
  /// Unique policy identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Domain this policy applies to.
  TextColumn get domain => text()();
  /// Policy rule text.
  TextColumn get rule => text()();
  /// JSON array of source fact ids.
  TextColumn get sourceFactIds => text().withDefault(const Constant('[]'))();
  /// Optional role required by this policy.
  TextColumn get requiredRole => text().nullable()();
  /// Whether this policy is active.
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  /// When this policy was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// When this policy was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
