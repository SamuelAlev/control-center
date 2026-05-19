import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_persistence/database/app_database.dart' as db;

/// Maps [db.MemoryAccessGrantsTableData] rows to [MemoryAccessGrant] domain entities.
class MemoryAccessGrantMapper {
  /// Creates a const [MemoryAccessGrantMapper].
  const MemoryAccessGrantMapper();

  /// Converts a [db.MemoryAccessGrantsTableData] row to a [MemoryAccessGrant].
  MemoryAccessGrant toDomain(db.MemoryAccessGrantsTableData row) {
    return MemoryAccessGrant(
      workspaceId: row.workspaceId,
      agentRole: AgentRole.tryParse(row.agentRole) ?? AgentRole.general,
      memoryDomain: row.memoryDomain,
      permission: MemoryPermission.tryParse(row.permission) ?? MemoryPermission.read,
    );
  }
}
