import 'package:cc_domain/core/domain/entities/memory_access_grant.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/services/memory_access_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/memory_permission.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_access_grant_repository.dart';
import 'package:cc_domain/features/memory/domain/usecases/promote_facts_to_policy_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

/// Simple fake grant repository for testing.
class _FakeMemoryAccessGrantRepository implements MemoryAccessGrantRepository {
  final List<MemoryAccessGrant> _grants = [];

  void seed(List<MemoryAccessGrant> grants) => _grants.addAll(grants);

  @override
  Future<List<MemoryAccessGrant>> getByWorkspace(String workspaceId) async =>
      _grants.where((g) => g.workspaceId == workspaceId).toList();

  @override
  Stream<List<MemoryAccessGrant>> watchByWorkspace(String workspaceId) async* {
    yield _grants.where((g) => g.workspaceId == workspaceId).toList();
  }

  @override
  Future<void> upsert(MemoryAccessGrant grant) async {
    final idx = _grants.indexWhere(
      (g) => g.workspaceId == grant.workspaceId &&
          g.agentRole == grant.agentRole &&
          g.memoryDomain == grant.memoryDomain,
    );
    if (idx >= 0) {
      _grants[idx] = grant;
    } else {
      _grants.add(grant);
    }
  }

  @override
  Future<void> upsertAll(List<MemoryAccessGrant> grants) async {
    for (final g in grants) {
      await upsert(g);
    }
  }
}

void main() {
  group('PromoteFactsToPolicyUseCase', () {
    late FakeMemoryFactRepository factRepo;
    late FakeMemoryPolicyRepository policyRepo;
    late _FakeMemoryAccessGrantRepository grantRepo;
    late MemoryAccessPolicy accessPolicy;
    late PromoteFactsToPolicyUseCase useCase;

    setUp(() {
      factRepo = FakeMemoryFactRepository();
      policyRepo = FakeMemoryPolicyRepository();
      grantRepo = _FakeMemoryAccessGrantRepository();
      accessPolicy = const MemoryAccessPolicy();
      useCase = PromoteFactsToPolicyUseCase(
        factRepository: factRepo,
        policyRepository: policyRepo,
        grantRepository: grantRepo,
        accessPolicy: accessPolicy,
      );
    });

    MemoryFact createFact({
      String id = 'f1',
      String workspaceId = 'ws1',
      String domain = 'test',
      String topic = 'topic',
      String content = 'content',
    }) {
      final now = DateTime.now();
      return MemoryFact(
        id: id,
        workspaceId: workspaceId,
        domain: domain,
        topic: topic,
        content: content,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('execute', () {
      test('creates policy when author has write access', timeout: const Timeout.factor(2), () async {
        grantRepo.seed([
          MemoryAccessGrant(
            workspaceId: 'ws1',
            agentRole: AgentRole.coder,
            memoryDomain: 'test',
            permission: MemoryPermission.write,
          ),
        ]);

        final policy = await useCase.execute(
          workspaceId: 'ws1',
          domain: 'test',
          rule: 'Always use snake_case',
          sourceFactIds: ['f1', 'f2'],
          authorRole: AgentRole.coder,
        );

        expect(policy, isNotNull);
        expect(policy!.workspaceId, 'ws1');
        expect(policy.domain, 'test');
        expect(policy.rule, 'Always use snake_case');
        expect(policy.sourceFactIds, ['f1', 'f2']);
        expect(policy.requiredRole, AgentRole.coder);
        expect(policy.active, isTrue);
      });

      test('throws when author lacks write access', timeout: const Timeout.factor(2), () async {
        grantRepo.seed([
          MemoryAccessGrant(
            workspaceId: 'ws1',
            agentRole: AgentRole.coder,
            memoryDomain: 'test',
            permission: MemoryPermission.read,
          ),
        ]);

        expect(
          () => useCase.execute(
            workspaceId: 'ws1',
            domain: 'test',
            rule: 'rule',
            sourceFactIds: [],
            authorRole: AgentRole.coder,
          ),
          throwsA(isA<InsufficientMemoryPermission>()),
        );
      });

      test('throws when no grant exists for author', timeout: const Timeout.factor(2), () async {
        // No grants seeded
        expect(
          () => useCase.execute(
            workspaceId: 'ws1',
            domain: 'test',
            rule: 'rule',
            sourceFactIds: [],
            authorRole: AgentRole.coder,
          ),
          throwsA(isA<InsufficientMemoryPermission>()),
        );
      });

      test('persists policy to repository', timeout: const Timeout.factor(2), () async {
        grantRepo.seed([
          MemoryAccessGrant(
            workspaceId: 'ws1',
            agentRole: AgentRole.coder,
            memoryDomain: 'test',
            permission: MemoryPermission.write,
          ),
        ]);

        final policy = await useCase.execute(
          workspaceId: 'ws1',
          domain: 'test',
          rule: 'Use descriptive names',
          sourceFactIds: ['f1'],
          authorRole: AgentRole.coder,
        );

        final stored = await policyRepo.getById('ws1', policy!.id);
        expect(stored, isNotNull);
        expect(stored!.rule, 'Use descriptive names');
      });

      test('generates unique policy ids', timeout: const Timeout.factor(2), () async {
        grantRepo.seed([
          MemoryAccessGrant(
            workspaceId: 'ws1',
            agentRole: AgentRole.coder,
            memoryDomain: 'test',
            permission: MemoryPermission.write,
          ),
        ]);

        final p1 = await useCase.execute(
          workspaceId: 'ws1',
          domain: 'test',
          rule: 'Rule 1',
          sourceFactIds: [],
          authorRole: AgentRole.coder,
        );
        final p2 = await useCase.execute(
          workspaceId: 'ws1',
          domain: 'test',
          rule: 'Rule 2',
          sourceFactIds: [],
          authorRole: AgentRole.coder,
        );

        expect(p1!.id, isNot(equals(p2!.id)));
      });
    });

    group('autoPromote', () {
      test('creates policy for domains with >= 3 active facts', timeout: const Timeout.factor(2), () async {
        factRepo.seed([
          createFact(id: 'f1', domain: 'codebase', content: 'Uses Riverpod'),
          createFact(id: 'f2', domain: 'codebase', content: 'Uses Drift'),
          createFact(id: 'f3', domain: 'codebase', content: 'Uses Flutter'),
        ]);

        final policies = await useCase.autoPromote('ws1');

        expect(policies.length, 1);
        expect(policies.first.domain, 'codebase');
        expect(policies.first.sourceFactIds, ['f1', 'f2', 'f3']);
        expect(policies.first.active, isTrue);
        expect(policies.first.rule, contains('Auto-promoted from 3 facts'));
        expect(policies.first.rule, contains('- Uses Riverpod'));
        expect(policies.first.rule, contains('- Uses Drift'));
        expect(policies.first.rule, contains('- Uses Flutter'));
      });

      test('does not promote domains with < 3 facts', timeout: const Timeout.factor(2), () async {
        factRepo.seed([
          createFact(id: 'f1', domain: 'codebase', content: 'Uses Riverpod'),
          createFact(id: 'f2', domain: 'codebase', content: 'Uses Drift'),
        ]);

        final policies = await useCase.autoPromote('ws1');
        expect(policies, isEmpty);
      });

      test('skips superseded facts when counting', timeout: const Timeout.factor(2), () async {
        factRepo.seed([
          createFact(id: 'f1', domain: 'codebase', content: 'Uses Riverpod'),
          createFact(id: 'f2', domain: 'codebase', content: 'Uses Drift'),
          MemoryFact(
            id: 'f3',
            workspaceId: 'ws1',
            domain: 'codebase',
            topic: 'topic',
            content: 'Superseded',
            supersededBy: 'f4',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        final policies = await useCase.autoPromote('ws1');
        expect(policies, isEmpty);
      });

      test('does not create duplicate policies for same fact set', timeout: const Timeout.factor(2), () async {
        factRepo.seed([
          createFact(id: 'f1', domain: 'codebase', content: 'Uses Riverpod'),
          createFact(id: 'f2', domain: 'codebase', content: 'Uses Drift'),
          createFact(id: 'f3', domain: 'codebase', content: 'Uses Flutter'),
        ]);

        final first = await useCase.autoPromote('ws1');
        expect(first.length, 1);

        final second = await useCase.autoPromote('ws1');
        expect(second, isEmpty);
      });

      test('promotes multiple domains independently', timeout: const Timeout.factor(2), () async {
        factRepo.seed([
          createFact(id: 'a1', domain: 'codebase', content: 'Uses Riverpod'),
          createFact(id: 'a2', domain: 'codebase', content: 'Uses Drift'),
          createFact(id: 'a3', domain: 'codebase', content: 'Uses Flutter'),
          createFact(id: 'b1', domain: 'preferences', content: 'Pref dark mode'),
          createFact(id: 'b2', domain: 'preferences', content: 'Pref vim keys'),
          createFact(id: 'b3', domain: 'preferences', content: 'Pref monospace'),
        ]);

        final policies = await useCase.autoPromote('ws1');
        expect(policies.length, 2);

        final domains = policies.map((p) => p.domain).toSet();
        expect(domains, containsAll(['codebase', 'preferences']));
      });

      test('scopes to workspace', timeout: const Timeout.factor(2), () async {
        factRepo.seed([
          createFact(id: 'f1', workspaceId: 'ws1', domain: 'codebase', content: 'A'),
          createFact(id: 'f2', workspaceId: 'ws1', domain: 'codebase', content: 'B'),
          createFact(id: 'f3', workspaceId: 'ws1', domain: 'codebase', content: 'C'),
          createFact(id: 'g1', workspaceId: 'ws2', domain: 'codebase', content: 'X'),
        ]);

        final policies = await useCase.autoPromote('ws1');
        expect(policies.length, 1);
        expect(policies.first.sourceFactIds, ['f1', 'f2', 'f3']);
      });

      test('returns empty list when no facts exist', timeout: const Timeout.factor(2), () async {
        final policies = await useCase.autoPromote('ws1');
        expect(policies, isEmpty);
      });
    });
  });
}
