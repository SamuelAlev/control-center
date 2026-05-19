import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';

class InsufficientMemoryPermission implements Exception {
  InsufficientMemoryPermission({
    required this.agentRole,
    required this.domain,
    required this.required,
    required this.actual,
  });

  final AgentRole agentRole;
  final String domain;
  final MemoryPermission required;
  final MemoryPermission actual;

  @override
  String toString() =>
      'InsufficientMemoryPermission: role ${agentRole.name} has $actual '
      'permission on $domain, but $required is required';
}

class MemoryAccessPolicy {
  const MemoryAccessPolicy();

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

  bool canWrite({
    required List<MemoryAccessGrant> grants,
    required AgentRole role,
    required String domain,
  }) {
    final permission = check(grants: grants, role: role, domain: domain);
    return permission == MemoryPermission.write;
  }
}
