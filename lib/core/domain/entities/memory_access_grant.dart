import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';

class MemoryAccessGrant {
  MemoryAccessGrant({
    required this.workspaceId,
    required this.agentRole,
    required this.memoryDomain,
    required this.permission,
  }) : assert(workspaceId.isNotEmpty, 'MemoryAccessGrant workspaceId must not be empty');

  final String workspaceId;
  final AgentRole agentRole;
  final String memoryDomain;
  final MemoryPermission permission;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryAccessGrant &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          agentRole == other.agentRole &&
          memoryDomain == other.memoryDomain &&
          permission == other.permission;

  @override
  int get hashCode => Object.hash(workspaceId, agentRole, memoryDomain, permission);
}
