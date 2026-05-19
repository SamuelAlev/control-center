import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/pipeline_trigger_dao.dart';
import 'package:control_center/features/pipelines/data/repositories/pipeline_trigger_repository_impl.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late PipelineTriggerRepositoryImpl repo;
  late PipelineTriggerDao dao;

  setUp(() async {
    db = createTestDatabase();
    dao = PipelineTriggerDao(db);
    repo = PipelineTriggerRepositoryImpl(dao);
  });

  tearDown(() async {
    await db.close();
  });

  PipelineTrigger makeTrigger({
    String id = 't-1',
    String eventType = 'pr_merged',
    String templateId = 'tmpl-1',
    String workspaceId = 'ws-1',
    bool enabled = true,
    String? cronExpression,
    Map<String, dynamic> match = const {},
  }) =>
      PipelineTrigger(
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

      final result = await repo.getById('t-1');
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

      final result = await repo.getById('t-match');
      expect(result!.match, {'status': 'merged', 'author': 'bot-1'});
    });
  });

  group('update', () {
    test('updates enabled state', () async {
      await repo.insert(makeTrigger());
      final updated = makeTrigger(enabled: false);
      await repo.update(updated);

      final result = await repo.getById('t-1');
      expect(result!.enabled, isFalse);
    });

    test('updates cronExpression', () async {
      await repo.insert(makeTrigger());
      final updated = makeTrigger(cronExpression: 'every:3600');
      await repo.update(updated);

      final result = await repo.getById('t-1');
      expect(result!.cronExpression, 'every:3600');
    });
  });

  group('deleteById', () {
    test('removes the trigger', () async {
      await repo.insert(makeTrigger());
      await repo.deleteById('t-1');

      final result = await repo.getById('t-1');
      expect(result, isNull);
    });
  });

  group('forWorkspace', () {
    test('filters by workspace', () async {
      await repo.insert(makeTrigger(id: 't-1', workspaceId: 'ws-1'));
      await repo.insert(makeTrigger(id: 't-2', workspaceId: 'ws-1'));
      await repo.insert(makeTrigger(id: 't-3', workspaceId: 'ws-2'));

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
    test('returns only enabled triggers for given event across workspaces', () async {
      await repo.insert(makeTrigger(id: 't-1', eventType: 'pr_merged', enabled: true, workspaceId: 'ws-1'));
      await repo.insert(makeTrigger(id: 't-2', eventType: 'pr_merged', enabled: false, workspaceId: 'ws-1'));
      await repo.insert(makeTrigger(id: 't-3', eventType: 'push', enabled: true, workspaceId: 'ws-1'));
      await repo.insert(makeTrigger(id: 't-4', eventType: 'pr_merged', enabled: true, workspaceId: 'ws-2'));

      final results = await repo.enabledForEvent('pr_merged');
      // Cross-workspace: t-1 (ws-1) and t-4 (ws-2), but NOT t-2 (disabled) or t-3 (different event)
      expect(results.length, 2);
      final ids = results.map((t) => t.id).toSet();
      expect(ids, containsAll(['t-1', 't-4']));
    });
  });

  group('markFired', () {
    test('sets lastFiredAt', () async {
      await repo.insert(makeTrigger());
      final when = DateTime(2025, 6, 11, 14, 30);
      await repo.markFired('t-1', when);

      final result = await repo.getById('t-1');
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
      await repo.insert(makeTrigger(id: 'reg-1', eventType: 'pr_merged', enabled: true));

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
