import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/action_policy_mapper.dart'
    show ActionPolicyMapper;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers [DaoActionPolicyRepository] and [ActionPolicyMapper] end-to-end.
/// Exercises the full rule ↔ row round trip, scope filtering and the
/// rule-identity dedup chokepoint.
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
    ActionConstraint? constraint,
    DateTime? expiresAt,
  }) => ActionPolicyRule(
    id: id,
    workspaceId: ws,
    scopeType: scopeType,
    scopeId: scopeId,
    actionClass: actionClass,
    commandPrefix: commandPrefix,
    decision: decision,
    provenance: provenance,
    constraint: constraint,
    expiresAt: expiresAt,
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
            scopeType: ActionScopeType.space,
            scopeId: 'c-1',
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.allow,
          ),
        );
        await repo.upsertRule(
          rule(
            id: 'ap-2',
            scopeType: ActionScopeType.space,
            scopeId: 'c-1',
            actionClass: ActionClass.gitPush,
            decision: ActionDecision.deny,
          ),
        );
        final rows = await repo.rulesForScope(
          'w-1',
          ActionScopeType.space,
          'c-1',
        );
        expect(rows, hasLength(1));
        expect(rows.first.id, 'ap-2');
      },
    );
  });

  group('upsertRule replaces only a rule with the same identity', () {
    final until = DateTime.utc(2025, 1, 1, 8);
    const feature = ActionConstraint(refs: ['feature/**']);

    ActionPolicyRule plain(String id, ActionDecision decision) => rule(
      id: id,
      scopeType: ActionScopeType.space,
      scopeId: 'c-1',
      actionClass: ActionClass.gitPush,
      decision: decision,
    );

    ActionPolicyRule standing(
      String id, {
      ActionConstraint constraint = feature,
      DateTime? expiresAt,
    }) => rule(
      id: id,
      scopeType: ActionScopeType.space,
      scopeId: 'c-1',
      actionClass: ActionClass.gitPush,
      decision: ActionDecision.allow,
      provenance: 'remembered',
      constraint: constraint,
      expiresAt: expiresAt ?? until,
    );

    Future<Set<String>> ids() async => {
      for (final r in await repo.rulesForScope(
        'w-1',
        ActionScopeType.space,
        'c-1',
      ))
        r.id,
    };

    test('a standing approval leaves the plain rule of its class', () async {
      await repo.upsertRule(plain('plain', ActionDecision.prompt));
      await repo.upsertRule(standing('standing'));
      expect(await ids(), {'plain', 'standing'});
    });

    test('a plain rule leaves the standing approvals of its class', () async {
      await repo.upsertRule(standing('standing'));
      await repo.upsertRule(plain('plain-1', ActionDecision.prompt));
      await repo.upsertRule(plain('plain-2', ActionDecision.deny));
      expect(await ids(), {'standing', 'plain-2'});
    });

    test('approving the same thing again refreshes it, no copy', () async {
      await repo.upsertRule(standing('first'));
      final later = until.add(const Duration(hours: 3));
      await repo.upsertRule(standing('second', expiresAt: later));
      expect(await ids(), {'second'});
      expect((await repo.ruleById('w-1', 'second'))?.expiresAt?.toUtc(), later);
    });

    test('approvals of different things coexist', () async {
      await repo.upsertRule(standing('feature'));
      await repo.upsertRule(
        standing(
          'command',
          constraint: const ActionConstraint(commands: ['git push']),
        ),
      );
      expect(await ids(), {'feature', 'command'});
    });

    test('a standing approval leaves a person\'s rule with the same '
        'condition', () async {
      await repo.upsertRule(
        rule(
          id: 'deny-feature',
          scopeType: ActionScopeType.space,
          scopeId: 'c-1',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.deny,
          constraint: feature,
        ),
      );
      await repo.upsertRule(standing('standing'));
      expect(await ids(), {'deny-feature', 'standing'});
    });

    test('a protected-branch deny survives a plain allow, and saving it '
        'again replaces it', () async {
      const trunk = ActionConstraint(refs: ['main']);
      ActionPolicyRule deny(String id) => rule(
        id: id,
        actionClass: ActionClass.gitPush,
        decision: ActionDecision.deny,
        constraint: trunk,
      );
      await repo.upsertRule(deny('deny-1'));
      await repo.upsertRule(
        rule(
          id: 'allow',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.allow,
        ),
      );
      await repo.upsertRule(deny('deny-2'));
      final rows = await repo.rulesForScope(
        'w-1',
        ActionScopeType.workspace,
        '',
      );
      expect({for (final r in rows) r.id}, {'allow', 'deny-2'});
    });

    test('identity stays within its scope', () async {
      await repo.upsertRule(standing('space'));
      await repo.upsertRule(
        rule(
          id: 'workspace',
          actionClass: ActionClass.gitPush,
          decision: ActionDecision.allow,
          provenance: 'remembered',
          constraint: feature,
          expiresAt: until,
        ),
      );
      expect(await ids(), {'space'});
      expect(await repo.rules('w-1'), hasLength(2));
    });
  });
}
