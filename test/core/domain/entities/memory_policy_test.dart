import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 5, 22, 12, 0);

  group('MemoryPolicy', () {
    test('constructor creates with required fields', () {
      final policy = MemoryPolicy(
        id: 'p-1',
        workspaceId: 'ws-1',
        domain: 'tech-stack',
        rule: 'Use Drift for all database operations',
        createdAt: now,
        updatedAt: now,
      );

      expect(policy.id, 'p-1');
      expect(policy.workspaceId, 'ws-1');
      expect(policy.domain, 'tech-stack');
      expect(policy.rule, 'Use Drift for all database operations');
      expect(policy.active, isTrue);
      expect(policy.requiredRole, isNull);
      expect(policy.sourceFactIds, isEmpty);
    });

    test('constructor asserts workspaceId not empty', () {
      expect(
        () => MemoryPolicy(
          id: 'p-1', workspaceId: '', domain: 'process',
          rule: 'test', createdAt: now, updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructor asserts rule not empty', () {
      expect(
        () => MemoryPolicy(
          id: 'p-1', workspaceId: 'ws-1', domain: 'process',
          rule: '', createdAt: now, updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('copyWith replaces fields', () {
      final policy = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'old rule', requiredRole: AgentRole.security,
        createdAt: now, updatedAt: now,
      );
      final updated = policy.copyWith(rule: 'new rule', active: false);
      expect(updated.rule, 'new rule');
      expect(updated.active, isFalse);
      expect(updated.requiredRole, AgentRole.security);
      expect(policy.rule, 'old rule');
    });

    test('equality works correctly', () {
      final a = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'strategy',
        rule: 'rule', active: true, createdAt: now, updatedAt: now,
      );
      final b = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'strategy',
        rule: 'rule', active: true, createdAt: now, updatedAt: now,
      );
      expect(a, equals(b));
    });

    test('copyWith with clearRequiredRole sets requiredRole to null', () {
      final policy = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', requiredRole: AgentRole.security,
        createdAt: now, updatedAt: now,
      );
      final updated = policy.copyWith(clearRequiredRole: true);
      expect(updated.requiredRole, isNull);
    });

    test('copyWith retains requiredRole when clearRequiredRole is false', () {
      final policy = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', requiredRole: AgentRole.security,
        createdAt: now, updatedAt: now,
      );
      final updated = policy.copyWith();
      expect(updated.requiredRole, AgentRole.security);
    });

    test('copyWith replaces requiredRole explicitly', () {
      final policy = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', requiredRole: AgentRole.security,
        createdAt: now, updatedAt: now,
      );
      final updated = policy.copyWith(requiredRole: AgentRole.ceo);
      expect(updated.requiredRole, AgentRole.ceo);
    });

    test('hashCode is equal for equal policies', () {
      final a = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', active: true, createdAt: now, updatedAt: now,
      );
      final b = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', active: true, createdAt: now, updatedAt: now,
      );
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs when active differs', () {
      final a = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', active: true, createdAt: now, updatedAt: now,
      );
      final b = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', active: false, createdAt: now, updatedAt: now,
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('hashCode differs when sourceFactIds differ', () {
      final a = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', sourceFactIds: ['a'], createdAt: now, updatedAt: now,
      );
      final b = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', sourceFactIds: ['b'], createdAt: now, updatedAt: now,
      );
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('equality compares sourceFactIds (list equality)', () {
      final a = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', sourceFactIds: ['a', 'b'], createdAt: now, updatedAt: now,
      );
      final b = MemoryPolicy(
        id: 'p-1', workspaceId: 'ws-1', domain: 'security',
        rule: 'rule', sourceFactIds: ['a', 'b'], createdAt: now, updatedAt: now,
      );
      expect(a, equals(b));
    });
  });
}
