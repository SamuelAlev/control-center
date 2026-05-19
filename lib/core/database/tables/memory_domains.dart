import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_domains_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_memory_domains_name', columns: {#workspaceId, #name}, unique: true)
/// Drift table for memory domains.
class MemoryDomainsTable extends Table {
  /// Unique domain identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Domain slug, unique per workspace.
  TextColumn get name => text()();
  /// Human-readable domain label.
  TextColumn get label => text()();
  /// Optional domain description.
  TextColumn get description => text().nullable()();
  /// When this domain was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Role that created this domain.
  TextColumn get createdByRole => text()();

  @override
  Set<Column> get primaryKey => {id};
}
