import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Drift table for memory access grants.
class MemoryAccessGrantsTable extends Table {
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Role granted access.
  TextColumn get agentRole => text()();
  /// Domain the role can access.
  TextColumn get memoryDomain => text()();
  /// Permission level ('read', 'write', etc.).
  TextColumn get permission => text().withDefault(const Constant('read'))();

  @override
  Set<Column> get primaryKey => {workspaceId, agentRole, memoryDomain};
}
