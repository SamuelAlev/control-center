import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/memory/domain/usecases/supersede_policy_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

void main() {
  group('SupersedePolicyUseCase', () {
    late FakeMemoryPolicyRepository policyRepo;
    late SupersedePolicyUseCase useCase;

    setUp(() {
      policyRepo = FakeMemoryPolicyRepository();
      useCase = SupersedePolicyUseCase(policyRepository: policyRepo);
    });

    final now = DateTime(2026, 6, 1);

    MemoryPolicy createPolicy({
      String id = 'p1',
      String workspaceId = 'ws1',
      bool active = true,
    }) {
      return MemoryPolicy(
        id: id,
        workspaceId: workspaceId,
        domain: 'architecture',
        rule: 'Use Clean Architecture layering.',
        active: active,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('marks the policy inactive', () async {
      policyRepo.seed([createPolicy(id: 'p1')]);

      final result = await useCase.execute(workspaceId: 'ws1', policyId: 'p1');

      expect(result.active, isFalse);
      expect(result.id, 'p1');
    });

    test('persists the retired policy to the repository', () async {
      policyRepo.seed([createPolicy(id: 'p1')]);

      await useCase.execute(workspaceId: 'ws1', policyId: 'p1');

      final stored = await policyRepo.getById('ws1', 'p1');
      expect(stored!.active, isFalse);
    });

    test('drops the policy from the active set', () async {
      policyRepo.seed([createPolicy(id: 'p1')]);

      await useCase.execute(workspaceId: 'ws1', policyId: 'p1');

      final active = await policyRepo.getActiveByWorkspace('ws1');
      expect(active, isEmpty);
    });

    test('bumps the updatedAt timestamp', () async {
      policyRepo.seed([
        MemoryPolicy(
          id: 'p1',
          workspaceId: 'ws1',
          domain: 'architecture',
          rule: 'old rule',
          createdAt: DateTime(2024),
          updatedAt: DateTime(2024),
        ),
      ]);

      final result = await useCase.execute(workspaceId: 'ws1', policyId: 'p1');

      expect(result.updatedAt.isAfter(DateTime(2024)), isTrue);
    });

    test('preserves rule/domain/createdAt when retiring', () async {
      final created = DateTime(2024, 3, 2);
      policyRepo.seed([
        MemoryPolicy(
          id: 'p1',
          workspaceId: 'ws1',
          domain: 'api-design',
          rule: 'All endpoints MUST be versioned.',
          createdAt: created,
          updatedAt: created,
        ),
      ]);

      final result = await useCase.execute(workspaceId: 'ws1', policyId: 'p1');

      expect(result.domain, 'api-design');
      expect(result.rule, 'All endpoints MUST be versioned.');
      expect(result.createdAt, created);
    });

    test('throws ArgumentError when the policy is not found', () {
      expect(
        () => useCase.execute(workspaceId: 'ws1', policyId: 'missing'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('does not retire a policy owned by another workspace', () async {
      policyRepo.seed([createPolicy(id: 'p1', workspaceId: 'ws1')]);

      await expectLater(
        useCase.execute(workspaceId: 'ws2', policyId: 'p1'),
        throwsA(isA<ArgumentError>()),
      );

      // The foreign workspace's policy is untouched and still active.
      final stored = await policyRepo.getById('ws1', 'p1');
      expect(stored!.active, isTrue);
    });
  });
}
