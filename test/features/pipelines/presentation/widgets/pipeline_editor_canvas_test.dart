import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_library_sidebar.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas_background.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_connect_port.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_drop_picker.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_geometry.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_editor_node_tile.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_quick_insert.dart';
import 'package:control_center/features/pipelines/presentation/widgets/template_node_title.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/canvas/canvas_zoom_controls.dart';
import 'package:control_center/shared/widgets/graph_node_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

PipelineStepDefinition _step({
  required String id,
  required StepKind kind,
  String? label,
  String? bodyKey,
  List<StepTrigger> triggers = const [],
  double? x,
  double? y,
}) {
  return PipelineStepDefinition(
    id: id,
    kind: kind,
    bodyKey: bodyKey ?? 'body_$id',
    triggers: triggers,
    config: PipelineNodeConfig(label: label),
    x: x,
    y: y,
  );
}

PipelineDefinition _definition(List<PipelineStepDefinition> steps) {
  return PipelineDefinition(
    templateId: 'tmpl-editor',
    workspaceId: 'ws-test',
    name: 'Editor Pipeline',
    steps: steps,
  );
}

PipelineTrigger _trigger({
  required String id,
  required String eventType,
  bool enabled = true,
}) {
  return PipelineTrigger(
    id: id,
    eventType: eventType,
    templateId: 'tmpl-editor',
    workspaceId: 'ws-test',
    enabled: enabled,
  );
}

/// Trigger → work (unconditional) + branch (routed) → later, plus a terminal
/// the canvas must not paint. Coordinates sit on the 240×120 seed pitch.
PipelineDefinition _graph() {
  return _definition([
    _step(
      id: 'start',
      kind: StepKind.trigger,
      bodyKey: BuiltInBodyKeys.trigger,
      label: 'Start',
      x: 0,
      y: 0,
    ),
    _step(
      id: 'work',
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      label: 'Review',
      triggers: const [
        StepTrigger(sourceStepIds: ['start']),
      ],
      x: 240,
      y: 0,
    ),
    _step(
      id: 'branch',
      kind: StepKind.router,
      bodyKey: BuiltInBodyKeys.condition,
      label: 'If approved',
      triggers: const [
        StepTrigger(sourceStepIds: ['start'], routeKey: 'approved'),
      ],
      x: 240,
      y: 120,
    ),
    _step(
      id: 'later',
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.bashScript,
      label: 'Later',
      triggers: const [
        StepTrigger(sourceStepIds: ['work']),
      ],
      x: 480,
      y: 0,
    ),
    _step(id: 'end', kind: StepKind.terminal, x: 720, y: 0),
  ]);
}

/// Two real start nodes at independent y, Manual wired to work.
PipelineDefinition _twoStartGraph() {
  return _definition([
    _step(
      id: 't-manual',
      kind: StepKind.trigger,
      bodyKey: BuiltInBodyKeys.trigger,
      x: 0,
      y: 0,
    ),
    _step(
      id: 't-sched',
      kind: StepKind.trigger,
      bodyKey: BuiltInBodyKeys.trigger,
      x: 0,
      y: 200,
    ),
    _step(
      id: 'work',
      kind: StepKind.listen,
      bodyKey: BuiltInBodyKeys.promptAgent,
      label: 'Review',
      triggers: const [
        StepTrigger(sourceStepIds: ['t-manual']),
      ],
      x: 240,
      y: 0,
    ),
    _step(id: 'end', kind: StepKind.terminal, x: 480, y: 0),
  ]);
}

Finder _iconButton(String tooltip) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == tooltip);

void main() {
  late AppLocalizations l10n;
  final library = defaultNodeTypeLibrary();

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pumpEditor(
    WidgetTester tester, {
    required PipelineDefinition definition,
    String? selectedStepId,
    String? selectedTriggerId,
    List<PipelineTrigger> triggers = const [],
    void Function(String stepId)? onSelect,
    void Function(String triggerId)? onSelectTrigger,
    void Function(String eventType, [Offset? at])? onAddTrigger,
    void Function(String triggerId)? onDeleteTrigger,
    void Function(NodeType type, Offset offset)? onDropNodeType,
    void Function(String stepId, Offset position)? onMoveNode,
    void Function(String from, String to)? onConnect,
    void Function(String from, String to)? onDisconnect,
    void Function(NodeType type, String fromStepId, Offset offset)?
    onInsertLinked,
    void Function(String stepId)? onDeleteStep,
    VoidCallback? onTidy,
    Widget Function(Widget canvas)? wrap,
  }) async {
    final canvas = PipelineEditorCanvas(
      definition: definition,
      selectedStepId: selectedStepId,
      selectedTriggerId: selectedTriggerId,
      library: library,
      triggers: triggers,
      onSelect: onSelect ?? (_) {},
      onSelectTrigger: onSelectTrigger ?? (_) {},
      onAddTrigger: onAddTrigger ?? (_, [_]) {},
      onDeleteTrigger: onDeleteTrigger ?? (_) {},
      onDropNodeType: onDropNodeType ?? (_, _) {},
      onMoveNode: onMoveNode ?? (_, _) {},
      onConnect: onConnect ?? (_, _) {},
      onDisconnect: onDisconnect ?? (_, _) {},
      onInsertLinked: onInsertLinked ?? (_, _, _) {},
      onDeleteStep: onDeleteStep ?? (_) {},
      onTidy: onTidy ?? () {},
    );
    await tester.pumpWidget(testWrap(wrap?.call(canvas) ?? canvas));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('nodes', () {
    testWidgets('renders body tiles only — entry step is not a tile', (
      tester,
    ) async {
      await pumpEditor(tester, definition: _graph());

      expect(find.byType(GraphNodeCard), findsNWidgets(3));
      expect(find.text('Start'), findsNothing);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('If approved'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('end'), findsNothing);
      expect(find.byType(PipelineEditorGhostTriggerTile), findsOneWidget);
    });

    testWidgets('tap selects a node', (tester) async {
      String? selected;
      await pumpEditor(
        tester,
        definition: _graph(),
        onSelect: (id) => selected = id,
      );

      await tester.tapAt(tester.getCenter(find.text('Review')));
      await tester.pump();
      expect(selected, 'work');
    });

    testWidgets('templated labels draw the variable as a badge', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        definition: _definition([
          _step(
            id: 'start',
            kind: StepKind.trigger,
            bodyKey: BuiltInBodyKeys.trigger,
            label: 'Start',
            x: 0,
            y: 0,
          ),
          _step(
            id: 'review',
            kind: StepKind.listen,
            bodyKey: BuiltInBodyKeys.promptAgent,
            label: 'Cross-review #{{pr_number}}',
            triggers: const [
              StepTrigger(sourceStepIds: ['start']),
            ],
            x: 240,
            y: 0,
          ),
          _step(id: 'end', kind: StepKind.terminal, x: 480, y: 0),
        ]),
      );

      expect(find.byType(TemplateVarBadge), findsOneWidget);
      expect(find.text('#pr_number'), findsOneWidget);
      expect(find.text('{{pr_number}}'), findsNothing);
      expect(find.text('Cross-review #{{pr_number}}'), findsNothing);
    });
  });

  group('trigger proxies', () {
    testWidgets('renders one stacked tile per PipelineTrigger', (tester) async {
      await pumpEditor(
        tester,
        definition: _graph(),
        triggers: [
          _trigger(id: 't-sched', eventType: PipelineTrigger.scheduleEventType),
          _trigger(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
      );

      expect(find.byType(PipelineEditorTriggerTile), findsNWidgets(2));
      expect(find.byType(PipelineEditorGhostTriggerTile), findsNothing);
      expect(
        find.byKey(const ValueKey('pipeline-trigger-t-manual')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('pipeline-trigger-t-sched')),
        findsOneWidget,
      );
      expect(find.text('Start'), findsNothing);
      expect(find.byType(GraphNodeCard), findsNWidgets(5));

      final manual = tester.getTopLeft(
        find.byKey(const ValueKey('pipeline-trigger-t-manual')),
      );
      final schedule = tester.getTopLeft(
        find.byKey(const ValueKey('pipeline-trigger-t-sched')),
      );
      expect(schedule.dy - manual.dy, closeTo(kPipelineEditorTriggerPitch, 1));
    });

    testWidgets('trigger tiles sit on their own step coordinates', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        definition: _twoStartGraph(),
        triggers: [
          _trigger(id: 't-sched', eventType: PipelineTrigger.scheduleEventType),
          _trigger(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
      );

      final manual = tester.getTopLeft(
        find.byKey(const ValueKey('pipeline-trigger-t-manual')),
      );
      final schedule = tester.getTopLeft(
        find.byKey(const ValueKey('pipeline-trigger-t-sched')),
      );
      expect(schedule.dy - manual.dy, closeTo(200, 1));
    });

    testWidgets('dragging a trigger port connects only that start', (
      tester,
    ) async {
      String? from;
      String? to;
      await pumpEditor(
        tester,
        definition: _twoStartGraph(),
        triggers: [
          _trigger(id: 't-sched', eventType: PipelineTrigger.scheduleEventType),
          _trigger(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
        onConnect: (a, b) {
          from = a;
          to = b;
        },
      );

      final port = find.byKey(PipelineEditorConnectPort.keyFor('t-sched'));
      final target = tester.getCenter(find.text('Review'));
      final start = tester.getCenter(port);
      await tester.drag(port, target - start);
      await tester.pumpAndSettle();

      expect(from, 't-sched');
      expect(to, 'work');
    });

    testWidgets('disabled trigger shows the Disabled chip', (tester) async {
      await pumpEditor(
        tester,
        definition: _graph(),
        triggers: [
          _trigger(
            id: 't-off',
            eventType: PipelineTrigger.webhookEventType,
            enabled: false,
          ),
        ],
      );

      expect(
        find.byKey(const ValueKey('pipeline-trigger-t-off')),
        findsOneWidget,
      );
      expect(find.text(l10n.disabled), findsOneWidget);
    });

    testWidgets('clicking a trigger fires onSelectTrigger', (tester) async {
      String? selected;
      await pumpEditor(
        tester,
        definition: _graph(),
        triggers: [
          _trigger(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
        onSelectTrigger: (id) => selected = id,
      );

      await tester.tap(find.byKey(const ValueKey('pipeline-trigger-t-manual')));
      await tester.pump();
      expect(selected, 't-manual');
    });

    testWidgets('Delete on a selected trigger fires onDeleteTrigger', (
      tester,
    ) async {
      final deleted = <String>[];
      await pumpEditor(
        tester,
        definition: _graph(),
        selectedTriggerId: 't-manual',
        triggers: [
          _trigger(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
        onDeleteTrigger: deleted.add,
      );
      await tester.tap(find.byType(PipelineEditorCanvas));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(deleted, ['t-manual']);
    });

    testWidgets('ghost tile picker fires onAddTrigger', (tester) async {
      String? added;
      await pumpEditor(
        tester,
        definition: _graph(),
        onAddTrigger: (type, [_]) => added = type,
      );

      expect(find.text(l10n.pipelineAddTrigger), findsOneWidget);
      await tester.tap(find.text(l10n.pipelineAddTrigger));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(l10n.triggerEventManual));
      await tester.pump();
      expect(added, PipelineTrigger.manualEventType);
    });

    testWidgets('sidebar drag of a trigger entry fires onAddTrigger', (
      tester,
    ) async {
      String? added;
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpEditor(
        tester,
        definition: _graph(),
        onAddTrigger: (type, [_]) => added = type,
        wrap: (canvas) => SizedBox(
          width: 1400,
          height: 800,
          child: Row(
            children: [
              SizedBox(width: 280, child: NodeLibrarySidebar(library: library)),
              Expanded(child: canvas),
            ],
          ),
        ),
      );

      expect(
        find.text(l10n.nodeCategoryTriggers.toUpperCase()),
        findsOneWidget,
      );
      final from = tester.getCenter(find.text(l10n.triggerEventWebhook).first);
      final to = tester.getCenter(find.byType(PipelineEditorCanvas));
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(to);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(added, PipelineTrigger.webhookEventType);
    });
  });

  group('eyebrows', () {
    testWidgets(
      'first trigger shows When this happens; successors show Do this',
      (tester) async {
        await pumpEditor(
          tester,
          definition: _graph(),
          triggers: [
            _trigger(
              id: 't-manual',
              eventType: PipelineTrigger.manualEventType,
            ),
          ],
        );

        expect(
          find.text(l10n.pipelineWhenThisHappens.toUpperCase()),
          findsOneWidget,
        );
        // Direct listeners of the trigger: Review and If approved. Later is a
        // grandchild and must not wear the same eyebrow.
        expect(find.text(l10n.pipelineDoThis.toUpperCase()), findsNWidgets(2));
      },
    );
  });

  group('keyboard', () {
    testWidgets('e then Enter connects the selected pair', (tester) async {
      String? from;
      String? to;
      // Same State across the selection change so `_connectFrom` survives.
      final canvasKey = GlobalKey();

      Future<void> pumpSelected(String selected) async {
        await tester.pumpWidget(
          testWrap(
            PipelineEditorCanvas(
              key: canvasKey,
              definition: _graph(),
              selectedStepId: selected,
              selectedTriggerId: null,
              library: library,
              triggers: const [],
              onSelect: (_) {},
              onSelectTrigger: (_) {},
              onAddTrigger: (_, [_]) {},
              onDeleteTrigger: (_) {},
              onDropNodeType: (_, _) {},
              onMoveNode: (_, _) {},
              onConnect: (a, b) {
                from = a;
                to = b;
              },
              onDisconnect: (_, _) {},
              onInsertLinked: (_, _, _) {},
              onDeleteStep: (_) {},
              onTidy: () {},
            ),
          ),
        );
        await tester.pump();
      }

      await pumpSelected('start');
      await tester.tap(find.byType(PipelineEditorCanvas));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pump();

      // Do not tap the successor — a tap would complete the connect itself.
      await pumpSelected('work');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(from, 'start');
      expect(to, 'work');
    });

    testWidgets('Delete removes a non-trigger and leaves the trigger', (
      tester,
    ) async {
      final deleted = <String>[];

      await pumpEditor(
        tester,
        definition: _graph(),
        selectedStepId: 'work',
        onDeleteStep: deleted.add,
      );
      await tester.tap(find.byType(PipelineEditorCanvas));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(deleted, ['work']);

      deleted.clear();
      await pumpEditor(
        tester,
        definition: _graph(),
        selectedStepId: 'start',
        onDeleteStep: deleted.add,
      );
      await tester.tap(find.byType(PipelineEditorCanvas));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(deleted, isEmpty);
    });
  });

  group('chrome', () {
    testWidgets('shows zoom controls and fires tidy', (tester) async {
      var tidied = false;
      await pumpEditor(
        tester,
        definition: _graph(),
        onTidy: () => tidied = true,
      );

      expect(find.byType(CanvasZoomControls), findsOneWidget);
      expect(_iconButton(l10n.zoomIn), findsOneWidget);
      expect(_iconButton(l10n.zoomOut), findsOneWidget);
      expect(_iconButton(l10n.fitToView), findsOneWidget);
      expect(_iconButton(l10n.pipelineTidyUp), findsOneWidget);

      await tester.tap(_iconButton(l10n.pipelineTidyUp));
      await tester.pump();
      expect(tidied, isTrue);
    });
  });

  group('connect drop', () {
    testWidgets('no per-node plus — palette and handle-drop create nodes', (
      tester,
    ) async {
      await pumpEditor(tester, definition: _graph(), selectedStepId: 'work');
      expect(find.byType(PipelineQuickInsert), findsNothing);
    });

    testWidgets('handle drag sticks on pointer down, not after slop', (
      tester,
    ) async {
      await pumpEditor(tester, definition: _graph());

      final port = find.byKey(PipelineEditorConnectPort.keyFor('work'));
      final gesture = await tester.startGesture(tester.getCenter(port));
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PipelineGhostEdgePainter,
        ),
        findsOneWidget,
      );

      // Well under [kTouchSlop] (~18px). The first drag used to do nothing
      // until the pointer had moved that far, so a short pull felt dead.
      await gesture.moveBy(const Offset(8, 4));
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PipelineGhostEdgePainter,
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('mouse pointer-down on the handle starts the wire', (
      tester,
    ) async {
      await pumpEditor(tester, definition: _graph());

      final port = find.byKey(PipelineEditorConnectPort.keyFor('work'));
      final gesture = await tester.startGesture(
        tester.getCenter(port),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PipelineGhostEdgePainter,
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('connect-drag up does not jump the graph', (tester) async {
      await pumpEditor(tester, definition: _graph());

      final tile = find.text('Review');
      final before = tester.getTopLeft(tile);
      final port = find.byKey(PipelineEditorConnectPort.keyFor('work'));
      final gesture = await tester.startGesture(tester.getCenter(port));
      await tester.pump();
      await gesture.moveBy(const Offset(12, -180));
      await tester.pump();

      expect(tester.getTopLeft(tile), before);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is PipelineGhostEdgePainter,
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump();
    });

    testWidgets('dragging a handle onto another node fires onConnect', (
      tester,
    ) async {
      String? from;
      String? to;
      await pumpEditor(
        tester,
        definition: _graph(),
        onConnect: (a, b) {
          from = a;
          to = b;
        },
      );

      final port = find.byKey(PipelineEditorConnectPort.keyFor('work'));
      final target = tester.getCenter(find.text('If approved'));
      final start = tester.getCenter(port);
      await tester.drag(port, target - start);
      await tester.pumpAndSettle();

      expect(from, 'work');
      expect(to, 'branch');
    });

    testWidgets('dropping a handle on empty canvas opens a picker that links', (
      tester,
    ) async {
      NodeType? picked;
      String? from;
      Offset? at;

      await pumpEditor(
        tester,
        definition: _graph(),
        onInsertLinked: (type, stepId, offset) {
          picked = type;
          from = stepId;
          at = offset;
        },
      );

      final port = find.byKey(PipelineEditorConnectPort.keyFor('work'));
      await tester.drag(port, const Offset(80, 220));
      await tester.pumpAndSettle();

      expect(find.byKey(PipelineEditorDropPicker.panelKey), findsOneWidget);
      expect(find.text(l10n.nodeLibrarySearchHint), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(PipelineNodeTypePicker),
          matching: find.text('Condition / switch (router)'),
        ),
      );
      await tester.pump();

      expect(picked?.id, 'pipeline.condition');
      expect(from, 'work');
      expect(at, isNotNull);
    });
  });

  group('edges', () {
    testWidgets('a routed edge renders its route-key label', (tester) async {
      await pumpEditor(
        tester,
        definition: _graph(),
        triggers: [
          _trigger(id: 't-manual', eventType: PipelineTrigger.manualEventType),
        ],
      );
      expect(find.text('approved'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('opens with the graph centred, not flushed to the top', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpEditor(tester, definition: _graph());

      final viewport = tester.getRect(find.byType(InteractiveViewer));
      final tile = tester.getRect(find.text('Review'));
      expect(
        tile.top,
        greaterThan(viewport.top + 80),
        reason: 'identity transform pins the graph under the top edge',
      );
      expect(
        tile.center.dy,
        closeTo(viewport.center.dy, viewport.height * 0.25),
      );
    });
  });

  group('pan', () {
    testWidgets(
      'empty-canvas drag pans freely when the graph is smaller than the viewport',
      (tester) async {
        // A finite boundaryMargin refuses the whole axis once the child plus
        // slack is smaller than the viewport — the editor's usual case, a
        // short left-to-right pipeline in a wide pane. This surface is wide
        // enough that a single tile cannot fill it even with the old 240px
        // leash, so a locked X axis would fail the dx assertion below.
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpEditor(
          tester,
          definition: _definition([
            _step(
              id: 'start',
              kind: StepKind.trigger,
              bodyKey: BuiltInBodyKeys.trigger,
              label: 'Start',
              x: 0,
              y: 0,
            ),
          ]),
        );

        final viewer = tester.widget<InteractiveViewer>(
          find.byType(InteractiveViewer),
        );
        final controller = viewer.transformationController!;
        final before = controller.value.getTranslation();
        // Start on empty chrome, away from the ghost tile and the zoom/hint
        // chips, so the viewer — not a child recognizer — owns the drag.
        final bounds = tester.getRect(find.byType(InteractiveViewer));
        final start = Offset(bounds.right - 120, bounds.top + 80);

        await tester.dragFrom(start, const Offset(140, 90));
        await tester.pumpAndSettle();

        final after = controller.value.getTranslation();
        // Touch slop eats the first ~20px of a test drag; what matters is that
        // BOTH axes moved. A finite boundary would leave dx at 0.
        expect(after.x, greaterThan(before.x + 80));
        expect(after.y, greaterThan(before.y + 40));
      },
    );
  });
}
