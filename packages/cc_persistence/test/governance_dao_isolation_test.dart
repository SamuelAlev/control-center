import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Governance rows written for one workspace must never surface in another.
///
/// Post-split each workspace is its own database FILE, so these tests prove the
/// repositories route to the right file (`_dbs.of(workspaceId)`) rather than
/// relying on a `WHERE workspace_id = ?` filter — a mis-routed read now returns
/// nothing instead of a foreign row.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('goals are isolated by workspace', () async {
    final repo = DaoGoalRepository(dbs);
    final now = DateTime.utc(2026, 1, 1);
    await repo.upsert(
      OrgGoal(
        id: 'g1',
        workspaceId: 'ws1',
        title: 'WS1 mission',
        level: OrgGoalLevel.company,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repo.upsert(
      OrgGoal(
        id: 'g2',
        workspaceId: 'ws2',
        title: 'WS2 mission',
        level: OrgGoalLevel.company,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Scoped read: ws1's goal is found from ws1, never from ws2.
    expect((await repo.getById('ws1', 'g1'))?.title, 'WS1 mission');
    expect(await repo.getById('ws2', 'g1'), isNull);
    final ws1 = await repo.listByWorkspace('ws1');
    expect(ws1.map((g) => g.id), ['g1']);
    final ws2 = await repo.listByWorkspace('ws2');
    expect(ws2.map((g) => g.id), ['g2']);
  });

  test('approvals are isolated by workspace', () async {
    final repo = DaoApprovalRepository(dbs);
    final now = DateTime.utc(2026, 1, 1);
    await repo.upsert(
      Approval(
        id: 'a1',
        workspaceId: 'ws1',
        title: 'WS1 approval',
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(await repo.getById('ws2', 'a1'), isNull);
    expect((await repo.getById('ws1', 'a1'))?.title, 'WS1 approval');
  });

  test('work products are isolated by workspace', () async {
    final repo = DaoWorkProductRepository(dbs);
    final now = DateTime.utc(2026, 1, 1);
    await repo.upsert(
      WorkProduct(
        id: 'wp1',
        workspaceId: 'ws1',
        title: 'WS1 plan',
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(await repo.getById('ws2', 'wp1'), isNull);
    expect(await repo.watchByWorkspace('ws2').first, isEmpty);
    expect((await repo.watchByWorkspace('ws1').first).map((w) => w.id), [
      'wp1',
    ]);
  });

  test('budget policies are isolated by workspace', () async {
    final repo = DaoBudgetPolicyRepository(dbs);
    await repo.upsertPolicy(
      const BudgetPolicy(
        id: 'p1',
        workspaceId: 'ws1',
        scopeType: 'agent',
        scopeId: 'a1',
        monthlyBudgetCents: 1000,
      ),
    );
    expect(await repo.getPolicyById('ws2', 'p1'), isNull);
    expect((await repo.getPolicyById('ws1', 'p1'))?.monthlyBudgetCents, 1000);
    final ws2 = await repo.listPolicies('ws2');
    expect(ws2, isEmpty);
  });
}
