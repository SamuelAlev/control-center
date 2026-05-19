import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/features/memory/domain/usecases/memory_cleanup_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_memory_repositories.dart';

void main() {
  group('MemoryCleanupUseCase', () {
    late FakeMemoryFactRepository factRepo;
    late FakeAgentWorkingMemoryRepository workingMemoryRepo;
    late MemoryCleanupUseCase useCase;

    setUp(() {
      factRepo = FakeMemoryFactRepository();
      workingMemoryRepo = FakeAgentWorkingMemoryRepository();
      useCase = MemoryCleanupUseCase(
        factRepository: factRepo,
        workingMemoryRepository: workingMemoryRepo,
      );
    });

    MemoryFact createFact({
      String id = 'f1',
      String workspaceId = 'ws1',
      String domain = 'test',
      String topic = 'topic',
      String content = 'content',
      double confidence = 1.0,
      String? supersededBy,
      DateTime? createdAt,
    }) {
      final now = DateTime.now();
      return MemoryFact(
        id: id,
        workspaceId: workspaceId,
        domain: domain,
        topic: topic,
        content: content,
        confidence: confidence,
        supersededBy: supersededBy,
        createdAt: createdAt ?? now,
        updatedAt: now,
      );
    }

    AgentWorkingMemory createWorkingMemory({
      String id = 'wm1',
      String workspaceId = 'ws1',
      String agentId = 'agent1',
      String content = 'short',
      DateTime? updatedAt,
    }) {
      return AgentWorkingMemory(
        id: id,
        workspaceId: workspaceId,
        agentId: agentId,
        content: content,
        updatedAt: updatedAt ?? DateTime.now(),
      );
    }

    group('_archiveStaleFacts', () {
      test('archives stale fact with low confidence', timeout: const Timeout.factor(2), () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 31));
        final fact = createFact(
          id: 'f1',
          confidence: 0.3,
          createdAt: oldDate,
        );
        factRepo.seed([fact]);

        await useCase.execute('ws1');

        final updated = await factRepo.getById('ws1', 'f1');
        expect(updated?.supersededBy, 'system:cleanup');
      });

      test('does not archive stale fact with high confidence', timeout: const Timeout.factor(2), () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 31));
        final fact = createFact(
          id: 'f2',
          confidence: 0.8,
          createdAt: oldDate,
        );
        factRepo.seed([fact]);

        await useCase.execute('ws1');

        final updated = await factRepo.getById('ws1', 'f2');
        expect(updated?.supersededBy, isNull);
      });

      test('does not archive fresh fact with low confidence', timeout: const Timeout.factor(2), () async {
        final recentDate = DateTime.now().subtract(const Duration(days: 10));
        final fact = createFact(
          id: 'f3',
          confidence: 0.3,
          createdAt: recentDate,
        );
        factRepo.seed([fact]);

        await useCase.execute('ws1');

        final updated = await factRepo.getById('ws1', 'f3');
        expect(updated?.supersededBy, isNull);
      });

      test('skips already superseded facts', timeout: const Timeout.factor(2), () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 60));
        final fact = createFact(
          id: 'f4',
          confidence: 0.2,
          supersededBy: 'other-fact',
          createdAt: oldDate,
        );
        factRepo.seed([fact]);

        await useCase.execute('ws1');

        final updated = await factRepo.getById('ws1', 'f4');
        // supersededBy should remain the original, not overwritten
        expect(updated?.supersededBy, 'other-fact');
      });

      test('only processes facts from the given workspace', timeout: const Timeout.factor(2), () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 31));
        factRepo.seed([
          createFact(id: 'f-ws1', workspaceId: 'ws1', confidence: 0.3, createdAt: oldDate),
          createFact(id: 'f-ws2', workspaceId: 'ws2', confidence: 0.3, createdAt: oldDate),
        ]);

        await useCase.execute('ws1');

        expect((await factRepo.getById('ws1', 'f-ws1'))?.supersededBy, 'system:cleanup');
        expect((await factRepo.getById('ws2', 'f-ws2'))?.supersededBy, isNull);
      });
    });

    group('_truncateWorkingMemory', () {
      test('truncates bloated working memory older than 14 days', timeout: const Timeout.factor(2), () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 15));
        final longContent = 'x' * 6000;
        workingMemoryRepo.seed([
          createWorkingMemory(id: 'wm1', content: longContent, updatedAt: oldDate),
        ]);

        await useCase.execute('ws1');

        final updated = (await workingMemoryRepo.watchByWorkspace('ws1').first).first;
        expect(updated.content.length, 2000);
      });

      test('does not truncate bloated working memory younger than 14 days', timeout: const Timeout.factor(2), () async {
        final recentDate = DateTime.now().subtract(const Duration(days: 7));
        final longContent = 'x' * 6000;
        workingMemoryRepo.seed([
          createWorkingMemory(id: 'wm2', content: longContent, updatedAt: recentDate),
        ]);

        await useCase.execute('ws1');

        final updated = (await workingMemoryRepo.watchByWorkspace('ws1').first).first;
        expect(updated.content.length, 6000);
      });

      test('does not truncate working memory under max chars', timeout: const Timeout.factor(2), () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 20));
        workingMemoryRepo.seed([
          createWorkingMemory(id: 'wm3', content: 'short', updatedAt: oldDate),
        ]);

        await useCase.execute('ws1');

        final updated = (await workingMemoryRepo.watchByWorkspace('ws1').first).first;
        expect(updated.content, 'short');
      });

      test('truncated content preserves the last 2000 characters', timeout: const Timeout.factor(2), () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 20));
        // Use distinctive prefixes so we can verify the suffix is kept
        final content = 'A' * 3000 + 'B' * 3000;
        workingMemoryRepo.seed([
          createWorkingMemory(id: 'wm4', content: content, updatedAt: oldDate),
        ]);

        await useCase.execute('ws1');

        final updated = (await workingMemoryRepo.watchByWorkspace('ws1').first).first;
        expect(updated.content.length, 2000);
        // The last 2000 chars of the original: last 2000 of 6000 = chars 4000-5999
        // content[4000:] = '' (no B's left, actually let's recalculate)
        // content = 'A'*3000 + 'B'*3000 = 6000 chars
        // last 2000 chars = content.substring(4000) = 'B'*2000
        expect(updated.content, 'B' * 2000);
      });
    });

    test('handles empty workspace gracefully', timeout: const Timeout.factor(2), () async {
      await useCase.execute('ws-empty');
      // Should not throw
    });
  });
}
