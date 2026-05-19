import 'dart:io';

import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, FontLoader;
import 'package:flutter_test/flutter_test.dart';

const _tabs = [
  EditorTab(kind: 'chat', label: 'A'),
  EditorTab(kind: 'terminal', label: 'B'),
  EditorTab(kind: 'browser', label: 'C'),
];

/// Finds the private unsaved-changes dot widget by its runtime type name.
final _dirtyDots = find.byWidgetPredicate(
  (w) => w.runtimeType.toString() == '_DirtyDot',
);

/// The VISIBLE label of the tab titled [label]. Each tab renders the label
/// twice — an invisible w500 twin reserves the selected width so selection
/// never resizes the cell — and the visible one is last in tree order.
Finder _label(String label) => find.text(label).last;

Widget _harness({
  required ValueChanged<int> onTabSelected,
  required TabReorderDrop onReorderDrop,
  int selectedIndex = 0,
  List<bool>? dirty,
  ValueChanged<int>? onTabClosed,
  bool disableAnimations = false,
  List<EditorTab> tabs = _tabs,
  String? fontFamily,
}) {
  final labels = [for (final t in tabs) t.label];
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 600,
              child: DefaultTextStyle.merge(
                style: TextStyle(fontFamily: fontFamily),
                child: EditorTabBar(
                  leafId: 'leaf-0',
                  tabs: tabs,
                  labels: labels,
                  selectedIndex: selectedIndex,
                  onTabSelected: onTabSelected,
                  onReorderDrop: onReorderDrop,
                  dirty: dirty,
                  onTabClosed: onTabClosed,
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
  testWidgets('tapping a tab selects it', (tester) async {
    int? selected;
    await tester.pumpWidget(
      _harness(onTabSelected: (i) => selected = i, onReorderDrop: (_, _) {}),
    );

    await tester.tap(_label('C'));
    expect(selected, 2);
  });

  testWidgets('dragging a tab past the others reports an end insertion', (
    tester,
  ) async {
    TabDragData? droppedData;
    int? droppedIndex;
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (data, index) {
          droppedData = data;
          droppedIndex = index;
        },
      ),
    );

    // Grab tab A and drag it far to the right, past all tabs.
    final gesture = await tester.startGesture(tester.getCenter(_label('A')));
    await tester.pump();
    await gesture.moveTo(const Offset(420, 17));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(droppedData, isNotNull);
    expect(droppedData!.tab.label, 'A');
    expect(droppedData!.sourceLeafId, 'leaf-0');
    // Dropping past the last tab inserts at the end.
    expect(droppedIndex, 3);
  });

  testWidgets('dropping before a tab reports that tab\'s index', (
    tester,
  ) async {
    int? droppedIndex;
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (_, index) => droppedIndex = index,
      ),
    );

    // Drag C onto the left half of B → insert before B (index 1).
    final bLeft = tester.getTopLeft(_label('B'));
    final gesture = await tester.startGesture(tester.getCenter(_label('C')));
    await tester.pump();
    await gesture.moveTo(Offset(bLeft.dx - 2, 17));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(droppedIndex, 1);
  });

  testWidgets('hovering a drag slides tabs aside and restores them on drop', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(onTabSelected: (_) {}, onReorderDrop: (_, _) {}),
    );

    final bBefore = tester.getTopLeft(_label('B')).dx;

    // Drag C over the left half of B → the drop gap opens before B and B
    // slides right to make room (C's own slot collapses, but it sits after B
    // so B's shift is the gap alone).
    final gesture = await tester.startGesture(tester.getCenter(_label('C')));
    await tester.pump();
    await gesture.moveTo(Offset(bBefore - 2, 17));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(_label('B')).dx, greaterThan(bBefore));

    // Dropping (the harness applies no reorder) restores the resting layout.
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_label('B')).dx, moreOrLessEquals(bBefore));
  });

  testWidgets('reduced motion opens the drop gap without animating', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (_, _) {},
        disableAnimations: true,
      ),
    );

    final bBefore = tester.getTopLeft(_label('B')).dx;

    final gesture = await tester.startGesture(tester.getCenter(_label('C')));
    await tester.pump();
    await gesture.moveTo(Offset(bBefore - 2, 17));
    // A single frame — no settling — must already show the full gap.
    await tester.pump();

    expect(tester.getTopLeft(_label('B')).dx, greaterThan(bBefore));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a selected clean tab shows the close button', (tester) async {
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (_, _) {},
        onTabClosed: (_) {},
        // No dirty flags → all clean.
      ),
    );

    // Only the selected tab (A) shows the close × when clean and unhovered.
    expect(find.byIcon(AppIcons.x), findsOneWidget);
    expect(_dirtyDots, findsNothing);
  });

  testWidgets('an unselected dirty tab shows the dot, not a close button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (_, _) {},
        onTabClosed: (_) {},
        selectedIndex: 0, // A selected (clean) → ×
        dirty: const [false, true, false], // B dirty, unselected → dot
      ),
    );

    // One dot (tab B) and one × (the selected clean tab A).
    expect(_dirtyDots, findsOneWidget);
    expect(find.byIcon(AppIcons.x), findsOneWidget);
  });

  testWidgets(
    'a selected dirty tab shows the dot instead of the close button',
    (tester) async {
      await tester.pumpWidget(
        _harness(
          onTabSelected: (_) {},
          onReorderDrop: (_, _) {},
          onTabClosed: (_) {},
          selectedIndex: 1, // B selected AND dirty → dot, not ×
          dirty: const [false, true, false],
        ),
      );

      expect(_dirtyDots, findsOneWidget);
      // A is unselected + clean (nothing); B is selected + dirty (dot) → no ×.
      expect(find.byIcon(AppIcons.x), findsNothing);
    },
  );

  testWidgets('hovering a dirty tab swaps the dot for the close button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (_, _) {},
        onTabClosed: (_) {},
        selectedIndex: 0,
        dirty: const [false, true, false],
      ),
    );

    // Before hover: B shows the dot.
    expect(_dirtyDots, findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(_label('B')));
    await tester.pumpAndSettle();

    // Hover wins: B now shows the × (A stays selected → ×) and no dot remains.
    expect(_dirtyDots, findsNothing);
    expect(find.byIcon(AppIcons.x), findsNWidgets(2));
  });

  testWidgets('changing the selected tab never shifts the strip layout', (
    tester,
  ) async {
    // The FlutterTest font's glyph advances ignore weight, which would make
    // this test vacuous — load the app's real variable font so the selected
    // tab's w500 label genuinely measures wider than the resting w400.
    final bytes = File(
      'packages/cc_ui/fonts/Manrope-Variable.ttf',
    ).readAsBytesSync();
    final loader = FontLoader('Manrope')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();

    // Vacuity guard: with the loaded font, w500 must measure wider than w400,
    // otherwise the equality assertions below could never fail.
    double measure(FontWeight weight) {
      final painter = TextPainter(
        text: TextSpan(
          text: 'Overview',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: weight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    expect(measure(FontWeight.w500), greaterThan(measure(FontWeight.w400)));

    const tabs = [
      EditorTab(kind: 'chat', label: 'Overview'),
      EditorTab(kind: 'terminal', label: 'Diff'),
      EditorTab(kind: 'browser', label: 'Terminal'),
    ];
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (_, _) {},
        onTabClosed: (_) {},
        tabs: tabs,
        fontFamily: 'Manrope',
      ),
    );

    final before = [for (final t in tabs) tester.getTopLeft(_label(t.label))];

    // Select the middle tab: its label goes w400 → w500 and Overview's goes
    // w500 → w400. The reserved-width twin must absorb both, so no label —
    // in particular none to the RIGHT of the selection change — may move.
    await tester.pumpWidget(
      _harness(
        onTabSelected: (_) {},
        onReorderDrop: (_, _) {},
        onTabClosed: (_) {},
        selectedIndex: 1,
        tabs: tabs,
        fontFamily: 'Manrope',
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < tabs.length; i++) {
      final after = tester.getTopLeft(_label(tabs[i].label));
      expect(
        after.dx,
        moreOrLessEquals(before[i].dx, epsilon: 0.01),
        reason: 'tab "${tabs[i].label}" shifted on selection change',
      );
    }
  });
}
