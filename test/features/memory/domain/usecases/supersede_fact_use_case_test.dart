import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/features/memory/domain/usecases/supersede_fact_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

void main() {
  group('SupersedeFactUseCase', () {
    late FakeMemoryFactRepository factRepo;
    late SupersedeFactUseCase useCase;

    setUp(() {
      factRepo = FakeMemoryFactRepository();
      useCase = SupersedeFactUseCase(factRepository: factRepo);
    });

    final now = DateTime.now();

    MemoryFact createFact({
      String id = 'f1',
      String workspaceId = 'ws1',
      String? supersededBy,
    }) {
      return MemoryFact(
        id: id,
        workspaceId: workspaceId,
        domain: 'test',
        topic: 'topic',
        content: 'content',
        supersededBy: supersededBy,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('marks fact as superseded', timeout: const Timeout.factor(2), () async {
      factRepo.seed([createFact(id: 'f1')]);

      final result = await useCase.execute(
        workspaceId: 'ws1',
        factId: 'f1',
        supersedingFactId: 'f2',
      );

      expect(result.supersededBy, 'f2');
      expect(result.id, 'f1');
    });

    test('persists superseded fact to repository', timeout: const Timeout.factor(2), () async {
      factRepo.seed([createFact(id: 'f1')]);

      await useCase.execute(
        workspaceId: 'ws1',
        factId: 'f1',
        supersedingFactId: 'f2',
      );

      final stored = await factRepo.getById('ws1', 'f1');
      expect(stored?.supersededBy, 'f2');
    });

    test('updates the updatedAt timestamp', timeout: const Timeout.factor(2), () async {
      final oldFact = MemoryFact(
        id: 'f1',
        workspaceId: 'ws1',
        domain: 'test',
        topic: 'topic',
        content: 'content',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      factRepo.seed([oldFact]);

      final result = await useCase.execute(
        workspaceId: 'ws1',
        factId: 'f1',
        supersedingFactId: 'f2',
      );

      expect(result.updatedAt.isAfter(oldFact.updatedAt), isTrue);
    });

    test('throws ArgumentError when fact not found', timeout: const Timeout.factor(2), () async {
      // Empty repo
      expect(
        () => useCase.execute(
          workspaceId: 'ws1',
          factId: 'nonexistent',
          supersedingFactId: 'f2',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when fact belongs to different workspace', timeout: const Timeout.factor(2), () async {
      factRepo.seed([createFact(id: 'f1', workspaceId: 'ws1')]);

      expect(
        () => useCase.execute(
          workspaceId: 'ws2',
          factId: 'f1',
          supersedingFactId: 'f2',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('preserves other fields when superseding', timeout: const Timeout.factor(2), () async {
      final fact = MemoryFact(
        id: 'f1',
        workspaceId: 'ws1',
        domain: 'codebase',
        topic: 'testing',
        content: 'Use integration tests',
        confidence: 0.9,
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );
      factRepo.seed([fact]);

      final result = await useCase.execute(
        workspaceId: 'ws1',
        factId: 'f1',
        supersedingFactId: 'f2',
      );

      expect(result.domain, 'codebase');
      expect(result.topic, 'testing');
      expect(result.content, 'Use integration tests');
      expect(result.confidence, 0.9);
      expect(result.createdAt, fact.createdAt);
    });
  });
}
