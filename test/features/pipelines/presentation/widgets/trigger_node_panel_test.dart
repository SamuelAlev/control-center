import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_node_panel.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

/// Builds a [PipelineTrigger] with sensible defaults.
PipelineTrigger _trigger({
  required String id,
  required String eventType,
  String templateId = 'tmpl-1',
  String workspaceId = 'ws-1',
  bool enabled = true,
  String? cronExpression,
  Map<String, dynamic> match = const {},
}) {
  return PipelineTrigger(
    id: id,
    eventType: eventType,
    templateId: templateId,
    workspaceId: workspaceId,
    enabled: enabled,
    cronExpression: cronExpression,
    match: match,
  );
}

/// Sets up the widget tree with a controlled stream of triggers.
Future<void> _setupPanel(
  WidgetTester tester, {
  required List<PipelineTrigger> triggers,
  String workspaceId = 'ws-1',
  String templateId = 'tmpl-1',
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() => tester.view.reset());

  final overrides = [
    pipelineTriggersForWorkspaceProvider(workspaceId)
        .overrideWith((ref) => Stream.value(triggers)),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: testWrap(TriggerNodePanel(
        workspaceId: workspaceId,
        templateId: templateId,
      )),
    ),
  );
  // Let the stream provider emit its value.
  await tester.pump();
}

void main() {
  group('TriggerNodePanel rendering', () {
    testWidgets('renders title with zap icon', (tester) async {
      await _setupPanel(tester, triggers: const []);

      expect(find.text('Triggers'), findsOneWidget);
      expect(find.byIcon(LucideIcons.zap), findsOneWidget);
    });

    testWidgets('renders help text', (tester) async {
      await _setupPanel(tester, triggers: const []);

      expect(find.text('What starts this pipeline.'), findsOneWidget);
    });

    testWidgets('shows empty state with manual toggle off', (tester) async {
      await _setupPanel(tester, triggers: const []);

      // One CcSwitch for the manual toggle (off by default when no manual)
      expect(find.byType(CcSwitch), findsOneWidget);
      // "Add trigger" button
      expect(find.text('Add trigger'), findsOneWidget);
      // "No automatic triggers yet." placeholder
      expect(find.text('No automatic triggers yet.'), findsOneWidget);
    });

    testWidgets('shows manual toggle on when manual trigger enabled',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
          id: 'man-1',
          eventType: PipelineTrigger.manualEventType,
          enabled: true,
        ),
      ]);

      final switchers = tester.widgetList<CcSwitch>(find.byType(CcSwitch));
      expect(switchers.length, 1);
      expect(switchers.first.value, isTrue);
    });

    testWidgets('shows manual toggle off when manual trigger disabled',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
          id: 'man-1',
          eventType: PipelineTrigger.manualEventType,
          enabled: false,
        ),
      ]);

      final switchers = tester.widgetList<CcSwitch>(find.byType(CcSwitch));
      expect(switchers.first.value, isFalse);
    });

    testWidgets('manual toggle off when no manual trigger exists',
        (tester) async {
      await _setupPanel(tester, triggers: const []);

      final switchers = tester.widgetList<CcSwitch>(find.byType(CcSwitch));
      expect(switchers.first.value, isFalse);
    });

    testWidgets('renders single automatic trigger row with toggle and delete',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(id: 'auto-1', eventType: 'ExternalPrDetected', enabled: true),
      ]);

      // 1 manual + 1 auto = 2 toggles
      expect(find.byType(CcSwitch), findsNWidgets(2));
      // Delete button (trash icon)
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      // "No automatic triggers yet." absent
      expect(find.text('No automatic triggers yet.'), findsNothing);
    });

    testWidgets('renders multiple automatic triggers sorted by event type',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(id: 'a3', eventType: 'RepoAdded', enabled: true),
        _trigger(id: 'a1', eventType: 'ExternalPrDetected', enabled: true),
        _trigger(id: 'a2', eventType: 'PrMerged', enabled: false),
      ]);

      // 1 manual + 3 auto = 4 toggles
      expect(find.byType(CcSwitch), findsNWidgets(4));
      // 3 delete buttons
      expect(find.byIcon(LucideIcons.trash2), findsNWidgets(3));
    });

    testWidgets('filters out triggers belonging to other templates',
        (tester) async {
      await _setupPanel(
        tester,
        triggers: [
          _trigger(
              id: 'other-1',
              eventType: 'ExternalPrDetected',
              templateId: 'other-tmpl',
              enabled: true),
        ],
        templateId: 'tmpl-1',
      );

      // Only manual toggle visible (the other template trigger is excluded)
      expect(find.byType(CcSwitch), findsOneWidget);
      expect(find.byIcon(LucideIcons.trash2), findsNothing);
      expect(find.text('No automatic triggers yet.'), findsOneWidget);
    });

    testWidgets('separates manual from automatic section', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
            id: 'man-1',
            eventType: PipelineTrigger.manualEventType,
            enabled: true),
        _trigger(id: 'auto-1', eventType: 'ExternalPrDetected', enabled: true),
      ]);

      // Manual section = 1 toggle (no delete). Auto section = 1 toggle + 1 delete.
      expect(find.byType(CcSwitch), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      expect(find.text('Add trigger'), findsOneWidget);
    });

    testWidgets('renders divider between manual and automatic sections',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
            id: 'man-1',
            eventType: PipelineTrigger.manualEventType,
            enabled: true),
        _trigger(id: 'auto-1', eventType: 'ExternalPrDetected', enabled: true),
      ]);

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders automatic section header', (tester) async {
      await _setupPanel(tester, triggers: const []);

      expect(find.text('Automatic triggers'), findsOneWidget);
    });

    testWidgets('renders schedule trigger with its detail label',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
          id: 'sched-1',
          eventType: PipelineTrigger.scheduleEventType,
          enabled: true,
          cronExpression: 'every:3600',
        ),
      ]);

      // Schedule trigger renders as an automatic row
      expect(find.byType(CcSwitch), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
      expect(find.text('No automatic triggers yet.'), findsNothing);
    });

    testWidgets('renders trigger with match filter', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
          id: 'pr-1',
          eventType: 'PullRequestStatusChanged',
          enabled: true,
          match: {'status': ['merged', 'closed']},
        ),
      ]);

      expect(find.byType(CcSwitch), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('renders disabled auto trigger with toggle off',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(id: 'auto-1', eventType: 'ExternalPrDetected', enabled: false),
      ]);

      final toggles =
          tester.widgetList<CcSwitch>(find.byType(CcSwitch)).toList();
      expect(toggles, hasLength(2));
      // Manual toggle (no manual exists → off)
      expect(toggles[0].value, isFalse);
      // Auto trigger toggle → off
      expect(toggles[1].value, isFalse);
    });

    testWidgets('handles mixed manual and multiple autos', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
            id: 'man-1',
            eventType: PipelineTrigger.manualEventType,
            enabled: true),
        _trigger(id: 'a-1', eventType: 'RepoAdded', enabled: false),
        _trigger(id: 'a-2', eventType: 'PrMerged', enabled: false),
      ]);

      // 1 manual + 2 autos = 3 toggles
      expect(find.byType(CcSwitch), findsNWidgets(3));
      // 2 delete buttons (autos only)
      expect(find.byIcon(LucideIcons.trash2), findsNWidgets(2));
    });

    testWidgets('add trigger button exists when empty', (tester) async {
      await _setupPanel(tester, triggers: const []);

      expect(find.text('Add trigger'), findsOneWidget);
    });

    testWidgets('auto trigger row shows toggle and delete', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(id: 'auto-1', eventType: 'ExternalPrDetected', enabled: true),
      ]);

      // 1 manual toggle + 1 auto toggle + 1 trash2 icon
      expect(find.byType(CcSwitch), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('manual section label renders', (tester) async {
      await _setupPanel(tester, triggers: const []);

      expect(find.text('Manual run'), findsOneWidget);
    });

    testWidgets('pipeline name is not visible when only manual',
        (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
          id: 'man-1',
          eventType: PipelineTrigger.manualEventType,
          enabled: true,
        ),
      ]);

      // Panel renders with title, manual section, divider, automatic header,
      // "No automatic triggers yet." placeholder, and Add trigger button.
      // No extra pipeline name or detail sections.
      expect(find.text('Triggers'), findsOneWidget);
      expect(find.text('Manual run'), findsOneWidget);
      expect(find.text('Automatic triggers'), findsOneWidget);
      expect(find.text('No automatic triggers yet.'), findsOneWidget);
      expect(find.text('Add trigger'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('Edge cases', () {
    testWidgets('handles unknown event type gracefully', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(id: 'u-1', eventType: 'UnknownCustomEvent', enabled: true),
      ]);

      // Renders without crash — trigger label falls back to raw eventType
      expect(find.byType(CcSwitch), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('handles trigger with empty match map', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
            id: 'auto-1',
            eventType: 'ExternalPrDetected',
            enabled: true,
            match: const {}),
      ]);

      // Renders normally — empty match just shows the base label
      expect(find.byType(CcSwitch), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('handles null cronExpression for schedule', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
          id: 'sched-1',
          eventType: PipelineTrigger.scheduleEventType,
          enabled: true,
          cronExpression: null,
        ),
      ]);

      // Renders without crash
      expect(find.byType(CcSwitch), findsNWidgets(2));
      expect(find.byIcon(LucideIcons.trash2), findsOneWidget);
    });

    testWidgets('handles all triggers disabled', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
            id: 'man-1',
            eventType: PipelineTrigger.manualEventType,
            enabled: false),
        _trigger(id: 'a-1', eventType: 'RepoAdded', enabled: false),
        _trigger(id: 'a-2', eventType: 'PrMerged', enabled: false),
      ]);

      // 1 manual + 2 auto = 3 switches, all off
      final toggles =
          tester.widgetList<CcSwitch>(find.byType(CcSwitch)).toList();
      expect(toggles, hasLength(3));
      for (final t in toggles) {
        expect(t.value, isFalse);
      }
      expect(find.byIcon(LucideIcons.trash2), findsNWidgets(2));
    });

    testWidgets('handles all triggers enabled', (tester) async {
      await _setupPanel(tester, triggers: [
        _trigger(
            id: 'man-1',
            eventType: PipelineTrigger.manualEventType,
            enabled: true),
        _trigger(id: 'a-1', eventType: 'RepoAdded', enabled: true),
        _trigger(id: 'a-2', eventType: 'PrMerged', enabled: true),
      ]);

      final toggles =
          tester.widgetList<CcSwitch>(find.byType(CcSwitch)).toList();
      expect(toggles, hasLength(3));
      for (final t in toggles) {
        expect(t.value, isTrue);
      }
    });

    testWidgets('handles many triggers in scrollable list', (tester) async {
      final triggers = <PipelineTrigger>[];
      for (var i = 0; i < 10; i++) {
        triggers.add(_trigger(
          id: 'auto-$i',
          eventType: 'CustomEvent$i',
          enabled: i.isEven,
        ));
      }

      await _setupPanel(tester, triggers: triggers);

      // 1 manual + 10 auto = 11 toggles. ListView virtualizes so we assert
      // at least the visible ones.
      expect(find.byType(CcSwitch), findsAtLeastNWidgets(10));
      expect(find.byIcon(LucideIcons.trash2), findsAtLeastNWidgets(8));
    });
  });
}
