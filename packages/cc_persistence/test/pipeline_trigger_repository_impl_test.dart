import 'package:cc_domain/cc_domain.dart' show WorkspaceMismatchException;
import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_template_removal.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late PipelineTriggerRepositoryImpl repo;
  late InMemorySecretStore secrets;
  late WebhookSecretVault vault;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final ws in ['ws-1', 'ws-2']) {
      await seedTestWorkspace(global, dbs, ws);
      await seedParents(dbs.of(ws), pipelineTemplates: ['tmpl-1', 'tmpl-2']);
    }
    // The route DAO is global: a webhook token must resolve to its workspace
    // BEFORE any workspace file is opened, which is the whole point of the
    // pre-auth route index.
    secrets = InMemorySecretStore();
    vault = WebhookSecretVault(secrets);
    repo = PipelineTriggerRepositoryImpl(dbs, global.workspaceRouteDao, vault);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  PipelineTrigger makeTrigger({
    String id = 't-1',
    String eventType = 'pr_merged',
    String templateId = 'tmpl-1',
    String workspaceId = 'ws-1',
    bool enabled = true,
    String? cronExpression,
    Map<String, dynamic> match = const {},
  }) => PipelineTrigger(
    id: id,
    eventType: eventType,
    templateId: templateId,
    workspaceId: workspaceId,
    enabled: enabled,
    cronExpression: cronExpression,
    match: match,
  );

  group('insert', () {
    test('inserts and retrieves by id', () async {
      final trigger = makeTrigger();
      await repo.insert(trigger);

      final result = await repo.getById('ws-1', 't-1');
      expect(result, isNotNull);
      expect(result!.eventType, 'pr_merged');
      expect(result.templateId, 'tmpl-1');
    });

    test('inserted trigger has match data', () async {
      final trigger = makeTrigger(
        id: 't-match',
        match: {'status': 'merged', 'author': 'bot-1'},
      );
      await repo.insert(trigger);

      final result = await repo.getById('ws-1', 't-match');
      expect(result!.match, {'status': 'merged', 'author': 'bot-1'});
    });
  });

  group('update', () {
    test('updates enabled state', () async {
      await repo.insert(makeTrigger());
      final updated = makeTrigger(enabled: false);
      await repo.update(updated);

      final result = await repo.getById('ws-1', 't-1');
      expect(result!.enabled, isFalse);
    });

    test('updates cronExpression', () async {
      await repo.insert(makeTrigger());
      final updated = makeTrigger(cronExpression: 'every:3600');
      await repo.update(updated);

      final result = await repo.getById('ws-1', 't-1');
      expect(result!.cronExpression, 'every:3600');
    });
  });

  group('webhook route ownership', () {
    test(
      'a token routed to one workspace cannot be re-pointed by another',
      () async {
        await repo.insert(
          makeTrigger(
            id: 'victim',
            eventType: PipelineTrigger.webhookEventType,
          ).copyWith(webhookToken: 'tok-1'),
        );

        final hijack = makeTrigger(
          id: 'attacker',
          eventType: PipelineTrigger.webhookEventType,
          workspaceId: 'ws-2',
        ).copyWith(webhookToken: 'tok-1');
        await expectLater(
          repo.insert(hijack),
          throwsA(isA<WorkspaceMismatchException>()),
        );
        // Refused before the row landed, and the route still points home.
        expect(await repo.getById('ws-2', 'attacker'), isNull);
        expect((await repo.byWebhookToken('tok-1'))?.id, 'victim');

        await repo.insert(
          makeTrigger(
            id: 'attacker',
            eventType: PipelineTrigger.webhookEventType,
            workspaceId: 'ws-2',
          ).copyWith(webhookToken: 'tok-2'),
        );
        await expectLater(
          repo.update(hijack),
          throwsA(isA<WorkspaceMismatchException>()),
        );
        expect((await repo.byWebhookToken('tok-1'))?.workspaceId, 'ws-1');
      },
    );

    test('re-saving a trigger with its own token is allowed', () async {
      final trigger = makeTrigger(
        eventType: PipelineTrigger.webhookEventType,
      ).copyWith(webhookToken: 'tok-1');
      await repo.insert(trigger);
      await repo.update(trigger.copyWith(match: const {'k': 'v'}));
      expect((await repo.byWebhookToken('tok-1'))?.match, {'k': 'v'});
    });
  });

  group('webhook tokens stay out of the databases', () {
    setUp(() async {
      for (final id in ['w-1', 'w-2', 'w-3']) {
        await seedPipelineTemplate(dbs.of('ws-1'), 'tmpl-$id');
      }
    });

    PipelineTrigger webhook({String id = 'w-1', String token = 'tok-1'}) =>
        makeTrigger(
          id: id,
          eventType: PipelineTrigger.webhookEventType,
          templateId: 'tmpl-$id',
        ).copyWith(webhookToken: token);

    Future<List<Object?>> triggerCells() async {
      final rows = await dbs
          .of('ws-1')
          .customSelect('SELECT * FROM pipeline_triggers')
          .get();
      return [for (final row in rows) ...row.data.values];
    }

    test('the row keeps a reference and the route a keyed hash', () async {
      await repo.insert(webhook());

      expect(await triggerCells(), isNot(contains('tok-1')));
      final routeKey = await vault.webhookRouteKey('tok-1');
      expect(routeKey, isNot('tok-1'));
      expect(
        await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.webhookToken,
          routeKey,
        ),
        'ws-1',
      );
      expect(
        await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.webhookToken,
          'tok-1',
        ),
        isNull,
      );
      expect(
        secrets.values[WebhookSecretVault.pipelineTriggerRef('ws-1', routeKey)],
        'tok-1',
      );
      // Every read resolves the token back through the reference.
      expect((await repo.getById('ws-1', 'w-1'))?.webhookToken, 'tok-1');
      expect((await repo.forWorkspace('ws-1')).single.webhookToken, 'tok-1');
      expect((await repo.byWebhookToken('tok-1'))?.id, 'w-1');
      expect(await repo.byWebhookToken('tok-2'), isNull);
    });

    test('the route key depends on the server route key', () async {
      final other = WebhookSecretVault(InMemorySecretStore());
      expect(
        await other.webhookRouteKey('tok-1'),
        isNot(await vault.webhookRouteKey('tok-1')),
      );
      // Minted once, then stable.
      expect(
        await WebhookSecretVault(secrets).webhookRouteKey('tok-1'),
        await vault.webhookRouteKey('tok-1'),
      );
    });

    test('deleting the trigger deletes its secret and its route', () async {
      await repo.insert(webhook());
      final routeKey = await vault.webhookRouteKey('tok-1');
      await repo.deleteById('ws-1', 'w-1');

      expect(
        secrets.values.keys.where((k) => k.startsWith('webhook_secret:')),
        isEmpty,
      );
      expect(
        await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.webhookToken,
          routeKey,
        ),
        isNull,
      );
    });

    test('a rotated token takes the old secret and route with it', () async {
      final trigger = webhook();
      await repo.insert(trigger);
      await repo.update(trigger.copyWith(webhookToken: 'tok-2'));

      expect(await repo.byWebhookToken('tok-1'), isNull);
      expect((await repo.byWebhookToken('tok-2'))?.id, 'w-1');
      expect(secrets.values.values.where((v) => v.startsWith('tok-')), [
        'tok-2',
      ]);
    });

    test('a trigger whose secret is gone reads without a token', () async {
      await repo.insert(webhook());
      await vault.deleteForWorkspace('ws-1');

      expect((await repo.getById('ws-1', 'w-1'))?.webhookToken, isNull);
      expect(await repo.byWebhookToken('tok-1'), isNull);
    });

    test('one token cannot be bound to two triggers of a workspace', () async {
      await repo.insert(webhook());
      await expectLater(
        repo.insert(webhook(id: 'w-2')),
        throwsA(isA<StateError>()),
      );
      expect(await repo.getById('ws-1', 'w-2'), isNull);
      // The first trigger keeps its secret.
      expect((await repo.byWebhookToken('tok-1'))?.id, 'w-1');
    });
  });

  group('deletePipelineTemplate', () {
    test('takes the template, its triggers, their routes and their secrets, '
        'and nothing of another template', () async {
      final db = dbs.of('ws-1');
      await seedPipelineTemplate(db, 'tmpl-hook');
      await repo.insert(
        makeTrigger(
          id: 'hook',
          eventType: PipelineTrigger.webhookEventType,
          templateId: 'tmpl-hook',
        ).copyWith(webhookToken: 'tok-hook'),
      );
      await repo.insert(makeTrigger(id: 'other', templateId: 'tmpl-2'));
      final routeKey = await vault.webhookRouteKey('tok-hook');

      final deleted = await deletePipelineTemplate(
        templates: PipelineTemplateRepositoryImpl(dbs),
        triggers: repo,
        workspaceId: 'ws-1',
        templateId: 'tmpl-hook',
      );

      expect(deleted, 1);
      expect(await repo.getById('ws-1', 'hook'), isNull);
      expect(
        await global.workspaceRouteDao.resolve(
          WorkspaceRouteKind.webhookToken,
          routeKey,
        ),
        isNull,
      );
      expect(secrets.values.values, isNot(contains('tok-hook')));
      expect(await repo.getById('ws-1', 'other'), isNotNull);
    });

    test('answers 0 for a template the workspace does not have', () async {
      expect(
        await deletePipelineTemplate(
          templates: PipelineTemplateRepositoryImpl(dbs),
          triggers: repo,
          workspaceId: 'ws-1',
          templateId: 'absent',
        ),
        0,
      );
    });
  });

  group('deleteById', () {
    test('removes the trigger', () async {
      await repo.insert(makeTrigger());
      await repo.deleteById('ws-1', 't-1');

      final result = await repo.getById('ws-1', 't-1');
      expect(result, isNull);
    });
  });

  group('forWorkspace', () {
    test('filters by workspace', () async {
      // Distinct templateIds: uq_pipeline_triggers is (workspaceId, eventType,
      // templateId), so two triggers in one workspace need different triples.
      await repo.insert(
        makeTrigger(id: 't-1', workspaceId: 'ws-1', templateId: 'tmpl-1'),
      );
      await repo.insert(
        makeTrigger(id: 't-2', workspaceId: 'ws-1', templateId: 'tmpl-2'),
      );
      await repo.insert(
        makeTrigger(id: 't-3', workspaceId: 'ws-2', templateId: 'tmpl-1'),
      );

      final ws1 = await repo.forWorkspace('ws-1');
      expect(ws1.length, 2);

      final ws2 = await repo.forWorkspace('ws-2');
      expect(ws2.length, 1);
    });

    test('returns empty for unused workspace', () async {
      final results = await repo.forWorkspace('empty');
      expect(results, isEmpty);
    });
  });

  group('enabledForEvent', () {
    test(
      'returns only enabled triggers for given event across workspaces',
      () async {
        // t-1/t-2 share (ws-1, pr_merged) so they must differ by templateId to
        // satisfy uq_pipeline_triggers; t-3 differs by eventType, t-4 by workspace.
        await repo.insert(
          makeTrigger(
            id: 't-1',
            eventType: 'pr_merged',
            enabled: true,
            workspaceId: 'ws-1',
            templateId: 'tmpl-1',
          ),
        );
        await repo.insert(
          makeTrigger(
            id: 't-2',
            eventType: 'pr_merged',
            enabled: false,
            workspaceId: 'ws-1',
            templateId: 'tmpl-2',
          ),
        );
        await repo.insert(
          makeTrigger(
            id: 't-3',
            eventType: 'push',
            enabled: true,
            workspaceId: 'ws-1',
            templateId: 'tmpl-1',
          ),
        );
        await repo.insert(
          makeTrigger(
            id: 't-4',
            eventType: 'pr_merged',
            enabled: true,
            workspaceId: 'ws-2',
            templateId: 'tmpl-1',
          ),
        );

        final results = await repo.enabledForEvent('pr_merged');
        // Cross-workspace: t-1 (ws-1) and t-4 (ws-2), but NOT t-2 (disabled) or t-3 (different event)
        expect(results.length, 2);
        final ids = results.map((t) => t.id).toSet();
        expect(ids, containsAll(['t-1', 't-4']));
      },
    );
  });

  group('markFired', () {
    test('sets lastFiredAt', () async {
      await repo.insert(makeTrigger());
      final when = DateTime(2025, 6, 11, 14, 30);
      await repo.markFired('ws-1', 't-1', when);

      final result = await repo.getById('ws-1', 't-1');
      expect(result!.lastFiredAt, when);
    });
  });

  group('scheduled', () {
    test('returns enabled triggers with schedule event type', () async {
      // Insert a schedule trigger
      final sched = makeTrigger(
        id: 'sched-1',
        eventType: PipelineTrigger.scheduleEventType,
        cronExpression: 'every:3600',
        enabled: true,
      );
      await repo.insert(sched);
      await repo.insert(
        makeTrigger(id: 'reg-1', eventType: 'pr_merged', enabled: true),
      );

      final scheduled = await repo.scheduled();
      expect(scheduled.length, 1);
      expect(scheduled.first.id, 'sched-1');
    });

    test('does not return disabled schedule triggers', () async {
      final sched = makeTrigger(
        id: 'sched-1',
        eventType: PipelineTrigger.scheduleEventType,
        enabled: false,
      );
      await repo.insert(sched);

      final scheduled = await repo.scheduled();
      expect(scheduled, isEmpty);
    });
  });

  group('watchForWorkspace', () {
    test('emits current triggers', () async {
      await repo.insert(makeTrigger(workspaceId: 'ws-1'));

      final results = await repo.watchForWorkspace('ws-1').first;
      expect(results.length, 1);
    });
  });
}
