import 'dart:convert';

import 'package:control_center/core/database/app_database.dart' as db;
import 'package:control_center/core/domain/value_objects/agent_role.dart';
import 'package:control_center/features/memory/data/mappers/memory_policy_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryPolicyMapper', () {
    const mapper = MemoryPolicyMapper();

    db.MemoryPoliciesTableData createRow({
      String id = 'p1',
      String workspaceId = 'ws1',
      String domain = 'codebase',
      String rule = 'Always write tests',
      String sourceFactIds = '[]',
      String? requiredRole,
      bool active = true,
      DateTime? createdAt,
      DateTime? updatedAt,
    }) {
      final now = DateTime(2025, 6, 10);
      return db.MemoryPoliciesTableData(
        id: id,
        workspaceId: workspaceId,
        domain: domain,
        rule: rule,
        sourceFactIds: sourceFactIds,
        requiredRole: requiredRole,
        active: active,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
      );
    }

    test('maps all basic fields', timeout: const Timeout.factor(2), () {
      final now = DateTime(2025, 6, 10);
      final row = createRow(
        id: 'pol-1',
        workspaceId: 'ws-1',
        domain: 'preferences',
        rule: 'Always use dark mode',
        active: true,
        createdAt: now,
        updatedAt: now,
      );

      final policy = mapper.toDomain(row);

      expect(policy.id, 'pol-1');
      expect(policy.workspaceId, 'ws-1');
      expect(policy.domain, 'preferences');
      expect(policy.rule, 'Always use dark mode');
      expect(policy.active, isTrue);
      expect(policy.createdAt, now);
      expect(policy.updatedAt, now);
    });

    test('parses source fact ids from JSON array', timeout: const Timeout.factor(2), () {
      final row = createRow(
        sourceFactIds: jsonEncode(['f1', 'f2', 'f3']),
      );

      final policy = mapper.toDomain(row);

      expect(policy.sourceFactIds, ['f1', 'f2', 'f3']);
    });

    test('returns empty list when source fact ids is empty JSON array', timeout: const Timeout.factor(2), () {
      final row = createRow(sourceFactIds: '[]');

      final policy = mapper.toDomain(row);

      expect(policy.sourceFactIds, isEmpty);
    });

    test('returns empty list when source fact ids is non-list JSON', timeout: const Timeout.factor(2), () {
      final row = createRow(sourceFactIds: jsonEncode('a-string'));

      final policy = mapper.toDomain(row);

      expect(policy.sourceFactIds, isEmpty);
    });

    test('parses requiredRole to AgentRole', timeout: const Timeout.factor(2), () {
      final row = createRow(requiredRole: 'coder');

      final policy = mapper.toDomain(row);

      expect(policy.requiredRole, AgentRole.coder);
    });

    test('returns null requiredRole when not set', timeout: const Timeout.factor(2), () {
      final row = createRow(requiredRole: null);

      final policy = mapper.toDomain(row);

      expect(policy.requiredRole, isNull);
    });

    test('returns null requiredRole for unknown role string', timeout: const Timeout.factor(2), () {
      final row = createRow(requiredRole: 'nonexistent_role');

      final policy = mapper.toDomain(row);

      expect(policy.requiredRole, isNull);
    });

    test('maps inactive policy', timeout: const Timeout.factor(2), () {
      final row = createRow(active: false);

      final policy = mapper.toDomain(row);

      expect(policy.active, isFalse);
    });
  });
}
