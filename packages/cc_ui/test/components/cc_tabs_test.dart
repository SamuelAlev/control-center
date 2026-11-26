import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  const tabs = [CcTab('Overview'), CcTab('Activity'), CcTab('Settings')];

  testWidgets('renders every tab label', (tester) async {
    await tester.pumpWidget(
      ccTestApp(CcTabs(tabs: tabs, selectedIndex: 0, onChanged: (_) {})),
    );
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('fires onChanged with the tapped index', (tester) async {
    int? changed;
    await tester.pumpWidget(
      ccTestApp(
        CcTabs(tabs: tabs, selectedIndex: 0, onChanged: (i) => changed = i),
      ),
    );
    await tester.tap(find.text('Settings'));
    expect(changed, 2);
  });

  testWidgets('each tab is built on a CcTappable', (tester) async {
    await tester.pumpWidget(
      ccTestApp(CcTabs(tabs: tabs, selectedIndex: 1, onChanged: (_) {})),
    );
    expect(find.byType(CcTappable), findsNWidgets(tabs.length));
  });

  testWidgets('renders a leading icon when provided', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcTabs(
          tabs: const [CcTab('Home', icon: IconData(0xe800))],
          selectedIndex: 0,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('arrow right advances and arrow left wraps', (tester) async {
    int selected = 0;
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcTabs(
            tabs: tabs,
            selectedIndex: selected,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );
    // Tap the selected tab to focus it (roving tabindex), then drive by keyboard.
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(selected, 1);

    // Wrap from the last index back to the first.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(selected, 0);

    // ArrowLeft wraps from the first to the last.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(selected, 2);
  });

  testWidgets('Home selects the first and End the last', (tester) async {
    int selected = 1;
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcTabs(
            tabs: tabs,
            selectedIndex: selected,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(selected, 0);

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(selected, 2);
  });

  testWidgets('arrow up/down are left to directional focus', (tester) async {
    int selected = 0;
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcTabs(
            tabs: tabs,
            selectedIndex: selected,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(selected, 0);
  });

  testWidgets('arrow keys follow the reading direction under RTL', (
    tester,
  ) async {
    int selected = 1;
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcTabs(
            tabs: tabs,
            selectedIndex: selected,
            onChanged: (i) => setState(() => selected = i),
          ),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    // In RTL the next tab sits to the left.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(_hasFocus(tester, 'Settings'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets('the strip is one Tab stop and Tab leaves it', (tester) async {
    final before = FocusNode(debugLabel: 'before');
    final after = FocusNode(debugLabel: 'after');
    addTearDown(before.dispose);
    addTearDown(after.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: before,
              child: const SizedBox(width: 20, height: 20),
            ),
            CcTabs(tabs: tabs, selectedIndex: 1, onChanged: (_) {}),
            Focus(
              focusNode: after,
              child: const SizedBox(width: 20, height: 20),
            ),
          ],
        ),
      ),
    );
    before.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, 'Activity'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(after.hasPrimaryFocus, isTrue);

    await _shiftTab(tester);
    expect(_hasFocus(tester, 'Activity'), isTrue);

    await _shiftTab(tester);
    expect(before.hasPrimaryFocus, isTrue);
  });

  testWidgets('the selected tab is announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ccTestApp(CcTabs(tabs: tabs, selectedIndex: 1, onChanged: (_) {})),
    );
    expect(
      tester.getSemantics(find.text('Activity')),
      matchesSemantics(
        label: 'Activity',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Overview')),
      matchesSemantics(
        label: 'Overview',
        isButton: true,
        hasSelectedState: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('focus stays on its tab when the tab count changes', (
    tester,
  ) async {
    final count = ValueNotifier(3);
    addTearDown(count.dispose);
    await tester.pumpWidget(
      ccTestApp(
        ValueListenableBuilder<int>(
          valueListenable: count,
          builder: (context, n, _) => CcTabs(
            tabs: [for (var i = 0; i < n; i++) CcTab('Tab $i')],
            selectedIndex: 1,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Tab 1'));
    await tester.pump();
    expect(_hasFocus(tester, 'Tab 1'), isTrue);

    count.value = 4;
    await tester.pumpAndSettle();
    expect(_hasFocus(tester, 'Tab 1'), isTrue);

    // Removing the focused tab hands focus to the tab now at the end.
    await tester.tap(find.text('Tab 3'));
    await tester.pump();
    count.value = 3;
    await tester.pumpAndSettle();
    expect(_hasFocus(tester, 'Tab 2'), isTrue);
    expect(tester.takeException(), isNull);
  });

  test('CcTab value semantics', () {
    const a = CcTab('Home', icon: IconData(0xe800));
    const aDup = CcTab('Home', icon: IconData(0xe800));
    const otherLabel = CcTab('Away', icon: IconData(0xe800));
    const otherIcon = CcTab('Home', icon: IconData(0xe801));

    expect(a, equals(aDup));
    expect(a.hashCode, aDup.hashCode);
    expect(a == otherLabel, isFalse);
    expect(a == otherIcon, isFalse);
  });
}

/// Whether the tab labelled [label] holds primary focus.
bool _hasFocus(WidgetTester tester, String label) =>
    Focus.of(tester.element(find.text(label))).hasPrimaryFocus;

Future<void> _shiftTab(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.tab);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.pump();
}
