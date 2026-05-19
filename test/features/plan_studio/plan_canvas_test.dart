import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_canvas.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/plan_node_visuals.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

/// The longest realistic plan title: a full task sentence, which is what the
/// planner actually emits ("Add partial staging (hunk/line) to Source Control
/// tab").
const _longTitle = 'Add commit message templates to Source Control tab';

PlanNode _n(
  String key, {
  String? title,
  List<String> deps = const [],
  String? roleKey,
  PlanNodeType type = PlanNodeType.work,
}) => PlanNode(
  key: key,
  title: title ?? key,
  type: type,
  dependsOn: deps,
  roleKey: roleKey,
);

Widget _wrap(
  PlanGraph graph, {
  String? selected,
  PlanNodeRunState state = PlanNodeRunState.none,
  PlanNodeEstimate? estimate,
  Set<String> diverged = const {},
  Set<String> readOnly = const {},
}) => MaterialApp(
  home: Scaffold(
    body: PlanCanvas(
      graph: graph,
      selectedKey: selected,
      onSelect: (_) {},
      runStateOf: (_) => state,
      estimateOf: (_) => estimate,
      divergedKeys: diverged,
      readOnlyKeys: readOnly,
      editable: true,
    ),
  ),
);

void main() {
  group('PlanCanvas node tile', () {
    testWidgets(
      'renders a long title over two lines without truncating to one',
      (tester) async {
        await tester.pumpWidget(
          _wrap(PlanGraph(nodes: [_n('a', title: _longTitle)])),
        );

        final title = tester.widget<Text>(find.text(_longTitle));
        expect(title.maxLines, 2);
        // The layout must not have clipped it into an ellipsis-only single line.
        final rendered = tester.renderObject<RenderParagraph>(
          find.text(_longTitle),
        );
        expect(
          rendered.size.height,
          greaterThan(20),
          reason: 'a single 13px line would be under 20px tall',
        );
      },
    );

    testWidgets('fits its fixed height with maximal content', (tester) async {
      // Long title + role + a running state chip + an estimate line: every
      // optional row present at once, which is the tile's tightest case.
      await tester.pumpWidget(
        _wrap(
          PlanGraph(
            nodes: [_n('a', title: _longTitle, roleKey: 'reviewer')],
          ),
          state: PlanNodeRunState.running,
          estimate: const PlanNodeEstimate(
            costCentsLow: 120,
            costCentsHigh: 480,
            sampleSize: 7,
            blastRadiusFiles: 14,
          ),
          diverged: const {'a'},
          readOnly: const {'a'},
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('reviewer'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
      // Kind is always labelled, not icon-only.
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('an edgeless plan lays out as a grid, not a single column', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PlanGraph(
            nodes: [
              for (var i = 0; i < 18; i++) _n('n$i', title: 'Task number $i'),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      // Tiles are Positioned inside the canvas stack; distinct lefts prove the
      // rank wrapped rather than stacking 18 deep.
      final lefts = tester
          .widgetList<Positioned>(find.byType(Positioned))
          .map((p) => p.left)
          .whereType<double>()
          .toSet();
      expect(lefts.length, greaterThan(1));
    });

    testWidgets('every state pairs its colour with a shape', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PlanGraph(nodes: [_n('a', title: 'Short')]),
          state: PlanNodeRunState.failed,
        ),
      );
      // Failed carries an icon AND the word, never the danger tint alone.
      expect(find.text('Failed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('PlanCanvas wheel', () {
    /// A chain long enough to overflow the viewport on both axes below, so there
    /// is somewhere to pan to (a graph that already fits is pinned, by design —
    /// the same leash the viewer applies to a drag).
    PlanGraph deepGraph() => PlanGraph(
      nodes: [
        for (var i = 0; i < 14; i++)
          _n('n$i', title: 'Task $i', deps: i == 0 ? const [] : ['n${i - 1}']),
      ],
    );

    /// A deliberately small viewport: the canvas must be larger than what is on
    /// screen for a pan to have anywhere to go.
    Widget wrapSmall(PlanGraph graph) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            height: 150,
            child: PlanCanvas(
              graph: graph,
              selectedKey: null,
              onSelect: (_) {},
              runStateOf: (_) => PlanNodeRunState.none,
            ),
          ),
        ),
      ),
    );

    /// Scrolls the wheel over the canvas, as a MOUSE (a trackpad sends pan/zoom
    /// events instead, which the viewer already handles as a pan).
    Future<void> wheel(WidgetTester tester, Offset delta) async {
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      final center = tester.getCenter(find.byType(PlanCanvas));
      await tester.sendEventToBinding(pointer.hover(center));
      await tester.sendEventToBinding(pointer.scroll(delta));
      await tester.pump();
    }

    testWidgets('a plain wheel pans vertically instead of zooming', (
      tester,
    ) async {
      await tester.pumpWidget(wrapSmall(deepGraph()));
      final before = tester.getCenter(find.text('Task 0'));
      final spanBefore = tester.getCenter(find.text('Task 1')) - before;

      await wheel(tester, const Offset(0, 120));

      final after = tester.getCenter(find.text('Task 0'));
      final spanAfter = tester.getCenter(find.text('Task 1')) - after;

      // Content moved up with the wheel …
      expect(after.dy, lessThan(before.dy));
      expect(after.dx, closeTo(before.dx, 0.01));
      // … and the scale is untouched: the gap between two nodes is unchanged.
      expect(spanAfter.dx, closeTo(spanBefore.dx, 0.01));
      expect(spanAfter.dy, closeTo(spanBefore.dy, 0.01));
    });

    testWidgets('shift + wheel pans horizontally', (tester) async {
      await tester.pumpWidget(wrapSmall(deepGraph()));
      final before = tester.getCenter(find.text('Task 0'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await wheel(tester, const Offset(0, 120));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      final after = tester.getCenter(find.text('Task 0'));
      expect(after.dx, lessThan(before.dx));
      expect(after.dy, closeTo(before.dy, 0.01));
    });

    testWidgets('⌘ + wheel zooms', (tester) async {
      await tester.pumpWidget(wrapSmall(deepGraph()));
      final spanBefore =
          tester.getCenter(find.text('Task 1')) -
          tester.getCenter(find.text('Task 0'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await wheel(tester, const Offset(0, -120));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

      final spanAfter =
          tester.getCenter(find.text('Task 1')) -
          tester.getCenter(find.text('Task 0'));

      // Zoomed in: the same two nodes are further apart on screen.
      expect(spanAfter.distance, greaterThan(spanBefore.distance));
    });
  });
}
