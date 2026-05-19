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
      expect(memory.updatedAt, now);
    });

    test('constructor allows empty content', () {
      final memory = AgentWorkingMemory(
        id: 'm-1',
        workspaceId: 'ws-1',
        agentId: 'a-1',
        content: '',
        updatedAt: now,
      );
      expect(memory.content, '');
      expect(memory.id, 'm-1');
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

    test('copyWith replaces all fields at once', () {
      final memory = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'old', updatedAt: now,
      );
      final later = now.add(const Duration(hours: 1));
      final updated = memory.copyWith(
        id: 'm-2',
        workspaceId: 'ws-2',
        agentId: 'a-2',
        content: 'new',
        updatedAt: later,
      );
      expect(updated.id, 'm-2');
      expect(updated.workspaceId, 'ws-2');
      expect(updated.agentId, 'a-2');
      expect(updated.content, 'new');
      expect(updated.updatedAt, later);
    });

    test('copyWith does not mutate original', () {
      final memory = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'old', updatedAt: now,
      );
      final _ = memory.copyWith(
        content: 'new',
        agentId: 'a-2',
      );
      expect(memory.content, 'old');
      expect(memory.agentId, 'a-1');
      expect(memory.workspaceId, 'ws-1');
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

    test('hashCode consistent with equality', () {
      final a = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      final b = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when id differs', () {
      final a = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      final b = AgentWorkingMemory(
        id: 'm-2', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when content differs', () {
      final a = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      final b = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'different', updatedAt: now,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when updatedAt differs', () {
      final a = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      final b = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now.add(const Duration(seconds: 1)),
      );
      expect(a, isNot(equals(b)));
    });

    test('hashCode differs when content differs', () {
      final a = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'notes', updatedAt: now,
      );
      final b = AgentWorkingMemory(
        id: 'm-1', workspaceId: 'ws-1', agentId: 'a-1',
        content: 'different', updatedAt: now,
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
