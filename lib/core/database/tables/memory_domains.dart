import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_domains_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_memory_domains_name', columns: {#workspaceId, #name}, unique: true)
class MemoryDomainsTable extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get label => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdByRole => text()();

  @override
  Set<Column> get primaryKey => {id};
}
