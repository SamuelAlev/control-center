import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/memory_policy_dao.dart';
import 'package:cc_persistence/repositories/dao_memory_policy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DaoMemoryPolicyRepository repo;
  late MemoryPolicyDao dao;

  setUp(() async {
    db = createTestDatabase();
    dao = MemoryPolicyDao(db);
    repo = DaoMemoryPolicyRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  MemoryPolicy makePolicy({
    String id = 'p-1',
    String workspaceId = 'ws-1',
    String domain = 'codebase',
    String rule = 'Allow read access',
    List<String> sourceFactIds = const [],
    AgentRole? requiredRole,
    bool active = true,
  }) =>
      MemoryPolicy(
        id: id,
        workspaceId: workspaceId,
        domain: domain,
        rule: rule,
        sourceFactIds: sourceFactIds,
        requiredRole: requiredRole,
        active: active,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 6, 1),
      );

  group('upsert', () {
    test('inserts a new policy', () async {
      final policy = makePolicy();
      await repo.upsert(policy);

      final result = await repo.getById('ws-1', 'p-1');
      expect(result, isNotNull);
      expect(result!.rule, 'Allow read access');
      expect(result.domain, 'codebase');
    });

    test('updates an existing policy', () async {
      await repo.upsert(makePolicy());
      final updated = makePolicy(rule: 'Deny all write');
      await repo.upsert(updated);

      final result = await repo.getById('ws-1', 'p-1');
      expect(result!.rule, 'Deny all write');
    });

    test('with sourceFactIds round-trip', () async {
      final policy = makePolicy(sourceFactIds: ['f-1', 'f-2', 'f-3']);
      await repo.upsert(policy);

      final result = await repo.getById('ws-1', 'p-1');
      expect(result!.sourceFactIds, ['f-1', 'f-2', 'f-3']);
    });

    test('with requiredRole round-trip', () async {
      final policy = makePolicy(requiredRole: AgentRole.reviewer);
      await repo.upsert(policy);

      final result = await repo.getById('ws-1', 'p-1');
      expect(result!.requiredRole, AgentRole.reviewer);
    });
  });

  group('getById', () {
    test('returns null for unknown policy', () async {
      final result = await repo.getById('ws-1', 'nonexistent');
      expect(result, isNull);
    });

    test('scoped to workspace — not found in wrong workspace', () async {
      await repo.upsert(makePolicy(workspaceId: 'ws-1'));
      final result = await repo.getById('ws-2', 'p-1');
      expect(result, isNull);
    });
  });

  group('getByWorkspace', () {
    test('filters by workspace', () async {
      await repo.upsert(makePolicy(id: 'p-1', workspaceId: 'ws-1', domain: 'a'));
      await repo.upsert(makePolicy(id: 'p-2', workspaceId: 'ws-1', domain: 'b'));
      await repo.upsert(makePolicy(id: 'p-3', workspaceId: 'ws-2', domain: 'c'));

      final ws1 = await repo.getByWorkspace('ws-1');
      expect(ws1.length, 2);

      final ws2 = await repo.getByWorkspace('ws-2');
      expect(ws2.length, 1);
    });

    test('returns empty for unused workspace', () async {
      final policies = await repo.getByWorkspace('empty');
      expect(policies, isEmpty);
    });
  });

  group('getActiveByWorkspace', () {
    test('returns only active policies', () async {
      await repo.upsert(makePolicy(id: 'p-1', active: true));
      await repo.upsert(makePolicy(id: 'p-2', active: false));

      final active = await repo.getActiveByWorkspace('ws-1');
      expect(active.length, 1);
      expect(active.first.id, 'p-1');
    });

    test('filters by domain when provided', () async {
      await repo.upsert(makePolicy(id: 'p-1', domain: 'codebase'));
      await repo.upsert(makePolicy(id: 'p-2', domain: 'security'));

      final codebase = await repo.getActiveByWorkspace('ws-1', domain: 'codebase');
      expect(codebase.length, 1);
      expect(codebase.first.domain, 'codebase');
    });

    test('returns all active when no domain filter', () async {
      await repo.upsert(makePolicy(id: 'p-1', domain: 'codebase'));
      await repo.upsert(makePolicy(id: 'p-2', domain: 'security'));

      final all = await repo.getActiveByWorkspace('ws-1');
      expect(all.length, 2);
    });
  });

  group('delete', () {
    test('removes policy', () async {
      await repo.upsert(makePolicy());
      await repo.delete('ws-1', 'p-1');

      final result = await repo.getById('ws-1', 'p-1');
      expect(result, isNull);
    });

    test('scoped to workspace', () async {
      await repo.upsert(makePolicy(workspaceId: 'ws-1'));
      await repo.delete('ws-2', 'p-1');
      // Should still exist in ws-1
      final result = await repo.getById('ws-1', 'p-1');
      expect(result, isNotNull);
    });
  });

  group('watchByWorkspace', () {
    test('emits current policies', () async {
      await repo.upsert(makePolicy());

      final results = await repo.watchByWorkspace('ws-1').first;
      expect(results.length, 1);
    });
  });
}
