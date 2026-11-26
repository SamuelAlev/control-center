import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_face.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_tab_landing.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:control_center/shared/editor/editor_workspace_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

EditorTab _tab(String label) => EditorTab(kind: 'chat', label: label);

Finder _leafGroup(String leafId) => find.byWidgetPredicate(
  (w) => w is EditorTabGroup && w.leafId == leafId,
);

Finder _leafViewport(String leafId) => find.ancestor(
  of: _leafGroup(leafId),
  matching: find.byType(EditorPaneViewport),
);

Finder _stripFace(String label) => find
    .descendant(
      of: find.byType(EditorWorkspace),
      matching: find.byWidgetPredicate(
        (w) => w is EditorTabFace && w.label == label,
      ),
    )
    .first;

Widget _workspaceHarness({
  required EditorLayoutController layout,
  EditorBodyBuilder? buildBody,
  VoidCallback? onResized,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
  Size size = const Size(800, 600),
}) {
  return testWrap(
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: Directionality(
          textDirection: textDirection,
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: EditorWorkspace(
                layout: layout,
                chrome: const EditorChrome(),
                onResized: onResized,
                buildBody:
                    buildBody ??
                    (tab, {required isVisible}) => ColoredBox(
                      key: ValueKey(tab),
                      color: const Color(0xFFFFFFFF),
                      child: Center(child: Text('body:${tab.label}')),
                    ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('split open animations', () {
    for (final edge in [
      DropEdge.right,
      DropEdge.left,
      DropEdge.bottom,
      DropEdge.top,
    ]) {
      testWidgets('animates ${edge.name} split smoothly and flush', (
        tester,
      ) async {
        final a = _tab('A');
        final b = _tab('B');
        final group = EditorTabGroupController()
          ..insert(0, a)
          ..insert(1, b);
        final layout = EditorLayoutController.single(controller: group);
        addTearDown(layout.dispose);

        await tester.pumpWidget(_workspaceHarness(layout: layout));
        expect(tester.getRect(_leafGroup('leaf-0')), const Rect.fromLTWH(0, 0, 800, 600));

        layout.splitWithTab(
          'leaf-0',
          edge,
          TabDragData(sourceLeafId: 'leaf-0', tabIndex: 1, tab: b),
        );

        // Very first frame: entering pane starts narrow without overflowing.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        expect(tester.takeException(), isNull);

        // Mid-animation: both panes are moving smoothly and stay flush.
        await tester.pump(const Duration(milliseconds: 84));
        final existing = tester.getRect(_leafViewport('leaf-0'));
        final entering = tester.getRect(_leafViewport(layout.activeLeafId));

        switch (edge) {
          case DropEdge.right:
            expect(existing.left, 0);
            expect(existing.width, greaterThan(400));
            expect(existing.width, lessThan(800));
            expect(entering.right, closeTo(800, 0.5));
            expect(entering.width, greaterThan(0));
            expect(entering.width, lessThan(400));
            expect(existing.right, closeTo(entering.left, 0.5));
            expect(
              tester.getRect(_leafGroup(layout.activeLeafId)).width,
              closeTo(400, 0.5),
            );
          case DropEdge.left:
            expect(entering.left, 0);
            expect(entering.width, greaterThan(0));
            expect(entering.width, lessThan(400));
            expect(existing.right, closeTo(800, 0.5));
            expect(existing.width, greaterThan(400));
            expect(existing.width, lessThan(800));
            expect(entering.right, closeTo(existing.left, 0.5));
            expect(
              tester.getRect(_leafGroup(layout.activeLeafId)).width,
              closeTo(400, 0.5),
            );
          case DropEdge.bottom:
            expect(existing.top, 0);
            expect(existing.height, greaterThan(300));
            expect(existing.height, lessThan(600));
            expect(entering.bottom, closeTo(600, 0.5));
            expect(entering.height, greaterThan(0));
            expect(entering.height, lessThan(300));
            expect(existing.bottom, closeTo(entering.top, 0.5));
            expect(
              tester.getRect(_leafGroup(layout.activeLeafId)).height,
              closeTo(300, 0.5),
            );
          case DropEdge.top:
            expect(entering.top, 0);
            expect(entering.height, greaterThan(0));
            expect(entering.height, lessThan(300));
            expect(existing.bottom, closeTo(600, 0.5));
            expect(existing.height, greaterThan(300));
            expect(existing.height, lessThan(600));
            expect(entering.bottom, closeTo(existing.top, 0.5));
            expect(
              tester.getRect(_leafGroup(layout.activeLeafId)).height,
              closeTo(300, 0.5),
            );
          case DropEdge.center:
            break;
        }

        await tester.pumpAndSettle();
        final settledExisting = tester.getRect(_leafGroup('leaf-0'));
        final settledEntering = tester.getRect(_leafGroup(layout.activeLeafId));
        if (edge == DropEdge.left || edge == DropEdge.right) {
          expect(settledExisting.width, closeTo(400, 0.5));
          expect(settledEntering.width, closeTo(400, 0.5));
        } else {
          expect(settledExisting.height, closeTo(300, 0.5));
          expect(settledEntering.height, closeTo(300, 0.5));
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('entering pane keeps target inner layout width while clipping', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final group = EditorTabGroupController()..insert(0, a);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      double? observedWidth;
      await tester.pumpWidget(
        _workspaceHarness(
          layout: layout,
          buildBody: (tab, {required isVisible}) => LayoutBuilder(
            key: ValueKey(tab),
            builder: (context, constraints) {
              if (identical(tab, b)) {
                observedWidth = constraints.maxWidth;
              }
              return const SizedBox.expand();
            },
          ),
        ),
      );

      layout.openInSplit('leaf-0', b, DropEdge.right);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));

      // Outer viewport is still narrow mid-entrance, while inner layout has full 400px.
      expect(
        tester.getRect(_leafViewport(layout.activeLeafId)).width,
        lessThan(250),
      );
      expect(observedWidth, closeTo(400, 0.5));

      await tester.pumpAndSettle();
      expect(observedWidth, closeTo(400, 0.5));
    });

    testWidgets('pointer DnD split animates both pane split and tab landing', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final group = EditorTabGroupController()
        ..insert(0, a)
        ..insert(1, b);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      await tester.pumpWidget(_workspaceHarness(layout: layout));

      final gesture = await tester.startGesture(
        tester.getCenter(_stripFace('B')),
      );
      await tester.pump();
      await gesture.moveTo(const Offset(780, 320));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final left = tester.getRect(_leafViewport('leaf-0'));
      final right = tester.getRect(_leafViewport(layout.activeLeafId));
      expect(left.width, greaterThan(400));
      expect(left.width, lessThan(800));
      expect(right.width, greaterThan(0));
      expect(right.width, lessThan(400));
      expect(left.right, closeTo(right.left, 0.5));
      // The tab landing flight is still airborne homing onto the sliding slot.
      expect(
        find.descendant(
          of: find.byType(EditorTabLandingSlot),
          matching: find.byWidgetPredicate(
            (w) => w is Opacity && w.opacity == 0 && w.alwaysIncludeSemantics,
          ),
        ),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
      expect(tester.getRect(_leafViewport('leaf-0')).width, closeTo(400, 0.5));
      expect(
        tester.getRect(_leafViewport(layout.activeLeafId)).width,
        closeTo(400, 0.5),
      );
    });
  });

  group('split collapse animations', () {
    testWidgets('closing a side pane animates surviving pane to full width', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final group = EditorTabGroupController()
        ..insert(0, a)
        ..insert(1, b);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      await tester.pumpWidget(_workspaceHarness(layout: layout));
      layout.splitWithTab(
        'leaf-0',
        DropEdge.right,
        TabDragData(sourceLeafId: 'leaf-0', tabIndex: 1, tab: b),
      );
      await tester.pumpAndSettle();
      final rightLeafId = layout.activeLeafId;

      layout.closeLeaf(rightLeafId);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final surviving = tester.getRect(_leafGroup('leaf-0'));
      expect(surviving.left, 0);
      expect(surviving.width, greaterThan(400));
      expect(surviving.width, lessThan(800));

      final exiting = find.byKey(ValueKey('exiting:$rightLeafId'));
      expect(exiting, findsOneWidget);
      final exitingRect = tester.getRect(exiting);
      expect(exitingRect.left, closeTo(surviving.right, 0.5));
      expect(exitingRect.right, closeTo(800, 0.5));

      await tester.pumpAndSettle();
      expect(tester.getRect(_leafGroup('leaf-0')), const Rect.fromLTWH(0, 0, 800, 600));
      expect(exiting, findsNothing);
    });

    testWidgets('DnD moving last tab out of a pane collapses it smoothly', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final group = EditorTabGroupController()
        ..insert(0, a)
        ..insert(1, b);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      await tester.pumpWidget(_workspaceHarness(layout: layout));
      layout.splitWithTab(
        'leaf-0',
        DropEdge.right,
        TabDragData(sourceLeafId: 'leaf-0', tabIndex: 1, tab: b),
      );
      await tester.pumpAndSettle();
      final rightLeafId = layout.activeLeafId;

      layout.moveTab(
        TabDragData(sourceLeafId: rightLeafId, tabIndex: 0, tab: b),
        'leaf-0',
        1,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final surviving = tester.getRect(_leafGroup('leaf-0'));
      expect(surviving.width, greaterThan(400));
      expect(surviving.width, lessThan(800));

      await tester.pumpAndSettle();
      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(800, 0.5));
      expect(find.byKey(ValueKey('exiting:$rightLeafId')), findsNothing);
    });

    testWidgets('3-way split and middle-pane collapse keep siblings anchored/flush', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final c = _tab('C');
      final group = EditorTabGroupController()..insert(0, a);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      await tester.pumpWidget(_workspaceHarness(layout: layout));
      layout.openInSplit('leaf-0', c, DropEdge.right);
      await tester.pumpAndSettle();
      final rightLeaf = layout.activeLeafId;

      // Split the left pane right: middle pane opens between 0 and 400 while
      // the right pane stays put at 400..800.
      layout.openInSplit('leaf-0', b, DropEdge.right);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final midLeaf = layout.activeLeafId;

      final rLeft = tester.getRect(_leafViewport('leaf-0'));
      final rMid = tester.getRect(_leafViewport(midLeaf));
      final rRight = tester.getRect(_leafViewport(rightLeaf));
      expect(rLeft.width, greaterThan(200));
      expect(rLeft.width, lessThan(400));
      expect(rMid.width, greaterThan(0));
      expect(rMid.width, lessThan(200));
      expect(rLeft.right, closeTo(rMid.left, 0.5));
      expect(rMid.right, closeTo(400, 0.5));
      expect(rRight, const Rect.fromLTWH(400, 0, 400, 600));

      await tester.pumpAndSettle();
      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(200, 0.5));
      expect(tester.getRect(_leafGroup(midLeaf)).width, closeTo(200, 0.5));
      expect(tester.getRect(_leafGroup(rightLeaf)).width, closeTo(400, 0.5));

      // Collapse the middle pane: outer panes expand inward smoothly.
      layout.closeLeaf(midLeaf);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      final closingLeft = tester.getRect(_leafGroup('leaf-0'));
      final closingRight = tester.getRect(_leafGroup(rightLeaf));
      final exitingMid = tester.getRect(find.byKey(ValueKey('exiting:$midLeaf')));
      expect(closingLeft.width, greaterThan(200));
      expect(closingRight.width, greaterThan(400));
      expect(closingLeft.right, closeTo(exitingMid.left, 0.5));
      expect(exitingMid.right, closeTo(closingRight.left, 0.5));

      await tester.pumpAndSettle();
      final finalLeft = tester.getRect(_leafGroup('leaf-0'));
      final finalRight = tester.getRect(_leafGroup(rightLeaf));
      expect(finalLeft.right, closeTo(finalRight.left, 0.5));
      expect(finalLeft.width + finalRight.width, closeTo(800, 0.5));
    });
  });

  group('RTL, reduced motion, interruption, and continuity', () {
    testWidgets('mirrors horizontal split and divider drag under RTL', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final group = EditorTabGroupController()..insert(0, a);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      await tester.pumpWidget(
        _workspaceHarness(layout: layout, textDirection: TextDirection.rtl),
      );
      layout.openInSplit('leaf-0', b, DropEdge.right);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final r0 = tester.getRect(_leafViewport('leaf-0'));
      final r1 = tester.getRect(_leafViewport(layout.activeLeafId));
      // Child 0 sits on the right in RTL; child 1 opens on the left.
      expect(r1.left, 0);
      expect(r0.right, closeTo(800, 0.5));
      expect(r1.right, closeTo(r0.left, 0.5));

      await tester.pumpAndSettle();
      expect(tester.getRect(_leafGroup('leaf-0')), const Rect.fromLTWH(400, 0, 400, 600));
      expect(
        tester.getRect(_leafGroup(layout.activeLeafId)),
        const Rect.fromLTWH(0, 0, 400, 600),
      );

      // Dragging the divider left grows child 0 (the right pane in RTL).
      final divider = find.byType(CcResizableDivider);
      final gesture = await tester.startGesture(tester.getCenter(divider));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pump();

      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(450, 0.5));
      expect(
        tester.getRect(_leafGroup(layout.activeLeafId)).width,
        closeTo(350, 0.5),
      );
    });

    testWidgets('reduced motion snaps split open and close immediately', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final group = EditorTabGroupController()..insert(0, a);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      await tester.pumpWidget(
        _workspaceHarness(layout: layout, disableAnimations: true),
      );
      layout.openInSplit('leaf-0', b, DropEdge.right);
      await tester.pump();

      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(400, 0.5));
      expect(
        tester.getRect(_leafGroup(layout.activeLeafId)).width,
        closeTo(400, 0.5),
      );

      layout.closeLeaf(layout.activeLeafId);
      await tester.pump();
      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(800, 0.5));
    });

    testWidgets('swapping layout controller snaps without animating', (
      tester,
    ) async {
      final layout1 = EditorLayoutController.single(
        controller: EditorTabGroupController()..insert(0, _tab('A')),
      );
      final layout2 = EditorLayoutController.single(
        controller: EditorTabGroupController()..insert(0, _tab('B')),
      )..openInSplit('leaf-0', _tab('C'), DropEdge.right);
      addTearDown(() {
        layout1.dispose();
        layout2.dispose();
      });

      await tester.pumpWidget(_workspaceHarness(layout: layout1));
      await tester.pumpWidget(_workspaceHarness(layout: layout2));

      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(400, 0.5));
      expect(
        tester.getRect(_leafGroup(layout2.activeLeafId)).width,
        closeTo(400, 0.5),
      );
    });

    testWidgets('tab selection mid-split does not restart animation', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final c = _tab('C');
      final group = EditorTabGroupController()
        ..insert(0, a)
        ..insert(1, b);
      final layout = EditorLayoutController.single(controller: group);
      addTearDown(layout.dispose);

      await tester.pumpWidget(_workspaceHarness(layout: layout));
      layout.openInSplit('leaf-0', c, DropEdge.right);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      final midWidth = tester.getRect(_leafGroup('leaf-0')).width;

      // Selecting tab A in leaf-0 mid-flight must not jump leaf-0 back to 800.
      await tester.tap(_stripFace('A'));
      await tester.pump();
      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(midWidth, 1));

      await tester.pumpAndSettle();
      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(400, 0.5));
    });

    testWidgets('rapid split interruption settles cleanly', (tester) async {
      final layout = EditorLayoutController.single(
        controller: EditorTabGroupController()..insert(0, _tab('A')),
      );
      addTearDown(layout.dispose);

      await tester.pumpWidget(_workspaceHarness(layout: layout));
      layout.openInSplit('leaf-0', _tab('B'), DropEdge.right);
      final leafB = layout.activeLeafId;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      layout.openInSplit(leafB, _tab('C'), DropEdge.bottom);
      final leafC = layout.activeLeafId;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(tester.getRect(_leafGroup('leaf-0')), const Rect.fromLTWH(0, 0, 400, 600));
      expect(tester.getRect(_leafGroup(leafB)), const Rect.fromLTWH(400, 0, 400, 300));
      expect(tester.getRect(_leafGroup(leafC)), const Rect.fromLTWH(400, 300, 400, 300));
    });

    testWidgets('divider drag clamps at min extent and snaps active transition', (
      tester,
    ) async {
      var resizedCount = 0;
      final layout = EditorLayoutController.single(
        controller: EditorTabGroupController()..insert(0, _tab('A')),
      );
      addTearDown(layout.dispose);

      await tester.pumpWidget(
        _workspaceHarness(layout: layout, onResized: () => resizedCount++),
      );
      layout.openInSplit('leaf-0', _tab('B'), DropEdge.right);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      // Grabbing the divider mid-flight snaps the animation immediately.
      final divider = find.byType(CcResizableDivider);
      final gesture = await tester.startGesture(tester.getCenter(divider));
      await tester.pump();
      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(400, 0.5));

      // Drag far right; clamps at 800 - 120 = 680.
      await gesture.moveBy(const Offset(500, 0));
      await gesture.up();
      await tester.pump();

      expect(resizedCount, greaterThan(0));
      expect(tester.getRect(_leafGroup('leaf-0')).width, closeTo(680, 0.5));
      expect(
        tester.getRect(_leafGroup(layout.activeLeafId)).width,
        closeTo(120, 0.5),
      );
    });

    testWidgets('surviving leaf preserves body state across split and collapse', (
      tester,
    ) async {
      final a = _tab('A');
      final b = _tab('B');
      final layout = EditorLayoutController.single(
        controller: EditorTabGroupController()..insert(0, a),
      );
      addTearDown(layout.dispose);

      State? capturedState;
      await tester.pumpWidget(
        _workspaceHarness(
          layout: layout,
          buildBody: (tab, {required isVisible}) => _ProbeBody(
            key: ValueKey(tab),
            onInit: (s) {
              if (identical(tab, a)) {
                capturedState = s;
              }
            },
          ),
        ),
      );

      final initialState = capturedState;
      expect(initialState, isNotNull);

      layout.openInSplit('leaf-0', b, DropEdge.right);
      await tester.pumpAndSettle();
      expect(identical(capturedState, initialState), isTrue);

      layout.closeLeaf(layout.activeLeafId);
      await tester.pumpAndSettle();
      expect(identical(capturedState, initialState), isTrue);
    });
  });
}

class _ProbeBody extends StatefulWidget {
  const _ProbeBody({super.key, required this.onInit});

  final void Function(State state) onInit;

  @override
  State<_ProbeBody> createState() => _ProbeBodyState();
}

class _ProbeBodyState extends State<_ProbeBody> {
  @override
  void initState() {
    super.initState();
    widget.onInit(this);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
