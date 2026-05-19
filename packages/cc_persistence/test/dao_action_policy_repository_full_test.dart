import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/action_policy_mapper.dart'
    show ActionPolicyMapper;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers [DaoActionPolicyRepository] and [ActionPolicyMapper] end-to-end.
/// Exercises the full rule ↔ row round trip, scope filtering, and the
/// "at most one rule per (scope, actionClass|commandPrefix)" dedup chokepoint.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoActionPolicyRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoActionPolicyRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  ActionPolicyRule rule({
    required String id,
    String ws = 'w-1',
    ActionScopeType scopeType = ActionScopeType.workspace,
    String scopeId = '',
    ActionClass? actionClass,
    String? commandPrefix,
    ActionDecision decision = ActionDecision.prompt,
    String provenance = 'user',
  }) => ActionPolicyRule(
    id: id,
    workspaceId: ws,
    scopeType: scopeType,
    scopeId: scopeId,
    actionClass: actionClass,
    commandPrefix: commandPrefix,
    decision: decision,
    provenance: provenance,
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 1),
  );

  group('DaoActionPolicyRepository round trip', () {
    test('upsert + ruleById + rules + rulesForScope', () async {
      final r = rule(
        id: 'ap-1',
        actionClass: ActionClass.gitPush,
        decision: ActionDecision.allow,
      );
      await repo.upsertRule(r);

      final fetched = await repo.ruleById('w-1', 'ap-1');
      expect(fetched?.decision, ActionDecision.allow);
      expect(fetched?.actionClass, ActionClass.gitPush);
      expect(fetched?.commandPrefix, isNull);

      expect(await repo.rules('w-1'), hasLength(1));
      expect(
        (await repo.rulesForScope(
          'w-1',
          ActionScopeType.workspace,
          '',
        )).first.id,
        'ap-1',
      );
    });

    test('command-prefix rules round-trip with actionClass null', () async {
      await repo.upsertRule(
        rule(
          id: 'ap-1',
          commandPrefix: 'git push',
          decision: ActionDecision.deny,
        ),
      );
      final fetched = await repo.ruleById('w-1', 'ap-1');
      expect(fetched?.commandPrefix, 'git push');
      expect(fetched?.actionClass, isNull);
      expect(fetched?.decision, ActionDecision.deny);
    });

    test('watchRules emits scoped + mapped rows', () async {
      await repo.upsertRule(rule(id: 'ap-1', actionClass: ActionClass.gitPush));
      final rows = await repo.watchRules('w-1').first;
      expect(rows, hasLength(1));
      expect(rows.first.actionClass, ActionClass.gitPush);
    });

    test('rules + watchRules are workspace-scoped', () async {
      await repo.upsertRule(
        rule(id: 'ap-1', ws: 'w-1', actionClass: ActionClass.gitPush),
      );
      await repo.upsertRule(
        rule(id: 'ap-2', ws: 'w-2', actionClass: ActionClass.gitPush),
      );
      expect(await repo.rules('w-1'), hasLength(1));
      expect(await repo.watchRules('w-2').first, hasLength(1));
    });

    test('deleteRule removes the row within the workspace', () async {
      await repo.upsertRule(rule(id: 'ap-1', actionClass: ActionClass.gitPush));
      await repo.deleteRule('w-1', 'ap-1');
      expect(await repo.ruleById('w-1', 'ap-1'), isNull);
    });

    test(
      'upsertRule dedups a logical duplicate (same scope + actionClass)',
      () async {
        // Two rules with different ids but identical (scope, actionClass) — the
        // repository chokepoint must delete the older one so only one remains.
        await repo.upsertRule(
          rule(
            id: 'ap-1',
            scopeType: ActionScopeType.channel,
            scopeId: 'c-1',
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.allow,
          ),
        );
        await repo.upsertRule(
          rule(
            id: 'ap-2',
            scopeType: ActionScopeType.channel,
            scopeId: 'c-1',
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.deny,
          ),
        );
        final rows = await repo.rulesForScope(
          'w-1',
          ActionScopeType.channel,
          'c-1',
        );
        expect(rows, hasLength(1));
        expect(rows.first.id, 'ap-2');
      },
    );
  });
}
