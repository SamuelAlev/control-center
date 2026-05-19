import 'package:cc_domain/features/agents/domain/services/budget_policy_service.dart';
import 'package:cc_domain/features/governance/domain/entities/budget_incident.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/budget_mapper.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises [DaoBudgetPolicyRepository] and [BudgetMapper] end-to-end against
/// an in-memory database. Covers every repository method (policies + incidents)
/// and the mapper's nullable-period branches.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late BudgetMapper mapper;
  late DaoBudgetPolicyRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    mapper = const BudgetMapper();
    repo = DaoBudgetPolicyRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  BudgetPolicy policy({
    String id = 'bp-1',
    String workspaceId = 'w-1',
    String scopeType = 'agent',
    String scopeId = 'a-1',
    int monthlyBudgetCents = 10_000,
    int softThresholdPercent = 80,
    bool hardStopEnabled = true,
    int spentCents = 0,
    String status = 'active',
    DateTime? periodStart,
    DateTime? periodEnd,
    DateTime? createdAt,
  }) => BudgetPolicy(
    id: id,
    workspaceId: workspaceId,
    scopeType: scopeType,
    scopeId: scopeId,
    monthlyBudgetCents: monthlyBudgetCents,
    softThresholdPercent: softThresholdPercent,
    hardStopEnabled: hardStopEnabled,
    spentCents: spentCents,
    status: status,
    periodStart: periodStart,
    periodEnd: periodEnd,
    createdAt: createdAt,
  );

  BudgetIncident incident({
    String id = 'bi-1',
    String workspaceId = 'w-1',
    String scopeType = 'agent',
    String scopeId = 'a-1',
    int spentCents = 12_000,
    int budgetCents = 10_000,
    bool isHardStop = true,
    String reason = 'budget_exhausted',
    String? policyId = 'bp-1',
  }) => BudgetIncident(
    id: id,
    workspaceId: workspaceId,
    policyId: policyId,
    scopeType: scopeType,
    scopeId: scopeId,
    spentCents: spentCents,
    budgetCents: budgetCents,
    isHardStop: isHardStop,
    reason: reason,
    triggeredAt: DateTime(2026, 1, 1),
  );

  group('BudgetMapper companion branches', () {
    test('policyToCompanion handles nullable periodStart / createdAt', () {
      final companion = mapper.policyToCompanion(
        policy(periodStart: null, createdAt: null),
      );
      expect(companion.periodStart.present, isFalse);
      expect(companion.createdAt.present, isFalse);
    });

    test('policyToCompanion forwards present period fields', () {
      final companion = mapper.policyToCompanion(
        policy(periodStart: DateTime(2026, 1, 1), createdAt: DateTime(2026)),
      );
      expect(companion.periodStart.present, isTrue);
      expect(companion.createdAt.present, isTrue);
    });
  });

  group('DaoBudgetPolicyRepository policies', () {
    test('listPolicies returns empty when absent', () async {
      expect(await repo.listPolicies('w-1'), isEmpty);
    });

    test('upsertPolicy then listPolicies round-trips', () async {
      await repo.upsertPolicy(policy());
      final policies = await repo.listPolicies('w-1');
      expect(policies, hasLength(1));
      expect(policies.first.scopeId, 'a-1');
      expect(policies.first.monthlyBudgetCents, 10_000);
    });

    test('getPolicyById is workspace-scoped', () async {
      await repo.upsertPolicy(policy(id: 'bp-1', workspaceId: 'w-1'));
      expect(await repo.getPolicyById('w-1', 'bp-1'), isNotNull);
      expect(await repo.getPolicyById('w-2', 'bp-1'), isNull);
      expect(await repo.getPolicyById('w-1', 'missing'), isNull);
    });

    test('getPolicyForScope finds the governing policy', () async {
      await repo.upsertPolicy(policy(scopeType: 'agent', scopeId: 'a-1'));
      final found = await repo.getPolicyForScope('w-1', 'agent', 'a-1');
      expect(found, isNotNull);
      expect(found!.scopeId, 'a-1');
      // Wrong scope returns null.
      expect(await repo.getPolicyForScope('w-1', 'agent', 'a-2'), isNull);
    });

    test('watchPolicies emits only the workspace rows', () async {
      await repo.upsertPolicy(policy(id: 'bp-1', workspaceId: 'w-1'));
      await repo.upsertPolicy(policy(id: 'bp-2', workspaceId: 'w-2'));
      final rows = await repo.watchPolicies('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'bp-1');
    });

    test('upsertPolicy replaces on conflict (same id PK)', () async {
      await repo.upsertPolicy(policy(spentCents: 1));
      await repo.upsertPolicy(policy(spentCents: 99));
      final loaded = await repo.getPolicyById('w-1', 'bp-1');
      expect(loaded?.spentCents, 99);
    });

    test('deletePolicy is workspace-scoped', () async {
      await repo.upsertPolicy(policy(id: 'bp-1', workspaceId: 'w-1'));
      await repo.deletePolicy('w-2', 'bp-1');
      expect(await repo.getPolicyById('w-1', 'bp-1'), isNotNull);
      await repo.deletePolicy('w-1', 'bp-1');
      expect(await repo.getPolicyById('w-1', 'bp-1'), isNull);
    });
  });

  group('DaoBudgetPolicyRepository incidents', () {
    test('recordIncident + incidentsForScope round-trips', () async {
      await repo.recordIncident(incident());
      final incidents = await repo.incidentsForScope('w-1', 'agent', 'a-1');
      expect(incidents, hasLength(1));
      expect(incidents.first.isHardStop, isTrue);
      expect(incidents.first.reason, 'budget_exhausted');
    });

    test('incidentsForScope is workspace-scoped', () async {
      await repo.recordIncident(incident(workspaceId: 'w-1'));
      await repo.recordIncident(
        incident(id: 'bi-2', workspaceId: 'w-2', scopeId: 'a-2'),
      );
      expect(await repo.incidentsForScope('w-2', 'agent', 'a-1'), isEmpty);
      expect(await repo.incidentsForScope('w-2', 'agent', 'a-2'), hasLength(1));
    });

    test('watchIncidents emits only the workspace rows', () async {
      await repo.recordIncident(incident(workspaceId: 'w-1'));
      await repo.recordIncident(incident(id: 'bi-2', workspaceId: 'w-2'));
      final rows = await repo.watchIncidents('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'bi-1');
    });

    test('recordIncident without a policy id round-trips', () async {
      await repo.recordIncident(incident(policyId: null));
      final incidents = await repo.incidentsForScope('w-1', 'agent', 'a-1');
      expect(incidents, hasLength(1));
      expect(incidents.first.policyId, isNull);
    });
  });
}
