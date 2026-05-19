import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/domain/services/memory_access_policy.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:uuid/uuid.dart';

class PromoteFactsToPolicyUseCase {
  PromoteFactsToPolicyUseCase({
    required MemoryFactRepository factRepository,
    required MemoryPolicyRepository policyRepository,
    required MemoryAccessGrantRepository grantRepository,
    required MemoryAccessPolicy accessPolicy,
  })  : _factRepository = factRepository,
        _policyRepository = policyRepository,
        _grantRepository = grantRepository,
        _accessPolicy = accessPolicy;

  final MemoryFactRepository _factRepository;
  final MemoryPolicyRepository _policyRepository;
  final MemoryAccessGrantRepository _grantRepository;
  final MemoryAccessPolicy _accessPolicy;
  final _uuid = const Uuid();

  Future<MemoryPolicy?> execute({
    required String workspaceId,
    required String domain,
    required String rule,
    required List<String> sourceFactIds,
    required AgentRole authorRole,
  }) async {
    final grants = await _grantRepository.getByWorkspace(workspaceId);
    _accessPolicy.enforceWrite(
      grants: grants,
      role: authorRole,
      domain: domain,
    );

    final now = DateTime.now();
    final policy = MemoryPolicy(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      domain: domain,
      rule: rule,
      sourceFactIds: sourceFactIds,
      requiredRole: authorRole,
      active: true,
      createdAt: now,
      updatedAt: now,
    );

    await _policyRepository.upsert(policy);
    return policy;
  }

  Future<List<MemoryPolicy>> autoPromote(String workspaceId) async {
    final facts = await _factRepository.getByWorkspace(workspaceId);
    final domainGroups = <String, List<MemoryFact>>{};

    for (final fact in facts) {
      if (fact.isSuperseded) {
        continue;
      }
      domainGroups.putIfAbsent(fact.domain, () => []).add(fact);
    }

    final policies = <MemoryPolicy>[];
    for (final entry in domainGroups.entries) {
      if (entry.value.length >= 3) {
        final factsForDomain = entry.value;
        final sourceIds = factsForDomain.map((f) => f.id).toList();
        final rule = factsForDomain
            .map((f) => '- ${f.content}')
            .join('\n');

        final existing = await _policyRepository.getActiveByWorkspace(
          workspaceId,
          domain: entry.key,
        );
        final alreadyPromoted = existing.any(
          (p) => p.sourceFactIds.length == sourceIds.length &&
              p.sourceFactIds.toSet().containsAll(sourceIds.toSet()),
        );

        if (!alreadyPromoted) {
          final policy = MemoryPolicy(
            id: _uuid.v4(),
            workspaceId: workspaceId,
            domain: entry.key,
            rule: '# Auto-promoted from ${factsForDomain.length} facts\n\n$rule',
            sourceFactIds: sourceIds,
            active: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _policyRepository.upsert(policy);
          policies.add(policy);
        }
      }
    }

    return policies;
  }

}
