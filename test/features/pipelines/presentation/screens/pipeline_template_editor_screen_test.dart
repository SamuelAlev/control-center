import 'dart:async';

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_template_editor_screen.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_config_editor.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_node_panel.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';
import '../../../../helpers/test_wrap.dart';

const _workspaceId = 'ws-1';
const _templateId = 'pipeline_1';

class _FixedWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceIdNotifier(this._id);
  final String _id;

  @override
  String? build() => _id;
}

class _FakeTemplateRepo implements PipelineTemplateRepository {
  _FakeTemplateRepo(this.template);

  PipelineDefinition template;
  PipelineDefinition? lastUpsert;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => template.templateId == templateId ? template : null;

  @override
  Future<void> upsert(PipelineDefinition definition) async {
    lastUpsert = definition;
    template = definition;
  }

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async => [
    template,
  ];

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) =>
      Stream.value([template]);

  @override
  Future<int> deleteById(String workspaceId, String templateId) async => 0;
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
  Future<PipelineTrigger?> byWebhookToken(String token) async {
    for (final t in items) {
      if (t.webhookToken == token) {
        return t;
      }
    }
    return null;
  }
}

PipelineDefinition _draft() {
  return PipelineDefinition(
    templateId: _templateId,
    workspaceId: _workspaceId,
    name: 'New pipeline',
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
        config: const PipelineNodeConfig(label: 'Trigger'),
        x: 0,
        y: 0,
      ),
      PipelineStepDefinition(
        id: 'step',
        kind: StepKind.listen,
        bodyKey: 'conversation.promptAgent',
        triggers: const [
          StepTrigger(sourceStepIds: ['trigger']),
        ],
        x: 280,
        y: 0,
      ),
      PipelineStepDefinition(
        id: r'step$terminal',
        kind: StepKind.terminal,
        bodyKey: '_terminal_step',
        triggers: const [
          StepTrigger(sourceStepIds: ['step']),
        ],
      ),
    ],
  );
}

/// cc_ui wraps icon buttons in [CcTooltip], which [CommonFinders.byTooltip]
/// (Material-only) cannot see — match the button's own tooltip instead.
Finder _iconButton(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);

Widget _wrap(_FakeTemplateRepo repo, _FakeTriggerRepo triggers) {
  return ProviderScope(
    overrides: [
      activeWorkspaceIdProvider.overrideWith(
        () => _FixedWorkspaceIdNotifier(_workspaceId),
      ),
      pipelineTemplateRepositoryProvider.overrideWithValue(repo),
      pipelineTriggerRepositoryProvider.overrideWithValue(triggers),
      reposForWorkspaceProvider(
        _workspaceId,
      ).overrideWith((ref) => Stream.value(const [])),
      agentRepositoryProvider.overrideWithValue(FakeAgentRepository()),
    ],
    child: testWrap(
      const PipelineTemplateEditorScreen(templateId: _templateId),
    ),
  );
}

/// The editor is a three-pane desktop surface (240 sidebar + canvas + 360
/// panel); the default 800x600 test viewport overflows it.
Future<void> _pumpEditor(
  WidgetTester tester,
  _FakeTemplateRepo repo, [
  _FakeTriggerRepo? triggers,
]) async {
  final triggerRepo = triggers ?? _FakeTriggerRepo();
  addTearDown(triggerRepo.dispose);
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_wrap(repo, triggerRepo));
  await tester.pumpAndSettle();
}

PipelineEditorCanvas _canvas(WidgetTester tester) =>
    tester.widget<PipelineEditorCanvas>(find.byType(PipelineEditorCanvas));

void main() {
  group('PipelineTemplateEditorScreen', () {
    testWidgets('does not open a config panel until a node is selected', (
      tester,
    ) async {
      final repo = _FakeTemplateRepo(_draft());
      final triggers = _FakeTriggerRepo()
        ..items.add(
          PipelineTrigger(
            id: 'trig-1',
            eventType: PipelineTrigger.manualEventType,
            templateId: _templateId,
            workspaceId: _workspaceId,
            enabled: true,
          ),
        );
      await _pumpEditor(tester, repo, triggers);

      expect(find.text('New pipeline'), findsOneWidget);
      expect(
        find.text(
          'Drag node types from the sidebar onto the canvas, then wire them together.',
        ),
        findsOneWidget,
      );
      expect(find.byType(TriggerNodePanel), findsNothing);
      expect(find.byType(NodeConfigEditor), findsNothing);
      // The trigger panel carries its own CcSwitch, so scope the assertion to
      // the header row that labels the template-level toggle.
      expect(
        find.descendant(
          of: find
              .ancestor(of: find.text('Enabled'), matching: find.byType(Row))
              .first,
          matching: find.byType(CcSwitch),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pencil swaps the title for a field; Enter commits', (
      tester,
    ) async {
      final repo = _FakeTemplateRepo(_draft());
      await _pumpEditor(tester, repo);

      await tester.tap(_iconButton('Rename'));
      await tester.pump();

      // The node library sidebar has its own search CcTextField; the title
      // editor is the only autofocused one.
      final titleField = find.byWidgetPredicate(
        (w) => w is CcTextField && w.autofocus,
      );
      expect(titleField, findsOneWidget);
      await tester.enterText(titleField, 'Deploy pipeline');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Deploy pipeline'), findsOneWidget);
      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('selecting a trigger node shows the trigger panel', (
      tester,
    ) async {
      final repo = _FakeTemplateRepo(_draft());
      final triggers = _FakeTriggerRepo()
        ..items.add(
          PipelineTrigger(
            id: 'trig-1',
            eventType: PipelineTrigger.manualEventType,
            templateId: _templateId,
            workspaceId: _workspaceId,
            enabled: true,
          ),
        );
      await _pumpEditor(tester, repo, triggers);

      _canvas(tester).onSelectTrigger('trig-1');
      await tester.pump();

      expect(find.byType(TriggerNodePanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TriggerNodePanel),
          matching: find.text('Manual run'),
        ),
        findsOneWidget,
      );
      expect(find.text('Triggers'), findsNothing);
      expect(find.text('Add trigger'), findsNothing);
    });

    testWidgets('onAddTrigger inserts through the trigger repository', (
      tester,
    ) async {
      final repo = _FakeTemplateRepo(_draft());
      final triggers = _FakeTriggerRepo();
      await _pumpEditor(tester, repo, triggers);

      _canvas(tester).onAddTrigger(PipelineTrigger.manualEventType);
      await tester.pump();
      await tester.pump();

      expect(triggers.items, hasLength(1));
      final created = triggers.items.single;
      expect(created.eventType, PipelineTrigger.manualEventType);
      expect(created.enabled, isTrue);
      expect(created.templateId, _templateId);
      expect(created.workspaceId, _workspaceId);
      expect(find.byType(TriggerNodePanel), findsOneWidget);
    });

    testWidgets('onAddTrigger uses per-kind defaults', (tester) async {
      final repo = _FakeTemplateRepo(_draft());
      final triggers = _FakeTriggerRepo();
      await _pumpEditor(tester, repo, triggers);

      _canvas(tester).onAddTrigger(PipelineTrigger.scheduleEventType);
      await tester.pump();
      _canvas(tester).onAddTrigger(PipelineTrigger.webhookEventType);
      await tester.pump();
      _canvas(tester).onAddTrigger('PullRequestStatusChanged');
      await tester.pump();

      expect(triggers.items, hasLength(3));

      final schedule = triggers.items.firstWhere(
        (t) => t.eventType == PipelineTrigger.scheduleEventType,
      );
      expect(schedule.enabled, isFalse);
      expect(schedule.cronExpression, 'every:86400');

      final webhook = triggers.items.firstWhere(
        (t) => t.eventType == PipelineTrigger.webhookEventType,
      );
      expect(webhook.enabled, isFalse);
      expect(webhook.webhookToken, isNotNull);
      expect(webhook.webhookToken, isNot(contains('-')));

      final event = triggers.items.firstWhere(
        (t) => t.eventType == 'PullRequestStatusChanged',
      );
      expect(event.enabled, isFalse);
    });

    testWidgets('onDeleteTrigger removes the row and clears the panel', (
      tester,
    ) async {
      final repo = _FakeTemplateRepo(_draft());
      final triggers = _FakeTriggerRepo()
        ..items.add(
          PipelineTrigger(
            id: 'trig-1',
            eventType: PipelineTrigger.webhookEventType,
            templateId: _templateId,
            workspaceId: _workspaceId,
            webhookToken: 'tok',
          ),
        );
      await _pumpEditor(tester, repo, triggers);

      _canvas(tester).onSelectTrigger('trig-1');
      await tester.pump();
      expect(find.byType(TriggerNodePanel), findsOneWidget);

      _canvas(tester).onDeleteTrigger('trig-1');
      await tester.pump();
      await tester.pump();

      expect(triggers.items, isEmpty);
      expect(find.byType(TriggerNodePanel), findsNothing);
    });
  });
}
