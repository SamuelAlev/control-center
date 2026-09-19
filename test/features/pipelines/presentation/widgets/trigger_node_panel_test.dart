import 'dart:async';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_node_panel.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

PipelineTrigger _trigger({
  required String id,
  required String eventType,
  String templateId = 'tmpl-1',
  String workspaceId = 'ws-1',
  bool enabled = true,
  String? cronExpression,
  String? timezone,
  String? webhookToken,
  CronCatchUpPolicy catchUpPolicy = CronCatchUpPolicy.catchUpLatestOnly,
  Map<String, dynamic> match = const {},
}) {
  return PipelineTrigger(
    id: id,
    eventType: eventType,
    templateId: templateId,
    workspaceId: workspaceId,
    enabled: enabled,
    cronExpression: cronExpression,
    timezone: timezone,
    webhookToken: webhookToken,
    catchUpPolicy: catchUpPolicy,
    match: match,
  );
}

class _FakeTriggerRepo implements PipelineTriggerRepository {
  final List<PipelineTrigger> items = [];
  final _controller = StreamController<List<PipelineTrigger>>.broadcast();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<PipelineTrigger>.unmodifiable(items));
    }
  }

  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  @override
  Future<void> insert(PipelineTrigger trigger) async {
    items.add(trigger);
    _emit();
  }

  @override
  Future<void> update(PipelineTrigger trigger) async {
    final i = items.indexWhere((t) => t.id == trigger.id);
    if (i >= 0) {
      items[i] = trigger;
    } else {
      items.add(trigger);
    }
    _emit();
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async {
    items.removeWhere((t) => t.id == id && t.workspaceId == workspaceId);
    _emit();
  }

  @override
  Future<List<PipelineTrigger>> forWorkspace(String workspaceId) async => [
    for (final t in items)
      if (t.workspaceId == workspaceId) t,
  ];

  @override
  Future<List<PipelineTrigger>> enabledForEvent(String eventType) async => [
    for (final t in items)
      if (t.enabled && t.eventType == eventType) t,
  ];

  @override
  Stream<List<PipelineTrigger>> watchForWorkspace(String workspaceId) async* {
    yield List<PipelineTrigger>.unmodifiable(items);
    yield* _controller.stream;
  }

  @override
  Future<PipelineTrigger?> getById(String workspaceId, String id) async {
    for (final t in items) {
      if (t.id == id && t.workspaceId == workspaceId) {
        return t;
      }
    }
    return null;
  }

  @override
  Future<List<PipelineTrigger>> scheduled() async => [
    for (final t in items)
      if (t.eventType == PipelineTrigger.scheduleEventType) t,
  ];

  @override
  Future<void> markFired(String workspaceId, String id, DateTime when) async {}

  @override
  Future<void> setSchedule(
    String workspaceId,
    String id, {
    DateTime? nextRunAt,
    DateTime? lastFiredAt,
  }) async {}

  @override
  Future<PipelineTrigger?> byWebhookToken(String token) async => null;
}

Future<void> _setupPanel(
  WidgetTester tester, {
  required List<PipelineTrigger> triggers,
  required String triggerId,
  String workspaceId = 'ws-1',
  String templateId = 'tmpl-1',
  _FakeTriggerRepo? repo,
  VoidCallback? onDelete,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final triggerRepo = repo ?? _FakeTriggerRepo();
  if (repo == null) {
    triggerRepo.items.addAll(triggers);
    addTearDown(triggerRepo.dispose);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pipelineTriggerRepositoryProvider.overrideWithValue(triggerRepo),
      ],
      child: testWrap(
        TriggerNodePanel(
          workspaceId: workspaceId,
          templateId: templateId,
          triggerId: triggerId,
          onDelete: onDelete ?? () {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('TriggerNodePanel', () {
    testWidgets('renders nothing when the selected trigger is missing', (
      tester,
    ) async {
      await _setupPanel(tester, triggers: const [], triggerId: 'missing');

      expect(find.byType(CcSwitch), findsNothing);
      expect(find.text('Add trigger'), findsNothing);
      expect(find.text('Triggers'), findsNothing);
    });

    testWidgets('inspects only the selected manual trigger', (tester) async {
      await _setupPanel(
        tester,
        triggers: [
          _trigger(
            id: 'man-1',
            eventType: PipelineTrigger.manualEventType,
            enabled: true,
          ),
          _trigger(id: 'auto-1', eventType: 'ExternalPrDetected'),
        ],
        triggerId: 'man-1',
      );

      expect(find.text('Manual run'), findsOneWidget);
      expect(
        find.text('Show on the run page and start by hand.'),
        findsOneWidget,
      );
      expect(find.byType(CcSwitch), findsOneWidget);
      expect(tester.widget<CcSwitch>(find.byType(CcSwitch)).value, isTrue);
      expect(find.byIcon(AppIcons.trash2), findsOneWidget);
      expect(find.text('Add trigger'), findsNothing);
      expect(find.text('Automatic triggers'), findsNothing);
      expect(find.text('External PR opened'), findsNothing);
    });

    testWidgets('lets a schedule trigger change its expression', (
      tester,
    ) async {
      final repo = _FakeTriggerRepo()
        ..items.add(
          _trigger(
            id: 'sched-1',
            eventType: PipelineTrigger.scheduleEventType,
            enabled: false,
            cronExpression: 'every:86400',
          ),
        );
      addTearDown(repo.dispose);

      await _setupPanel(
        tester,
        triggers: repo.items,
        triggerId: 'sched-1',
        repo: repo,
      );

      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Schedule (cron or every:seconds)'), findsOneWidget);
      expect(find.text('Timezone (optional)'), findsOneWidget);
      expect(find.text('On missed runs'), findsOneWidget);

      final fields = find.byType(CcTextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.first, 'every:60');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();

      expect(repo.items.single.cronExpression, 'every:60');
    });

    testWidgets('coerces a bare number to every:N', (tester) async {
      final repo = _FakeTriggerRepo()
        ..items.add(
          _trigger(
            id: 'sched-1',
            eventType: PipelineTrigger.scheduleEventType,
            cronExpression: 'every:86400',
          ),
        );
      addTearDown(repo.dispose);

      await _setupPanel(
        tester,
        triggers: repo.items,
        triggerId: 'sched-1',
        repo: repo,
      );

      await tester.enterText(find.byType(CcTextField).first, '3600');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pump();

      expect(repo.items.single.cronExpression, 'every:3600');
    });

    testWidgets('shows the webhook path for a webhook trigger', (tester) async {
      await _setupPanel(
        tester,
        triggers: [
          _trigger(
            id: 'hook-1',
            eventType: PipelineTrigger.webhookEventType,
            webhookToken: 'abc123',
          ),
        ],
        triggerId: 'hook-1',
      );

      expect(find.text('Webhook'), findsOneWidget);
      expect(find.text('Webhook path'), findsOneWidget);
      expect(find.text('/webhooks/abc123'), findsOneWidget);
      expect(find.byIcon(AppIcons.copy), findsOneWidget);
    });

    testWidgets('edits PR status chips on the selected event trigger', (
      tester,
    ) async {
      final repo = _FakeTriggerRepo()
        ..items.add(
          _trigger(
            id: 'pr-1',
            eventType: 'PullRequestStatusChanged',
            match: {
              'status': ['merged'],
            },
          ),
        );
      addTearDown(repo.dispose);

      await _setupPanel(
        tester,
        triggers: repo.items,
        triggerId: 'pr-1',
        repo: repo,
      );

      expect(find.text('PR status changed'), findsOneWidget);
      expect(find.text('PullRequestStatusChanged'), findsOneWidget);
      expect(
        find.text(
          'Merged, closed, opened, reopened, or approved. Filter by status in the inspector.',
        ),
        findsOneWidget,
      );
      expect(find.text('Only when the status is'), findsOneWidget);

      final merged = tester.widget<CcChip>(
        find.widgetWithText(CcChip, 'merged'),
      );
      expect(merged.selected, isTrue);
      final closed = tester.widget<CcChip>(
        find.widgetWithText(CcChip, 'closed'),
      );
      expect(closed.selected, isFalse);

      await tester.tap(find.widgetWithText(CcChip, 'closed'));
      await tester.pump();
      await tester.pump();

      final statuses = repo.items.single.match['status'] as List<dynamic>;
      expect(statuses, containsAll(['merged', 'closed']));
    });

    testWidgets('persists the enabled switch on the selected trigger', (
      tester,
    ) async {
      final repo = _FakeTriggerRepo()
        ..items.add(
          _trigger(
            id: 'auto-1',
            eventType: 'ExternalPrDetected',
            enabled: false,
          ),
        );
      addTearDown(repo.dispose);

      await _setupPanel(
        tester,
        triggers: repo.items,
        triggerId: 'auto-1',
        repo: repo,
      );

      expect(tester.widget<CcSwitch>(find.byType(CcSwitch)).value, isFalse);
      await tester.tap(find.byType(CcSwitch));
      await tester.pump();
      await tester.pump();

      expect(repo.items.single.enabled, isTrue);
    });

    testWidgets('delete calls onDelete for the selected trigger only', (
      tester,
    ) async {
      var deleted = false;
      await _setupPanel(
        tester,
        triggers: [
          _trigger(id: 'auto-1', eventType: 'PrMerged'),
          _trigger(id: 'auto-2', eventType: 'RepoAdded'),
        ],
        triggerId: 'auto-1',
        onDelete: () => deleted = true,
      );

      expect(find.text('PR merged'), findsOneWidget);
      expect(find.text('Repository added'), findsNothing);
      await tester.tap(find.byIcon(AppIcons.trash2));
      await tester.pump();
      expect(deleted, isTrue);
    });

    testWidgets('unknown event type falls back to the raw type name', (
      tester,
    ) async {
      await _setupPanel(
        tester,
        triggers: [_trigger(id: 'u-1', eventType: 'UnknownCustomEvent')],
        triggerId: 'u-1',
      );

      expect(find.text('UnknownCustomEvent'), findsOneWidget);
      expect(find.byType(CcSwitch), findsOneWidget);
    });
  });
}
