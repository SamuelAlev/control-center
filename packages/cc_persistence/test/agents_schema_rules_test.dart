import 'package:cc_domain/cc_domain.dart' show ConcurrencyConflictException;
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/action_policy_mapper.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

/// Records the SQL of every read so a test can ask SQLite how it plans the
/// exact statement a DAO sent.
class _CaptureReads extends QueryInterceptor {
  final List<(String, List<Object?>)> reads = [];

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    reads.add((statement, args));
    return executor.runSelect(statement, args);
  }
}

/// The statement that creates [index].
String _sqlOf(Index index) => index.createStatementsByDialect.values.first;

void main() {
  late WorkspaceDatabase db;

  setUp(() => db = createTestDatabase(workspaceId: 'ws'));
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT count(*) AS n FROM $table').getSingle())
          .read<int>('n');

  Iterable<Index> indexesOf(String table) => db.allSchemaEntities
      .whereType<Index>()
      .where((index) => _sqlOf(index).contains(' ON $table '));

  Set<String> declaredIndexes(String table) => {
    for (final index in indexesOf(table)) index.entityName,
  };

  group('action_policies', () {
    Future<void> upsert({
      required String id,
      String scopeType = 'workspace',
      String scopeId = '',
      String? actionClass = 'gitPush',
      String? commandPrefix,
      String decision = 'prompt',
      String provenance = 'user',
      String? constraintJson,
    }) => db.actionPolicyDao.upsertRule(
      ActionPoliciesTableCompanion.insert(
        id: id,
        workspaceId: 'ws',
        scopeType: scopeType,
        scopeId: Value(scopeId),
        actionClass: Value(actionClass),
        commandPrefix: Value(commandPrefix),
        decision: Value(decision),
        provenance: Value(provenance),
        constraintJson: Value(constraintJson),
      ),
    );

    test('two writes of the same rule leave one row', () async {
      await upsert(id: 'first', decision: 'prompt');
      await upsert(id: 'second', decision: 'deny');

      final rows = await db.select(db.actionPoliciesTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'second');
      expect(rows.single.decision, 'deny');
    });

    test('the same subject at another scope is another rule', () async {
      await seedSpace(db, 'space-1');
      await upsert(id: 'workspace-rule');
      await upsert(id: 'space-rule', scopeType: 'space', scopeId: 'space-1');
      await upsert(id: 'command-rule', actionClass: null, commandPrefix: 'git');

      expect(await count('action_policies'), 3);
    });

    test('a standing approval coexists with the plain rule', () async {
      await upsert(id: 'plain', decision: 'deny');
      await upsert(
        id: 'standing',
        decision: 'allow',
        provenance: 'remembered',
        constraintJson: '{"refs":["feature/*"]}',
      );
      await upsert(
        id: 'standing-again',
        decision: 'allow',
        provenance: 'remembered',
        constraintJson: '{"refs":["feature/*"]}',
      );

      expect([
        for (final r in await db.select(db.actionPoliciesTable).get()) r.id,
      ], unorderedEquals(['plain', 'standing-again']));
    });

    test('editing a rule into another rule identity is refused', () async {
      await upsert(id: 'push');
      await upsert(id: 'pr', actionClass: 'prCreate');

      await expectLater(
        upsert(id: 'pr', actionClass: 'gitPush'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a rule names exactly one subject and a matching scope', () async {
      await expectLater(
        upsert(id: 'none', actionClass: null),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        upsert(id: 'both', commandPrefix: 'git'),
        throwsA(isA<SqliteException>()),
      );
      await expectLater(
        upsert(id: 'scoped-workspace', scopeId: 'space-1'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('the mapper refuses a provenance a stored rule cannot have', () {
      final rule = ActionPolicyRule(
        id: 'managed',
        workspaceId: 'ws',
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        commandPrefix: 'git',
        decision: ActionDecision.deny,
        provenance: 'managed',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(
        () => const ActionPolicyMapper().ruleToCompanion(rule),
        throwsArgumentError,
      );
    });
  });

  group('declared slot and dedupe keys', () {
    test('a cron slot is guarded by the class index alone', () {
      final unique = [
        for (final index in indexesOf('cron_executions'))
          if (_sqlOf(index).contains('UNIQUE')) index.entityName,
      ];
      expect(unique, ['idx_cron_executions_slot']);
    });

    test('a second claim of one cron slot loses', () async {
      await seedPipelineTemplate(db, 'template');
      await db.pipelineTriggerDao.insert(
        PipelineTriggersTableCompanion.insert(
          id: 'trigger',
          eventType: 'schedule',
          templateId: 'template',
          workspaceId: 'ws',
        ),
      );
      final planned = DateTime.utc(2026, 11, 12, 3);
      Future<bool> claim(String id) => db.cronExecutionDao.claimSlot(
        id: id,
        workspaceId: 'ws',
        triggerId: 'trigger',
        plannedAt: planned,
      );

      expect(await claim('a'), isTrue);
      expect(await claim('b'), isFalse);
      expect(await count('cron_executions'), 1);
    });

    test('the webhook dedupe key is declared on the table', () {
      expect(
        declaredIndexes('webhook_deliveries'),
        contains('uq_webhook_deliveries_dedupe'),
      );
    });

    test('the live pipeline run dedupe key is declared on the table', () {
      expect(
        declaredIndexes('pipeline_runs'),
        containsAll([
          'uq_pipeline_runs_active_dedup',
          'idx_pipeline_runs_template_status',
        ]),
      );
    });

    test('the run log index the recent-runs list reads is declared', () {
      expect(
        declaredIndexes('agent_run_logs'),
        containsAll([
          'idx_agent_run_logs_started',
          'idx_agent_run_logs_agent_started',
          'idx_agent_run_logs_conversation_started',
        ]),
      );
    });
  });

  group('natural keys take the write', () {
    test('a budget policy is one per scope', () async {
      Future<void> write(String id, int micros) => db.budgetDao.upsertPolicy(
        BudgetPolicyTableCompanion.insert(
          id: id,
          workspaceId: 'ws',
          scopeType: 'agent',
          scopeId: 'agent-1',
          monthlyBudgetMicros: Value(micros),
        ),
      );
      await write('p1', 100);
      await write('p2', 200);

      final rows = await db.select(db.budgetPolicyTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'p1');
      expect(rows.single.monthlyBudgetMicros, 200);
    });

    test('a ticket sync config is one per vendor', () async {
      Future<void> write(String id) => db.ticketSyncDao.upsertConfig(
        TicketSyncConfigsTableCompanion.insert(
          id: id,
          workspaceId: 'ws',
          vendor: 'linear',
        ),
      );
      await write('c1');
      await write('c2');
      expect(await count('ticket_sync_configs'), 1);
    });

    test('a ticket sync link is one per ticket and vendor', () async {
      await seedTicket(db, 'ticket');
      Future<void> write(String id, String externalId) =>
          db.ticketSyncDao.upsertLink(
            TicketSyncLinksTableCompanion.insert(
              id: id,
              workspaceId: 'ws',
              ticketId: 'ticket',
              vendor: 'linear',
              externalId: externalId,
            ),
          );
      await write('l1', 'ext-1');
      await write('l2', 'ext-2');

      final rows = await db.select(db.ticketSyncLinksTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'l1');
      expect(rows.single.externalId, 'ext-2');
    });

    test('a sandbox exec decision is one per folder', () async {
      Future<void> write(String id, String decision) =>
          db.sandboxExecGrantDao.upsert(
            SandboxExecGrantsTableCompanion.insert(
              id: id,
              workspaceId: 'ws',
              path: '/work/tree',
              decision: Value(decision),
            ),
          );
      await write('g1', 'deny');
      await write('g2', 'allow');

      final rows = await db.select(db.sandboxExecGrantsTable).get();
      expect(rows, hasLength(1));
      expect(rows.single.id, 'g1');
      expect(rows.single.decision, 'allow');
    });

    test('a skill source is one per repository', () async {
      Future<void> write(String id) => db.skillSourceDao.upsert(
        SkillSourcesTableCompanion.insert(
          id: id,
          workspaceId: 'ws',
          owner: 'acme',
          repo: 'skills',
          url: 'https://github.com/acme/skills',
        ),
      );
      await write('s1');
      await write('s2');
      expect(await count('skill_sources'), 1);
    });

    test('two writers of one revision number: the second conflicts', () async {
      final global = createTestGlobalDatabase();
      final dbs = createTestWorkspaceDatabases(global: global);
      addTearDown(() async {
        await dbs.closeAll();
        await global.close();
      });
      await seedTestWorkspace(global, dbs, 'ws-1');
      await dbs
          .of('ws-1')
          .workProductDao
          .upsert(
            WorkProductsTableCompanion.insert(
              id: 'wp',
              workspaceId: 'ws-1',
              title: 'Plan',
            ),
          );
      final repo = DaoWorkProductRepository(dbs);
      WorkProductRevision revision(String id) => WorkProductRevision(
        id: id,
        workProductId: 'wp',
        workspaceId: 'ws-1',
        revisionNumber: 1,
        content: id,
        createdAt: DateTime(2026),
      );

      await repo.addRevision(revision('r1'));
      await expectLater(
        repo.addRevision(revision('r2')),
        throwsA(isA<ConcurrencyConflictException>()),
      );
      expect(
        [for (final r in await repo.getRevisions('ws-1', 'wp')) r.id],
        ['r1'],
      );
    });
  });

  group('delete rules', () {
    test('a run log outlives its conversation, not its agent', () async {
      await seedConversation(db, 'conv');
      await seedRunLog(db, 'run', agentId: 'agent');
      await db.customStatement(
        "UPDATE agent_run_logs SET conversation_id = 'conv' WHERE id = 'run'",
      );

      await db.customStatement("DELETE FROM conversations WHERE id = 'conv'");
      final row = await db
          .customSelect(
            "SELECT conversation_id FROM agent_run_logs WHERE id = 'run'",
          )
          .getSingle();
      expect(row.read<String?>('conversation_id'), isNull);

      await db.customStatement("DELETE FROM agents WHERE id = 'agent'");
      expect(await count('agent_run_logs'), 0);
    });

    test('a run log refuses an id that is not a conversation', () async {
      await seedSpace(db, 'space-only');
      await seedRunLog(db, 'run');
      await expectLater(
        db.customStatement(
          "UPDATE agent_run_logs SET conversation_id = 'space-only' "
          "WHERE id = 'run'",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a call usage goes with its run', () async {
      await seedRunLog(db, 'run');
      await db.customStatement(
        'INSERT INTO run_call_usages '
        '(id, workspace_id, run_id, request_id, started_at, recorded_at) '
        "VALUES ('run/req/1', 'ws', 'run', 'req', 0, 0)",
      );
      await db.customStatement("DELETE FROM agent_run_logs WHERE id = 'run'");
      expect(await count('run_call_usages'), 0);
    });

    test('a team member goes with the team', () async {
      await seedTeam(db, 'team');
      await seedAgent(db, 'agent');
      await db.customStatement(
        'INSERT INTO team_members (team_id, agent_id) '
        "VALUES ('team', 'agent')",
      );
      await db.customStatement("DELETE FROM teams WHERE id = 'team'");
      expect(await count('team_members'), 0);
      expect(await count('agents'), 1);
    });

    test(
      'a template delete takes its triggers, a re-seed keeps them',
      () async {
        await seedPipelineTemplate(db, 'template');
        await db.pipelineTriggerDao.insert(
          PipelineTriggersTableCompanion.insert(
            id: 'trigger',
            eventType: 'manual',
            templateId: 'template',
            workspaceId: 'ws',
          ),
        );

        await db.pipelineTemplateDao.upsert(
          PipelineTemplatesTableCompanion.insert(
            id: 'template',
            workspaceId: 'ws',
            name: 'Re-seeded',
          ),
        );
        expect(await count('pipeline_triggers'), 1);

        await db.pipelineTemplateDao.deleteById('ws', 'template');
        expect(await count('pipeline_triggers'), 0);
      },
    );

    test('a pipeline run outlives its template', () async {
      await seedPipelineTemplate(db, 'template');
      await seedPipelineRun(db, 'run', templateId: 'template');
      await db.pipelineTemplateDao.deleteById('ws', 'template');
      expect(await count('pipeline_runs'), 1);
    });

    test('deleting a project leaves its tickets without one', () async {
      await seedProject(db, 'project');
      await seedTicket(db, 'ticket');
      await db.customStatement(
        "UPDATE tickets SET project_id = 'project' WHERE id = 'ticket'",
      );
      await db.projectDao.deleteProject('project', 'ws');
      final row = await db
          .customSelect("SELECT project_id FROM tickets WHERE id = 'ticket'")
          .getSingle();
      expect(row.read<String?>('project_id'), isNull);
    });

    test('deleting a goal makes its children roots', () async {
      await db.customStatement(
        'INSERT INTO goals (id, workspace_id, title) '
        "VALUES ('parent', 'ws', 'Parent')",
      );
      await db.customStatement(
        'INSERT INTO goals (id, workspace_id, title, parent_goal_id) '
        "VALUES ('child', 'ws', 'Child', 'parent')",
      );
      await db.goalDao.deleteById('ws', 'parent');
      final row = await db
          .customSelect("SELECT parent_goal_id FROM goals WHERE id = 'child'")
          .getSingle();
      expect(row.read<String?>('parent_goal_id'), isNull);
    });
  });

  group('closed value sets', () {
    test('a status outside the enum is refused', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO pipeline_runs (id, template_id, workspace_id, status) '
          "VALUES ('run', 't', 'ws', 'paused')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('a JSON column refuses text that is not JSON', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO pipeline_runs '
          '(id, template_id, workspace_id, state_json) '
          "VALUES ('run', 't', 'ws', 'not json')",
        ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('run log reads use their index', () {
    late WorkspaceDatabase planned;
    late _CaptureReads capture;

    setUp(() async {
      capture = _CaptureReads();
      planned = WorkspaceDatabase.forTesting(
        NativeDatabase.memory().interceptWith(capture),
        workspaceId: 'ws',
      );
      await seedConversation(planned, 'conv');
      await seedRunLog(planned, 'run');
    });
    tearDown(() => planned.close());

    Future<String> planOfLastRead() async {
      final (sql, args) = capture.reads.last;
      final rows = await planned.executor.runSelect(
        'EXPLAIN QUERY PLAN $sql',
        args,
      );
      return rows.map((r) => r['detail']).join('\n');
    }

    test('the recent-runs watch walks the start index', () async {
      await planned.agentDao.watchRecentLogs(20).first;
      final plan = await planOfLastRead();
      expect(plan, contains('idx_agent_run_logs_started'));
      expect(plan, isNot(contains('TEMP B-TREE')));
    });

    test('the non-terminal read probes the status index', () async {
      await planned.agentDao.nonTerminalLogs();
      expect(await planOfLastRead(), contains('idx_agent_run_logs_status'));
    });

    test('the per-conversation list walks its index in order', () async {
      await planned.agentDao.watchLogsByConversation('ws', 'conv').first;
      final plan = await planOfLastRead();
      expect(plan, contains('idx_agent_run_logs_conversation_started'));
      expect(plan, isNot(contains('TEMP B-TREE')));
    });
  });
}
