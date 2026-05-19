import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';

class MemoryAccessGrantMapper {
  const MemoryAccessGrantMapper();

  MemoryAccessGrant toDomain(db.MemoryAccessGrantsTableData row) {
    return MemoryAccessGrant(
      workspaceId: row.workspaceId,
      agentRole: AgentRole.tryParse(row.agentRole) ?? AgentRole.general,
      memoryDomain: row.memoryDomain,
      permission: MemoryPermission.tryParse(row.permission) ?? MemoryPermission.read,
    );
  }
}
