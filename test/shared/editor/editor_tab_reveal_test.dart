import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A strip that overflows: ten tabs in a 480px lane, like a VS Code editor
/// group with more files open than fit.
EditorTabGroupController _group(int count) {
  final group = EditorTabGroupController();
  for (var i = 1; i <= count; i++) {
    group.openTab(EditorTab(kind: 'file', label: 'Untitled-$i'));
  }
  return group;
}

Widget _harness(
  EditorTabGroupController group, {
  TextDirection textDirection = TextDirection.ltr,
  bool disableAnimations = false,
}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: Directionality(
      textDirection: textDirection,
      // The tabs are Draggables, which need an Overlay to lift into.
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => Align(
              alignment: AlignmentDirectional.topStart,
              child: SizedBox(
                width: 480,
                child: ListenableBuilder(
                  listenable: group,
                  builder: (context, _) => EditorTabBar(
                    leafId: 'leaf-0',
                    tabs: group.tabs,
                    labels: [for (final t in group.tabs) t.label],
                    selectedIndex: group.selectedIndex,
                    onTabSelected: (i) => group.selectedIndex = i,
                    onReorderDrop: (_, _) {},
                    onTabClosed: (i) => group.removeAt(i),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Rect _viewport(WidgetTester tester) =>
    tester.getRect(find.byType(SingleChildScrollView));

Rect _slot(WidgetTester tester, EditorTab tab) =>
    tester.getRect(find.byKey(ObjectKey(tab)));

ScrollPosition _position(WidgetTester tester) => tester
    .state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    )
    .position;

void _expectFullyVisible(WidgetTester tester, EditorTab tab) {
  final viewport = _viewport(tester);
  final slot = _slot(tester, tab);
  expect(
    slot.left,
    greaterThanOrEqualTo(viewport.left - 0.5),
    reason: '${tab.label} is cut off at the left edge',
  );
  expect(
    slot.right,
    lessThanOrEqualTo(viewport.right + 0.5),
    reason: '${tab.label} is cut off at the right edge',
  );
}

/// Taps the visible sliver of [tab] — its center may be scrolled out of view.
Future<void> _tapVisible(WidgetTester tester, EditorTab tab) async {
  final visible = _slot(tester, tab).intersect(_viewport(tester));
  expect(
    visible.width,
    greaterThan(4),
    reason: '${tab.label} is not on screen',
  );
  await tester.tapAt(visible.center);
  await tester.pumpAndSettle();
}

void main() {
  group('EditorTabGroupController.openTab', () {
    test('opens the new tab right of the selected one and selects it', () {
      final group = _group(4)..selectedIndex = 1;
      const fresh = EditorTab(kind: 'file', label: 'New');

      group.openTab(fresh);

      expect(group.selectedIndex, 2);
      expect(
        [for (final t in group.tabs) t.label],
        ['Untitled-1', 'Untitled-2', 'New', 'Untitled-3', 'Untitled-4'],
      );
    });

    test('opening several tabs in a row keeps them in order', () {
      final group = _group(3);

      expect(
        [for (final t in group.tabs) t.label],
        ['Untitled-1', 'Untitled-2', 'Untitled-3'],
      );
      expect(group.selectedIndex, 2);
    });

    test('a de-duped open refocuses in place instead of moving the tab', () {
      final group = EditorTabGroupController()
        ..openTab(const EditorTab(kind: 'a', label: 'A', dedupKey: 'a'))
        ..openTab(const EditorTab(kind: 'b', label: 'B'))
        ..openTab(const EditorTab(kind: 'c', label: 'C'))
        ..selectedIndex = 2;

      group.openTab(const EditorTab(kind: 'a', label: 'A', dedupKey: 'a'));

      expect(group.selectedIndex, 0);
      expect([for (final t in group.tabs) t.label], ['A', 'B', 'C']);
    });
  });

  group('EditorTabBar reveals the selected tab', () {
    testWidgets('a restored strip opens scrolled to its selected tab', (
      tester,
    ) async {
      final group = _group(10)..selectedIndex = 8;
      await tester.pumpWidget(_harness(group));
      await tester.pump();

      _expectFullyVisible(tester, group.tabs[8]);
    });

    testWidgets('opening a tab from the last one scrolls to the new last tab', (
      tester,
    ) async {
      final group = _group(10);
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();
      _expectFullyVisible(tester, group.tabs.last);

      group.openTab(const EditorTab(kind: 'file', label: 'Untitled-11'));
      await tester.pumpAndSettle();

      expect(group.tabs.last.label, 'Untitled-11');
      _expectFullyVisible(tester, group.tabs.last);
      // The strip ends there, so it scrolled all the way.
      final position = _position(tester);
      expect(position.pixels, position.maxScrollExtent);
    });

    testWidgets('a tab opened beside a mid-strip tab scrolls into view', (
      tester,
    ) async {
      final group = _group(10)..selectedIndex = 0;
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();
      // Bring the third tab to the right edge so its right neighbour — where
      // the new tab will land — sits in the hidden overflow.
      group.selectedIndex = 2;
      await tester.pumpAndSettle();
      _expectFullyVisible(tester, group.tabs[2]);
      expect(
        _slot(tester, group.tabs[3]).right,
        greaterThan(_viewport(tester).right),
      );

      const fresh = EditorTab(kind: 'file', label: 'Fresh');
      group.openTab(fresh);
      await tester.pumpAndSettle();

      expect(group.tabs[3], same(fresh));
      expect(group.selectedIndex, 3);
      _expectFullyVisible(tester, fresh);
    });

    testWidgets('clicking a tab cut off at the right edge scrolls it whole', (
      tester,
    ) async {
      final group = _group(10)..selectedIndex = 0;
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();
      final viewport = _viewport(tester);
      final partial = group.tabs.firstWhere((t) {
        final slot = _slot(tester, t);
        return slot.left < viewport.right && slot.right > viewport.right;
      });

      await _tapVisible(tester, partial);

      expect(group.tabs[group.selectedIndex], same(partial));
      _expectFullyVisible(tester, partial);
      // Least movement: its trailing edge now meets the viewport's.
      expect(_slot(tester, partial).right, closeTo(viewport.right, 0.5));
    });

    testWidgets('clicking the selected tab after scrolling it half away '
        'brings it back', (tester) async {
      final group = _group(10)..selectedIndex = 3;
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();
      final selected = group.tabs[3];
      final viewport = _viewport(tester);
      // Wheel the strip until the selected tab is clipped at the left edge.
      final position = _position(tester);
      position.jumpTo(
        position.pixels +
            (_slot(tester, selected).left - viewport.left) +
            _slot(tester, selected).width / 2,
      );
      await tester.pump();
      expect(_slot(tester, selected).left, lessThan(viewport.left));

      await _tapVisible(tester, selected);

      _expectFullyVisible(tester, selected);
      expect(_slot(tester, selected).left, closeTo(viewport.left, 0.5));
    });

    testWidgets('a fully visible tab does not scroll the strip', (
      tester,
    ) async {
      final group = _group(10)..selectedIndex = 0;
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();
      expect(_position(tester).pixels, 0);

      await _tapVisible(tester, group.tabs[1]);

      expect(group.selectedIndex, 1);
      expect(_position(tester).pixels, 0);
    });

    testWidgets('closing the active tab reveals the tab that takes over', (
      tester,
    ) async {
      final group = _group(10)..selectedIndex = 0;
      await tester.pumpWidget(_harness(group));
      await tester.pumpAndSettle();
      // Visit the last tab (scrolls right), then the first (scrolls back).
      group.selectedIndex = 9;
      await tester.pumpAndSettle();
      group.selectedIndex = 0;
      await tester.pumpAndSettle();

      // Closing the first tab falls back to the last-visited one.
      group.removeAt(0);
      await tester.pumpAndSettle();

      expect(group.tabs[group.selectedIndex].label, 'Untitled-10');
      _expectFullyVisible(tester, group.tabs[group.selectedIndex]);
    });

    testWidgets('reduced motion jumps straight to the revealed tab', (
      tester,
    ) async {
      final group = _group(10)..selectedIndex = 0;
      await tester.pumpWidget(_harness(group, disableAnimations: true));
      await tester.pump();

      group.selectedIndex = 9;
      await tester.pump();
      await tester.pump();

      _expectFullyVisible(tester, group.tabs[9]);
    });

    testWidgets('reveals follow reading direction under RTL', (tester) async {
      final group = _group(10)..selectedIndex = 0;
      await tester.pumpWidget(
        _harness(group, textDirection: TextDirection.rtl),
      );
      await tester.pumpAndSettle();
      _expectFullyVisible(tester, group.tabs.first);

      group.openTab(const EditorTab(kind: 'file', label: 'Fresh'));
      group.selectedIndex = 10;
      await tester.pumpAndSettle();
      _expectFullyVisible(tester, group.tabs[10]);

      group.selectedIndex = 0;
      await tester.pumpAndSettle();
      _expectFullyVisible(tester, group.tabs[0]);
    });
  });
}
