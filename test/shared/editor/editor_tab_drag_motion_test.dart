import 'package:control_center/shared/editor/editor_drop_overlay.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:control_center/shared/editor/editor_tab_face.dart';
import 'package:control_center/shared/editor/editor_tab_ghost.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:control_center/shared/editor/editor_tab_landing.dart';
import 'package:control_center/shared/editor/editor_workspace.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';

const _a = EditorTab(kind: 'chat', label: 'A');
const _b = EditorTab(kind: 'terminal', label: 'B');
const _c = EditorTab(kind: 'browser', label: 'C');

/// The strip's face for the tab titled [label] (not the ghost's or the
/// flight's copy, which live in the overlay and come later in tree order).
Finder _stripFace(String label) => find
    .descendant(
      of: find.byType(EditorTabBar),
      matching: find.byWidgetPredicate(
        (w) => w is EditorTabFace && w.label == label,
      ),
    )
    .first;

Finder get _ghostFace => find.descendant(
  of: find.byType(EditorTabGhost),
  matching: find.byType(EditorTabFace),
);

Finder get _flights =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == '_Flight');

/// Tabs currently painted invisible because their landing is still in flight
/// (the slot keeps their semantics, unlike the label's invisible width twin).
Finder get _awaitingLanding => find.descendant(
  of: find.byType(EditorTabLandingSlot),
  matching: find.byWidgetPredicate(
    (w) => w is Opacity && w.opacity == 0 && w.alwaysIncludeSemantics,
  ),
);

/// A bare strip that applies its own drops, so a drop really moves a tab.
class _Strip extends StatefulWidget {
  const _Strip();

  @override
  State<_Strip> createState() => _StripState();
}

class _StripState extends State<_Strip> {
  final _tabs = [_a, _b, _c];

  @override
  Widget build(BuildContext context) {
    return EditorTabBar(
      leafId: 'leaf-0',
      tabs: _tabs,
      labels: [for (final t in _tabs) t.label],
      selectedIndex: 0,
      onTabSelected: (_) {},
      onReorderDrop: (data, insertIndex) => setState(() {
        final from = _tabs.indexOf(data.tab);
        _tabs.removeAt(from);
        _tabs.insert(
          from < insertIndex ? insertIndex - 1 : insertIndex,
          data.tab,
        );
      }),
    );
  }
}

Widget _harness({
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Directionality(
            textDirection: textDirection,
            child: const Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(width: 600, child: _Strip()),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a lifted tab rides the strip under the point it was grabbed', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    final home = tester.getTopLeft(_stripFace('B'));
    final grab = tester.getCenter(_stripFace('B'));

    final gesture = await tester.startGesture(grab);
    await tester.pump();
    // Sideways and a little down — still over the strip.
    await gesture.moveBy(const Offset(40, 6));
    await tester.pump();

    expect(_ghostFace, findsOneWidget);
    final ghost = tester.getTopLeft(_ghostFace);
    // Horizontally it keeps the grab point under the pointer; vertically it
    // stays on the strip's row instead of following the pointer down.
    expect(ghost.dx, moreOrLessEquals(home.dx + 40));
    expect(ghost.dy, moreOrLessEquals(home.dy));
    // The ghost is the tab itself, at the tab's own size.
    expect(tester.getSize(_ghostFace).width, greaterThan(0));
    expect(tester.getSize(_ghostFace).height, EditorTabBar.height);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('under RTL the ghost rides the strip the same way', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(textDirection: TextDirection.rtl));
    final home = tester.getTopLeft(_stripFace('B'));
    // The strip reads right to left: A sits right of B.
    expect(tester.getTopLeft(_stripFace('A')).dx, greaterThan(home.dx));

    final gesture = await tester.startGesture(
      tester.getCenter(_stripFace('B')),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(-40, 6));
    await tester.pump();

    final ghost = tester.getTopLeft(_ghostFace);
    expect(ghost.dx, moreOrLessEquals(home.dx - 40));
    expect(ghost.dy, moreOrLessEquals(home.dy));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('pulled off the strip, the ghost eases free of it', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    final home = tester.getTopLeft(_stripFace('B'));
    final grab = tester.getCenter(_stripFace('B'));

    final gesture = await tester.startGesture(grab);
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    // Mid-travel: off the strip's row, not yet under the pointer.
    final travelling = tester.getTopLeft(_ghostFace).dy;
    expect(travelling, greaterThan(home.dy));
    expect(travelling, lessThan(home.dy + 200));

    await tester.pumpAndSettle();
    // Settled: the grab point is back under the pointer, in both axes.
    expect(tester.getTopLeft(_ghostFace), home + const Offset(20, 200));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a released tab glides into its new slot, then shows', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());
    final aLeft = tester.getTopLeft(_stripFace('A')).dx;

    // Drag C onto the left half of A: it lands first.
    final gesture = await tester.startGesture(
      tester.getCenter(_stripFace('C')),
    );
    await tester.pump();
    await gesture.moveTo(Offset(aLeft + 2, 17));
    await tester.pumpAndSettle();
    final ghostAtRelease = tester.getTopLeft(_ghostFace);
    await gesture.up();
    await tester.pump();

    // The strip is already in its final order; the real C waits, invisible,
    // while a copy flies in from where the ghost was let go.
    expect(tester.getTopLeft(_stripFace('C')).dx, moreOrLessEquals(aLeft));
    expect(_flights, findsOneWidget);
    expect(_awaitingLanding, findsOneWidget);
    final flying = find.descendant(
      of: _flights,
      matching: find.byType(EditorTabFace),
    );
    expect(tester.getTopLeft(flying), ghostAtRelease);

    await tester.pumpAndSettle();
    expect(_flights, findsNothing);
    expect(_awaitingLanding, findsNothing);
    expect(tester.getTopLeft(_stripFace('C')).dx, moreOrLessEquals(aLeft));
  });

  testWidgets('an accepted drop lays the strip out at once', (tester) async {
    await tester.pumpWidget(_harness());
    final start = tester.getTopLeft(_stripFace('A')).dx;

    // Drag A past the end: B and C close up at once, with no slot easing
    // from the width of the tab it used to hold.
    final gesture = await tester.startGesture(
      tester.getCenter(_stripFace('A')),
    );
    await tester.pump();
    await gesture.moveTo(const Offset(500, 17));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pump();

    expect(tester.getTopLeft(_stripFace('B')).dx, moreOrLessEquals(start));
    final bRight = tester.getTopRight(_stripFace('B')).dx;
    expect(tester.getTopLeft(_stripFace('C')).dx, moreOrLessEquals(bRight));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_stripFace('B')).dx, moreOrLessEquals(start));
  });

  testWidgets('a cancelled drag flies the tab back home', (tester) async {
    await tester.pumpWidget(_harness());
    final home = tester.getTopLeft(_stripFace('B'));

    final gesture = await tester.startGesture(
      tester.getCenter(_stripFace('B')),
    );
    await tester.pump();
    await gesture.moveBy(const Offset(0, 300));
    await tester.pumpAndSettle();
    // Nothing below the strip takes the drop.
    await gesture.up();
    await tester.pump();

    expect(_flights, findsOneWidget);
    await tester.pumpAndSettle();
    expect(_flights, findsNothing);
    expect(_awaitingLanding, findsNothing);
    expect(tester.getTopLeft(_stripFace('B')), home);
  });

  testWidgets('reduced motion drops the glide: the tab is simply there', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(disableAnimations: true));
    final aLeft = tester.getTopLeft(_stripFace('A')).dx;

    final gesture = await tester.startGesture(
      tester.getCenter(_stripFace('C')),
    );
    await tester.pump();
    await gesture.moveTo(Offset(aLeft + 2, 17));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(_flights, findsNothing);
    expect(_awaitingLanding, findsNothing);
    expect(tester.getTopLeft(_stripFace('C')).dx, moreOrLessEquals(aLeft));
  });

  testWidgets('a split washes the new pane where the preview stood', (
    tester,
  ) async {
    final group = EditorTabGroupController()
      ..insert(0, _a)
      ..insert(1, _b);
    final layout = EditorLayoutController.single(controller: group);
    addTearDown(layout.dispose);
    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 800,
          height: 600,
          child: EditorWorkspace(
            layout: layout,
            chrome: const EditorChrome(),
            buildBody: (tab, {required isVisible}) =>
                ColoredBox(key: ValueKey(tab), color: const Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(_stripFace('B')),
    );
    await tester.pump();
    // Onto the right edge band of the body: the preview takes the right half.
    await gesture.moveTo(const Offset(780, 320));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(EditorDropOverlay),
        matching: find.byWidgetPredicate(
          (w) => w is AnimatedOpacity && w.opacity == 1,
        ),
      ),
      findsOneWidget,
    );
    await gesture.up();
    await tester.pump();

    expect(layout.leafCount, 2);
    final newLeaf = layout.activeLeafId;
    final wash = find.byWidgetPredicate(
      (w) => w is EditorPaneLandingWash && w.leafId == newLeaf,
    );
    expect(wash, findsOneWidget);
    // One frame in, the wash covers the new pane at near full strength.
    await tester.pump(const Duration(milliseconds: 16));
    final washing = find.descendant(of: wash, matching: find.byType(Opacity));
    expect(washing, findsOneWidget);
    expect(tester.widget<Opacity>(washing).opacity, greaterThan(0.5));
    // The previous pane's preview does not fade on top of it.
    expect(
      find.descendant(
        of: find.byType(EditorDropOverlay),
        matching: find.byWidgetPredicate(
          (w) => w is AnimatedOpacity && w.opacity > 0,
        ),
      ),
      findsNothing,
    );

    await tester.pumpAndSettle();
    expect(washing, findsNothing);
    expect(_flights, findsNothing);
    // B landed as the first tab of the new pane's strip, to the right.
    expect(tester.getTopLeft(_stripFace('B')).dx, greaterThan(300));
  });
}
