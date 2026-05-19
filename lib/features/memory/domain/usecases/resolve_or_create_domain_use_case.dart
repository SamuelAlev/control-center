import 'package:control_center/core/domain/entities/memory_access_grant.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/core/domain/value_objects/memory_permission.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:uuid/uuid.dart';

/// Resolves a domain input string to an existing [MemoryDomain] or creates a
/// new one, seeding access grants for all roles.
class ResolveOrCreateDomainUseCase {
  /// Creates a [ResolveOrCreateDomainUseCase].
  ResolveOrCreateDomainUseCase({
    required MemoryDomainRepository domainRepository,
    required MemoryAccessGrantRepository grantRepository,
  })  : _domainRepository = domainRepository,
        _grantRepository = grantRepository;

  final MemoryDomainRepository _domainRepository;
  final MemoryAccessGrantRepository _grantRepository;
  final _uuid = const Uuid();

  /// Resolves [domainInput] to an existing domain or creates a new one.
  ///
  /// Returns the resolved or created [MemoryDomain].
  Future<MemoryDomain> execute({
    required String workspaceId,
    required String domainInput,
    String? domainLabel,
    String? domainDescription,
    required AgentRole authorRole,
  }) async {
    final slug = _slugify(domainInput);
    final existing = await _domainRepository.findByName(workspaceId, slug);
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final domain = MemoryDomain(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      name: slug,
      label: domainLabel ?? domainInput,
      description: domainDescription,
      createdAt: now,
      createdByRole: authorRole.name,
    );

    await _domainRepository.upsert(domain);
    await _seedAccessGrants(workspaceId, slug, authorRole);

    return domain;
  }

  Future<void> _seedAccessGrants(
    String workspaceId,
    String domainSlug,
    AgentRole creatorRole,
  ) async {
    final grants = <MemoryAccessGrant>[];
    for (final role in AgentRole.values) {
      grants.add(MemoryAccessGrant(
        workspaceId: workspaceId,
        agentRole: role,
        memoryDomain: domainSlug,
        permission: role == creatorRole
            ? MemoryPermission.write
            : MemoryPermission.read,
      ));
    }
    await _grantRepository.upsertAll(grants);
  }

  String _slugify(String input) {
    return input
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'[\s_]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
