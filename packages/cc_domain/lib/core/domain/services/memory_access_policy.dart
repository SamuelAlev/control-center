import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';

/// Exception thrown when an agent's memory permission is insufficient
/// to perform a requested operation.
class InsufficientMemoryPermission implements Exception {
  /// Creates an [InsufficientMemoryPermission] with the given role,
  /// domain, required permission and actual permission.
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
  ///
  /// [domain] may be a repo-qualified slug (`repo:owner-project/architecture`);
  /// it is matched on its BARE name, which is how grants are seeded. One
  /// `architecture` grant therefore governs that domain in every repo, and
  /// tightening it to read-only cannot be bypassed by writing into a
  /// repo-scoped copy. A grant stored under a fully-qualified slug (written
  /// before grants were normalized) still wins for that exact repo.
  MemoryPermission check({
    required List<MemoryAccessGrant> grants,
    required AgentRole role,
    required String domain,
  }) {
    final forRole = grants.where((g) => g.agentRole == role);
    final exact = forRole.where((g) => g.memoryDomain == domain).firstOrNull;
    if (exact != null) {
      return exact.permission;
    }
    final bare = MemoryDomainScope.bareName(domain);
    final grant = forRole.where((g) => g.memoryDomain == bare).firstOrNull;
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
