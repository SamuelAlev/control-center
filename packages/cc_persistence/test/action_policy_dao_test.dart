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

  Future<void> seedRule({
    required String id,
    required String ws,
    required String scopeType,
    required String scopeId,
    String? actionClass,
    String? commandPrefix,
    String decision = 'prompt',
    String provenance = 'user',
  }) => db.actionPolicyDao.upsertRule(
    ActionPoliciesTableCompanion.insert(
      id: id,
      workspaceId: ws,
      scopeType: scopeType,
      scopeId: Value(scopeId),
      actionClass: actionClass == null
          ? const Value.absent()
          : Value(actionClass),
      commandPrefix: commandPrefix == null
          ? const Value.absent()
          : Value(commandPrefix),
      decision: Value(decision),
      provenance: Value(provenance),
    ),
  );

  group('ActionPolicyDao workspace isolation', () {
    test('upsert + rules returns only rows for the workspace', () async {
      await seedRule(
        id: 'ap-1',
        ws: 'w-1',
        scopeType: 'workspace',
        scopeId: '',
        actionClass: 'Bash',
        decision: 'allow',
      );
      await seedRule(
        id: 'ap-2',
        ws: 'w-2',
        scopeType: 'workspace',
        scopeId: '',
        actionClass: 'Bash',
        decision: 'deny',
      );

      final rows = await db.actionPolicyDao.rules('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.id, 'ap-1');
      expect(rows.first.decision, 'allow');
    });

    test('upsert replaces on conflict (same id)', () async {
      await seedRule(
        id: 'ap-1',
        ws: 'w-1',
        scopeType: 'workspace',
        scopeId: '',
        actionClass: 'Bash',
        decision: 'allow',
      );
      await seedRule(
        id: 'ap-1',
        ws: 'w-1',
        scopeType: 'workspace',
        scopeId: '',
        actionClass: 'Bash',
        decision: 'deny',
      );
      final rows = await db.actionPolicyDao.rules('w-1');
      expect(rows, hasLength(1));
      expect(rows.first.decision, 'deny');
    });

    test('watchRules emits scoped + ordered rows', () async {
      await seedRule(
        id: 'ap-b',
        ws: 'w-1',
        scopeType: 'space',
        scopeId: 'c-2',
        commandPrefix: 'git push',
      );
      await seedRule(
        id: 'ap-a',
        ws: 'w-1',
        scopeType: 'space',
        scopeId: 'c-1',
        commandPrefix: 'git push',
      );
      final rows = await db.actionPolicyDao.watchRules('w-1').first;
      expect(rows.map((r) => r.id).toList(), ['ap-a', 'ap-b']);
    });

    test('rulesForScope is scoped by (ws, scopeType, scopeId)', () async {
      await seedRule(
        id: 'ap-1',
        ws: 'w-1',
        scopeType: 'space',
        scopeId: 'c-1',
        commandPrefix: 'git',
      );
      await seedRule(
        id: 'ap-2',
        ws: 'w-1',
        scopeType: 'space',
        scopeId: 'c-2',
        commandPrefix: 'git',
      );
      await seedRule(
        id: 'ap-3',
        ws: 'w-2',
        scopeType: 'space',
        scopeId: 'c-1',
        commandPrefix: 'git',
      );

      final rows = await db.actionPolicyDao.rulesForScope(
        'w-1',
        'space',
        'c-1',
      );
      expect(rows, hasLength(1));
      expect(rows.first.id, 'ap-1');
    });

    test('ruleById returns the row only within its workspace', () async {
      await seedRule(
        id: 'ap-1',
        ws: 'w-1',
        scopeType: 'workspace',
        scopeId: '',
        actionClass: 'Bash',
      );
      expect((await db.actionPolicyDao.ruleById('w-1', 'ap-1'))?.id, 'ap-1');
      expect(await db.actionPolicyDao.ruleById('w-2', 'ap-1'), isNull);
      expect(await db.actionPolicyDao.ruleById('w-1', 'missing'), isNull);
    });

    test(
      'deleteRule is workspace-scoped — foreign workspace is a no-op',
      () async {
        await seedRule(
          id: 'ap-1',
          ws: 'w-1',
          scopeType: 'workspace',
          scopeId: '',
          actionClass: 'Bash',
        );
        // A foreign workspace cannot delete it.
        await db.actionPolicyDao.deleteRule('w-2', 'ap-1');
        expect(await db.actionPolicyDao.ruleById('w-1', 'ap-1'), isNotNull);

        // The owning workspace can.
        await db.actionPolicyDao.deleteRule('w-1', 'ap-1');
        expect(await db.actionPolicyDao.ruleById('w-1', 'ap-1'), isNull);
      },
    );
  });
}
