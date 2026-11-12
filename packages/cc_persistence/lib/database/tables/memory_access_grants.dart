import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for memory access grants: one permission per agent role and
/// memory domain.
class MemoryAccessGrantsTable extends Table {
  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Role granted access (`AgentRole.name`).
  TextColumn get agentRole => text().check(
    // ignore: recursive_getters
    agentRole.isIn(SpacesStoredValues.agentRole),
  )();

  /// Domain the role can access. No foreign key: it is a domain slug, and
  /// grants are seeded per role for domains that need no row of their own.
  TextColumn get memoryDomain => text()();

  /// Permission level (`MemoryPermission.name`: `none`, `read`, `write`).
  TextColumn get permission => text()
      .check(
        // ignore: recursive_getters
        permission.isIn(SpacesStoredValues.memoryPermission),
      )
      .withDefault(const Constant('read'))();

  @override
  String get tableName => 'memory_access_grants';

  @override
  Set<Column> get primaryKey => {agentRole, memoryDomain};
}
