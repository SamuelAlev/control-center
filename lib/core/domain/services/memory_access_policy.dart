import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';

/// Exception thrown when an agent's memory permission is insufficient
/// to perform a requested operation.
class InsufficientMemoryPermission implements Exception {
  /// Creates an [InsufficientMemoryPermission] with the given role,
  /// domain, required permission, and actual permission.
  InsufficientMemoryPermission({
    required this.agentRole,
    required this.domain,
    required this.required,
    required this.actual,
  });

  /// Agent role whose permission was insufficient.
  final AgentRole agentRole;
  /// Domain on which access was denied.
  final String domain;
  /// Permission level required for the operation.
  final MemoryPermission required;
  /// Permission level the agent actually held.
  final MemoryPermission actual;

  @override
  String toString() =>
      'InsufficientMemoryPermission: role ${agentRole.name} has $actual '
      'permission on $domain, but $required is required';
}

/// Evaluates memory access permissions for agents against their grants.

class MemoryAccessPolicy {
  /// Creates a [MemoryAccessPolicy].
  const MemoryAccessPolicy();

  /// Checks the memory permission for the given [role] on [domain]
  /// against the provided [grants].
  MemoryPermission check({
    required List<MemoryAccessGrant> grants,
    required AgentRole role,
    required String domain,
  }) {
    final grant = grants.where(
      (g) => g.agentRole == role && g.memoryDomain == domain,
    ).firstOrNull;
    return grant?.permission ?? MemoryPermission.read;
  }

  /// Enforces write permission; throws [InsufficientMemoryPermission] if
  /// [role] does not have write access on [domain] in [grants].
  void enforceWrite({
    required List<MemoryAccessGrant> grants,
    required AgentRole role,
    required String domain,
  }) {
    final permission = check(grants: grants, role: role, domain: domain);
    if (permission != MemoryPermission.write) {
      throw InsufficientMemoryPermission(
        agentRole: role,
        domain: domain,
        required: MemoryPermission.write,
        actual: permission,
      );
    }
  }

  /// Returns `true` if [role] has write permission on [domain] in [grants].
  bool canWrite({
    required List<MemoryAccessGrant> grants,
    required AgentRole role,
    required String domain,
  }) {
    final permission = check(grants: grants, role: role, domain: domain);
    return permission == MemoryPermission.write;
  }
}
