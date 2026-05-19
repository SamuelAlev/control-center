import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';

/// Defines what a specific [AgentRole] can do within a memory domain.
class MemoryAccessGrant {
  /// Creates a new [MemoryAccessGrant].
  MemoryAccessGrant({
    required this.workspaceId,
    required this.agentRole,
    required this.memoryDomain,
    required this.permission,
  }) : assert(workspaceId.isNotEmpty, 'MemoryAccessGrant workspaceId must not be empty');

  /// Workspace where this grant applies.
  final String workspaceId;
  /// Role granted access.
  final AgentRole agentRole;
  /// Memory domain scoped by this grant.
  final String memoryDomain;
  /// Permission level granted.
  final MemoryPermission permission;

  /// Structural equality check.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryAccessGrant &&
          runtimeType == other.runtimeType &&
          workspaceId == other.workspaceId &&
          agentRole == other.agentRole &&
          memoryDomain == other.memoryDomain &&
          permission == other.permission;

  /// Hash code based on all fields.
  @override
  int get hashCode => Object.hash(workspaceId, agentRole, memoryDomain, permission);
}
