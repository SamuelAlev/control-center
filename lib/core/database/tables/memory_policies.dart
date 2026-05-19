import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_policies_workspaceId', columns: {#workspaceId})
class MemoryPoliciesTable extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get domain => text()();
  TextColumn get rule => text()();
  TextColumn get sourceFactIds => text().withDefault(const Constant('[]'))();
  TextColumn get requiredRole => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
