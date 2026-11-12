import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_domains_name', columns: {#name}, unique: true)
/// Drift table for memory domains.
class MemoryDomainsTable extends Table {
  /// Unique domain identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Domain slug, unique in the workspace this file holds.
  TextColumn get name => text()();

  /// Human-readable domain label.
  TextColumn get label => text()();

  /// Optional domain description.
  TextColumn get description => text().nullable()();

  /// When this domain was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Role that created this domain (`AgentRole.name`).
  TextColumn get createdByRole => text().check(
    // ignore: recursive_getters
    createdByRole.isIn(SpacesStoredValues.agentRole),
  )();

  @override
  String get tableName => 'memory_domains';

  @override
  Set<Column> get primaryKey => {id};
}
