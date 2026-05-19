import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

class MemoryAccessGrantsTable extends Table {
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get agentRole => text()();
  TextColumn get memoryDomain => text()();
  TextColumn get permission => text().withDefault(const Constant('read'))();

  @override
  Set<Column> get primaryKey => {workspaceId, agentRole, memoryDomain};
}
