import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 22, 12, 0);

  group('MemoryFact', () {
    test('constructor creates with required fields', () {
      final fact = MemoryFact(
        id: 'f-1',
        workspaceId: 'ws-1',
        domain: 'test',
        topic: 'tech stack',
        content: 'We use Flutter for frontend',
        createdAt: now,
        updatedAt: now,
      );

      expect(fact.id, 'f-1');
      expect(fact.workspaceId, 'ws-1');
      expect(fact.domain, 'test');
      expect(fact.topic, 'tech stack');
      expect(fact.content, 'We use Flutter for frontend');
      expect(fact.confidence, 1.0);
      expect(fact.supersededBy, isNull);
      expect(fact.authoredByAgentId, isNull);
      expect(fact.authoredByRole, isNull);
      expect(fact.isSuperseded, isFalse);
    });

    test('constructor asserts workspaceId not empty', () {
      expect(
        () => MemoryFact(
          id: 'f-1', workspaceId: '', domain: 'test', topic: 'test',
          content: 'content', createdAt: now, updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructor asserts topic not empty', () {
      expect(
        () => MemoryFact(
          id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: '',
          content: 'content', createdAt: now, updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructor asserts confidence range', () {
      expect(
        () => MemoryFact(
          id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
          content: 'content', confidence: 1.5, createdAt: now, updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('isSuperseded returns true when supersededBy is set', () {
      final fact = MemoryFact(
        id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
        content: 'content', supersededBy: 'f-2', createdAt: now, updatedAt: now,
      );
      expect(fact.isSuperseded, isTrue);
    });

    test('copyWith replaces fields', () {
      final fact = MemoryFact(
        id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
        content: 'old', createdAt: now, updatedAt: now,
      );
      final updated = fact.copyWith(
        content: 'new',
        supersededBy: 'f-2',
      );
      expect(updated.content, 'new');
      expect(updated.supersededBy, 'f-2');
      expect(fact.content, 'old');
    });

    test('copyWith clears supersededBy', () {
      final fact = MemoryFact(
        id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
        content: 'content', supersededBy: 'f-2', createdAt: now, updatedAt: now,
      );
      final updated = fact.copyWith(clearSupersededBy: true);
      expect(updated.supersededBy, isNull);
    });

    test('equality works correctly', () {
      final a = MemoryFact(
        id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
        content: 'content', authoredByAgentId: 'a-1',
        authoredByRole: AgentRole.ceo,
        createdAt: now, updatedAt: now,
      );
      final b = MemoryFact(
        id: 'f-1', workspaceId: 'ws-1', domain: 'test', topic: 'test',
        content: 'content', authoredByAgentId: 'a-1',
        authoredByRole: AgentRole.ceo,
        createdAt: now, updatedAt: now,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}
