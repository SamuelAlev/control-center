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

  testWidgets('arrow up/down mirror left/right', (tester) async {
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
    expect(selected, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(selected, 0);
  });

  testWidgets('changing the tab count rebuilds the focus nodes', (
    tester,
  ) async {
    var tabCount = 2;
    late void Function(void Function()) setStateOf;
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            setStateOf = setState;
            final list = [
              for (var i = 0; i < tabCount; i++)
                CcTab(String.fromCharCode(65 + i)),
            ];
            return CcTabs(tabs: list, selectedIndex: 0, onChanged: (_) {});
          },
        ),
      ),
    );
    expect(find.text('C'), findsNothing);

    // Grow from two to three tabs — didUpdateWidget rebuilds the focus nodes.
    setStateOf(() => tabCount = 3);
    await tester.pumpAndSettle();
    expect(find.text('C'), findsOneWidget);
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
