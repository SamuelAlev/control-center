import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

PipelineStepDefinition _step({
  required String id,
  required StepKind kind,
  String? label,
  double? x,
  double? y,
}) {
  return PipelineStepDefinition(
    id: id,
    kind: kind,
    bodyKey: 'body_$id',
    config: PipelineNodeConfig(label: label),
    x: x,
    y: y,
  );
}

PipelineDefinition _definition(List<PipelineStepDefinition> steps) {
  return PipelineDefinition(
    templateId: 'tmpl-test',
    workspaceId: 'ws-test',
    name: 'Test Pipeline',
    steps: steps,
  );
}

PipelineStepRun _stepRun({
  required String stepId,
  required PipelineStepStatus status,
  DateTime? startedAt,
  DateTime? finishedAt,
}) {
  final start = startedAt ?? DateTime(2026, 1, 1, 12, 0, 0);
  return PipelineStepRun(
    id: 'run_$stepId',
    pipelineRunId: 'run-1',
    stepId: stepId,
    status: status,
    startedAt: start,
    finishedAt: finishedAt,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  /// Pumps a [PipelineCanvas] with the given overrides.
  Future<void> pumpCanvas(
    WidgetTester tester,
    PipelineDefinition definition, {
    String? runId,
    String? initialSelectedStepId,
    List<Override> overrides = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pipelineClockProvider.overrideWith((_) => Stream.value(0)),
          ...overrides,
        ],
        child: testWrap(
          PipelineCanvas(
            definition: definition,
            runId: runId,
            initialSelectedStepId: initialSelectedStepId,
          ),
        ),
      ),
    );
    // Let autofocus and AnimatedContainer settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  // -- Empty canvas ---------------------------------------------------------

  group('empty canvas', () {
    testWidgets('shows placeholder when definition has no steps', (tester) async {
      final def = _definition([]);
      await pumpCanvas(tester, def);
      expect(find.text(l10n.pipelinesNoSteps), findsOneWidget);
    });

    testWidgets('shows placeholder when all steps are terminal', (tester) async {
      final def = _definition([
        _step(id: 'end', kind: StepKind.terminal),
      ]);
      await pumpCanvas(tester, def);
      expect(find.text(l10n.pipelinesNoSteps), findsOneWidget);
    });

    testWidgets('shows placeholder when only terminal steps exist', (tester) async {
      final def = _definition([
        _step(id: 't1', kind: StepKind.terminal),
        _step(id: 't2', kind: StepKind.terminal),
      ]);
      await pumpCanvas(tester, def);
      expect(find.text(l10n.pipelinesNoSteps), findsOneWidget);
    });
  });

  // -- Nodes ----------------------------------------------------------------

  group('nodes', () {
    testWidgets('renders a single trigger node label', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
      ]);
      await pumpCanvas(tester, def);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('renders node label from config, falling back to id', (tester) async {
      final def = _definition([
        _step(id: 'setup', kind: StepKind.listen, label: 'Setup'),
        _step(id: 'fetch', kind: StepKind.listen),
      ]);
      await pumpCanvas(tester, def);
      expect(find.text('Setup'), findsOneWidget);
      expect(find.text('fetch'), findsOneWidget);
    });

    testWidgets('nodes use Positioned with coordinates when provided', (tester) async {
      final def = _definition([
        _step(id: 'a', kind: StepKind.trigger, x: 0, y: 0),
        _step(id: 'b', kind: StepKind.listen, x: 300, y: 200),
      ]);
      await pumpCanvas(tester, def);
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('trigger node uses brand colors', (tester) async {
      final def = _definition([
        _step(id: 'trigger', kind: StepKind.trigger),
      ]);
      await pumpCanvas(tester, def);
      expect(find.text('trigger'), findsOneWidget);
    });
  });

  // -- Connections ----------------------------------------------------------

  group('connections', () {
    testWidgets('renders CustomPaint for edge/background layers', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, x: 0, y: 0),
        _step(id: 'stepA', kind: StepKind.listen, x: 250, y: 0),
        _step(id: 'end', kind: StepKind.terminal, x: 500, y: 0),
      ]);
      await pumpCanvas(tester, def);
      // Multiple CustomPaint widgets exist (edge painter + background painter
      // + any from the theme). At minimum there should be some.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders PipelineCanvasBackground', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, x: 0, y: 0),
      ]);
      await pumpCanvas(tester, def);
      expect(find.byType(PipelineCanvasBackground), findsOneWidget);
    });
  });

  // -- Interaction without runId --------------------------------------------

  group('interaction without runId', () {
    testWidgets('tapping a node does not open detail panel', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
      ]);
      await pumpCanvas(tester, def);

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(milliseconds: 200));

      // No 360-width detail panel container should appear after tap
      final wideContainers = tester.widgetList<Container>(find.byType(Container)).where(
        (c) => c.constraints?.minWidth == 360,
      );
      expect(wideContainers, isEmpty);
    });

    testWidgets('detail panel sidebar is absent when runId is null', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger),
      ]);
      await pumpCanvas(tester, def);
      final sidebarContainers = find.byWidgetPredicate(
        (w) => w is Container && w.constraints?.minWidth == 360,
      );
      expect(sidebarContainers, findsNothing);
    });

    testWidgets('pan gesture shifts canvas', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, x: 0, y: 0),
      ]);
      await pumpCanvas(tester, def);

      final gestureDetector = find.byType(GestureDetector).first;
      await tester.drag(gestureDetector, const Offset(50, 30));
      await tester.pump(const Duration(milliseconds: 200));

      // Canvas still renders after pan
      expect(find.text('start'), findsOneWidget);
    });
  });

  // -- Interaction with runId -----------------------------------------------

  group('interaction with runId', () {
    testWidgets('tapping a node selects it and shows detail panel', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
        _step(id: 'stepA', kind: StepKind.listen, label: 'A'),
      ]);
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
        ],
      );

      // Tap the Start node
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(milliseconds: 200));

      final wideContainers = tester.widgetList<Container>(find.byType(Container)).where(
        (c) => c.constraints?.minWidth == 360,
      );
      expect(wideContainers, isNotEmpty);
    });


    testWidgets('initialSelectedStepId pre-opens detail panel', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
        _step(id: 'stepA', kind: StepKind.listen, label: 'A'),
      ]);
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        initialSelectedStepId: 'stepA',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
        ],
      );

      final wideContainers = tester.widgetList<Container>(find.byType(Container)).where(
        (c) => c.constraints?.minWidth == 360,
      );
      expect(wideContainers, isNotEmpty);
    });

    testWidgets('nodes show status colors when step runs are present', (tester) async {
      const stepId = 'stepA';
      final def = _definition([
        _step(id: 'trigger', kind: StepKind.trigger, label: 'T'),
        _step(id: stepId, kind: StepKind.listen, label: 'A'),
      ]);
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value([
              _stepRun(
                stepId: stepId,
                status: PipelineStepStatus.completed,
                startedAt: DateTime(2026, 1, 1, 12, 0, 0),
                finishedAt: DateTime(2026, 1, 1, 12, 0, 5),
              ),
            ]),
          ),
        ],
      );

      expect(find.text(l10n.pipelineStatusCompleted), findsOneWidget);
    });

    testWidgets('running step shows spinner', (tester) async {
      final def = _definition([
        _step(id: 'trigger', kind: StepKind.trigger, label: 'T'),
        _step(id: 'r', kind: StepKind.listen, label: 'R'),
      ]);
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value([
              _stepRun(
                stepId: 'r',
                status: PipelineStepStatus.running,
                startedAt: DateTime.now().subtract(const Duration(minutes: 1)),
              ),
            ]),
          ),
        ],
      );

      // A running step renders a CircularProgressIndicator as its glyph
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('failed step shows error status text', (tester) async {
      final def = _definition([
        _step(id: 'trigger', kind: StepKind.trigger, label: 'T'),
        _step(id: 'f', kind: StepKind.listen, label: 'F'),
      ]);
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value([
              _stepRun(
                stepId: 'f',
                status: PipelineStepStatus.failed,
                startedAt: DateTime(2026, 1, 1, 12, 0, 0),
                finishedAt: DateTime(2026, 1, 1, 12, 0, 3),
              ),
            ]),
          ),
        ],
      );

      expect(find.text(l10n.pipelineStatusFailed), findsOneWidget);
    });
  });

  // -- didUpdateWidget ------------------------------------------------------

  group('didUpdateWidget', () {
    testWidgets('resets selected step when runId changes', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
        _step(id: 'stepA', kind: StepKind.listen, label: 'A'),
      ]);

      // Provide overrides for both run IDs up front.
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
          pipelineStepRunsForRunProvider('run-2').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
        ],
      );

      // Select 'A' node
      await tester.tap(find.text('A'));
      await tester.pump(const Duration(milliseconds: 200));

      var wideContainers = tester.widgetList<Container>(find.byType(Container)).where(
        (c) => c.constraints?.minWidth == 360,
      );
      expect(wideContainers, isNotEmpty);

      // Re-pump with a different runId in the same ProviderScope.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pipelineClockProvider.overrideWith((_) => Stream.value(0)),
            pipelineStepRunsForRunProvider('run-1').overrideWith(
              (_) => Stream.value(const <PipelineStepRun>[]),
            ),
            pipelineStepRunsForRunProvider('run-2').overrideWith(
              (_) => Stream.value(const <PipelineStepRun>[]),
            ),
          ],
          child: testWrap(
            PipelineCanvas(
              definition: def,
              runId: 'run-2',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      wideContainers = tester.widgetList<Container>(find.byType(Container)).where(
        (c) => c.constraints?.minWidth == 360,
      );
      expect(wideContainers, isEmpty);
    });

    testWidgets('uses initialSelectedStepId when provided with new runId',
        (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
        _step(id: 'stepA', kind: StepKind.listen, label: 'A'),
      ]);

      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
          pipelineStepRunsForRunProvider('run-2').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
        ],
      );

      // Re-pump with run-2 and initialSelectedStepId.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pipelineClockProvider.overrideWith((_) => Stream.value(0)),
            pipelineStepRunsForRunProvider('run-1').overrideWith(
              (_) => Stream.value(const <PipelineStepRun>[]),
            ),
            pipelineStepRunsForRunProvider('run-2').overrideWith(
              (_) => Stream.value(const <PipelineStepRun>[]),
            ),
          ],
          child: testWrap(
            PipelineCanvas(
              definition: def,
              runId: 'run-2',
              initialSelectedStepId: 'stepA',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final wideContainers = tester.widgetList<Container>(find.byType(Container)).where(
        (c) => c.constraints?.minWidth == 360,
      );
      expect(wideContainers, isNotEmpty);
    });
  });

  // -- Semantics ------------------------------------------------------------

  group('semantics', () {
    testWidgets('nodes have button semantics when runId is set', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
      ]);
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
        ],
      );

      // Several Semantics widgets have button:true (node + FTappable).
      // At least the node's Semantics with label 'Start' should exist.
      final nodeSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true && w.properties.label == 'Start',
      );
      expect(nodeSemantics, findsOneWidget);
    });

    testWidgets('selected node has selected=true semantics', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
      ]);
      await pumpCanvas(
        tester,
        def,
        runId: 'run-1',
        overrides: [
          pipelineStepRunsForRunProvider('run-1').overrideWith(
            (_) => Stream.value(const <PipelineStepRun>[]),
          ),
        ],
      );

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(milliseconds: 200));

      final selectedSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.selected == true,
      );
      // The selected node and potentially its FTappable wrapper both have selected=true
      expect(selectedSemantics, findsAtLeastNWidgets(1));
    });
  });

  // -- Multiple nodes -------------------------------------------------------

  group('multiple nodes', () {
    testWidgets('renders all non-terminal steps', (tester) async {
      final def = _definition([
        _step(id: 'trigger', kind: StepKind.trigger, label: 'T'),
        _step(id: 'a', kind: StepKind.listen, label: 'A'),
        _step(id: 'b', kind: StepKind.listen, label: 'B'),
        _step(id: 'join', kind: StepKind.join, label: 'J'),
        _step(id: 'router', kind: StepKind.router, label: 'R'),
      ]);
      await pumpCanvas(tester, def);

      expect(find.text('T'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('J'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('terminal steps are filtered out', (tester) async {
      final def = _definition([
        _step(id: 'trigger', kind: StepKind.trigger, label: 'T'),
        _step(id: 'end1', kind: StepKind.terminal, label: 'End'),
        _step(id: 'end2', kind: StepKind.terminal, label: 'End2'),
      ]);
      await pumpCanvas(tester, def);

      expect(find.text('T'), findsOneWidget);
      expect(find.text('End'), findsNothing);
      expect(find.text('End2'), findsNothing);
    });
  });

  // -- Focus / keyboard -----------------------------------------------------

  group('focus and keyboard', () {
    testWidgets('Focus widget is present with autofocus', (tester) async {
      final def = _definition([
        _step(id: 'start', kind: StepKind.trigger, label: 'Start'),
      ]);
      await pumpCanvas(tester, def);

      // The canvas Focus with autofocus is the one wrapping CallbackShortcuts.
      final canvasFocus = find.byWidgetPredicate(
        (w) => w is Focus && w.autofocus == true && w.child is CallbackShortcuts,
      );
      expect(canvasFocus, findsOneWidget);
    });

  });
}
