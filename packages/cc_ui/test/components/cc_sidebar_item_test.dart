import 'package:cc_ui/src/components/cc_sidebar_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders icon and label', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarItem(icon: LucideIcons.house, label: 'Dashboard'),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
  });

  testWidgets('fires onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcSidebarItem(
          icon: LucideIcons.bot,
          label: 'Agents',
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('Agents'));
    expect(taps, 1);
  });

  testWidgets('collapsed hides label but keeps the icon', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarItem(
          icon: LucideIcons.house,
          label: 'Dashboard',
          collapsed: true,
        ),
      ),
    );

    expect(find.text('Dashboard'), findsNothing);
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
  });

  testWidgets('selected renders without throwing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarItem(
          icon: LucideIcons.house,
          label: 'Dashboard',
          selected: true,
        ),
      ),
    );

    expect(find.byType(CcSidebarItem), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
