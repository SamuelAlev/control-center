import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late WorkspaceDatabase db;

  setUp(() async {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedPolicy({
    required String id,
    required String ws,
    required String scopeType,
    required String scopeId,
    int monthlyBudgetCents = 1000,
  }) => db.budgetDao.upsertPolicy(
    BudgetPolicyTableCompanion.insert(
      id: id,
      workspaceId: Value(ws),
      scopeType: scopeType,
      scopeId: scopeId,
      monthlyBudgetCents: Value(monthlyBudgetCents),
    ),
  );

  group('BudgetDao policies', () {
    test('getPolicies is workspace-scoped', () async {
      await seedPolicy(
        id: 'bp-1',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-1',
      );
      await seedPolicy(
        id: 'bp-2',
        ws: 'w-2',
        scopeType: 'agent',
        scopeId: 'a-2',
      );

      final rows = await db.budgetDao.getPolicies('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'bp-1');
    });

    test('watchPolicies emits scoped rows', () async {
      await seedPolicy(
        id: 'bp-1',
        ws: 'w-1',
        scopeType: 'workspace',
        scopeId: '',
      );
      final rows = await db.budgetDao.watchPolicies('w-1').first;
      expect(rows, hasLength(1));
    });

    test('upsertPolicy replaces on conflict (same id PK)', () async {
      await seedPolicy(
        id: 'bp-1',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-1',
        monthlyBudgetCents: 1000,
      );
      await seedPolicy(
        id: 'bp-1',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-1',
        monthlyBudgetCents: 2000,
      );
      final row = await db.budgetDao.getPolicyById('w-1', 'bp-1');
      expect(row?.monthlyBudgetCents, 2000);
    });

    test('getPolicyById is workspace-scoped', () async {
      await seedPolicy(
        id: 'bp-1',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-1',
      );
      expect((await db.budgetDao.getPolicyById('w-1', 'bp-1'))?.id, 'bp-1');
      expect(await db.budgetDao.getPolicyById('w-2', 'bp-1'), isNull);
      expect(await db.budgetDao.getPolicyById('w-1', 'missing'), isNull);
    });

    test('getPolicyForScope is workspace-scoped', () async {
      await seedPolicy(
        id: 'bp-1',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-1',
      );
      await seedPolicy(
        id: 'bp-2',
        ws: 'w-2',
        scopeType: 'agent',
        scopeId: 'a-1',
      );
      expect(
        (await db.budgetDao.getPolicyForScope('w-1', 'agent', 'a-1'))?.id,
        'bp-1',
      );
      expect(
        await db.budgetDao.getPolicyForScope('w-2', 'agent', 'a-1'),
        isNotNull,
      );
      // Uncapped scope returns null.
      expect(
        await db.budgetDao.getPolicyForScope('w-1', 'agent', 'unknown'),
        isNull,
      );
    });

    test(
      'deletePolicy is workspace-scoped — foreign workspace is a no-op',
      () async {
        await seedPolicy(
          id: 'bp-1',
          ws: 'w-1',
          scopeType: 'agent',
          scopeId: 'a-1',
        );
        expect(await db.budgetDao.deletePolicy('w-2', 'bp-1'), 0);
        expect(await db.budgetDao.getPolicyById('w-1', 'bp-1'), isNotNull);
        expect(await db.budgetDao.deletePolicy('w-1', 'bp-1'), 1);
        expect(await db.budgetDao.getPolicyById('w-1', 'bp-1'), isNull);
      },
    );
  });

  group('BudgetDao incidents', () {
    Future<void> seedIncident({
      required String id,
      required String ws,
      required String scopeType,
      required String scopeId,
      bool hardStop = false,
    }) => db.budgetDao.insertIncident(
      BudgetIncidentsTableCompanion.insert(
        id: id,
        workspaceId: ws,
        scopeType: scopeType,
        scopeId: scopeId,
        spentCents: 800,
        budgetCents: 1000,
        isHardStop: Value(hardStop),
        reason: 'soft_threshold',
      ),
    );

    test('watchIncidents is workspace-scoped, newest first', () async {
      await seedIncident(
        id: 'bi-1',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-1',
      );
      await seedIncident(
        id: 'bi-2',
        ws: 'w-2',
        scopeType: 'agent',
        scopeId: 'a-2',
      );
      final rows = await db.budgetDao.watchIncidents('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.id, 'bi-1');
    });

    test('incidentsForScope is workspace + scope scoped', () async {
      await seedIncident(
        id: 'bi-1',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-1',
      );
      await seedIncident(
        id: 'bi-2',
        ws: 'w-1',
        scopeType: 'agent',
        scopeId: 'a-2',
      );
      await seedIncident(
        id: 'bi-3',
        ws: 'w-2',
        scopeType: 'agent',
        scopeId: 'a-1',
      );
      final rows = await db.budgetDao.incidentsForScope('w-1', 'agent', 'a-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'bi-1');
    });
  });
}
