import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  const tabs = [
    CcTab('Overview'),
    CcTab('Activity'),
    CcTab('Settings'),
  ];

  testWidgets('renders every tab label', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcTabs(tabs: tabs, selectedIndex: 0, onChanged: (_) {}),
      ),
    );
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('fires onChanged with the tapped index', (tester) async {
    int? changed;
    await tester.pumpWidget(
      ccTestApp(
        CcTabs(
          tabs: tabs,
          selectedIndex: 0,
          onChanged: (i) => changed = i,
        ),
      ),
    );
    await tester.tap(find.text('Settings'));
    expect(changed, 2);
  });

  testWidgets('each tab is built on a CcTappable', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcTabs(tabs: tabs, selectedIndex: 1, onChanged: (_) {}),
      ),
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
}
