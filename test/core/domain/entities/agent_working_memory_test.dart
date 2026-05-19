import 'package:control_center/core/domain/entities/agent_working_memory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 22, 12, 0);

  group('AgentWorkingMemory', () {
    test('constructor creates with required fields', () {
      final memory = AgentWorkingMemory(
        id: 'm-1',
        workspaceId: 'ws-1',
        agentId: 'a-1',
        content: 'Test notes',
        updatedAt: now,
      );

      expect(memory.id, 'm-1');
      expect(memory.workspaceId, 'ws-1');
      expect(memory.agentId, 'a-1');
      expect(memory.content, 'Test notes');
    });

    test('constructor asserts agentId not empty', () {
      expect(
        () => AgentWorkingMemory(
          id: 'm-1', workspaceId: 'ws-1', agentId: '',
          content: '', updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructor asserts workspaceId not empty', () {
      expect(
        () => AgentWorkingMemory(
          id: 'm-1', workspaceId: '', agentId: 'a-1',
          content: '', updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith replaces fields', () {
      final memory = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'old', updatedAt: now,
      );
      final updated = memory.copyWith(content: 'new');
      expect(updated.content, 'new');
      expect(memory.content, 'old');
    });

    test('equality works correctly', () {
      final a = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      final b = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      expect(a, equals(b));
    });
  });
}
