import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_facts_supersededBy', columns: {#supersededBy})
@TableIndex(name: 'idx_memory_facts_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_memory_facts_topic', columns: {#topic})
@TableIndex(name: 'idx_memory_facts_domain', columns: {#domain})
class MemoryFactsTable extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get domain => text()();
  TextColumn get topic => text()();
  TextColumn get content => text()();
  TextColumn get sourceObservationIds => text().withDefault(const Constant('[]'))();
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  TextColumn get supersededBy => text().nullable()();
  TextColumn get authoredByAgentId => text().nullable()();
  TextColumn get authoredByRole => text().nullable()();
  BlobColumn get embedding => blob().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
