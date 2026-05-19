import 'package:cc_ui/src/components/cc_sidebar_group.dart';
import 'package:cc_ui/src/components/cc_sidebar_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders uppercase label and children', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarGroup(
          label: 'Navigate',
          children: [
            CcSidebarItem(icon: LucideIcons.house, label: 'Dashboard'),
          ],
        ),
      ),
    );

    expect(find.text('NAVIGATE'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('collapsible header toggles children visibility',
      (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarGroup(
          label: 'Navigate',
          collapsible: true,
          children: [
            CcSidebarItem(icon: LucideIcons.house, label: 'Dashboard'),
          ],
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);

    await tester.tap(find.text('NAVIGATE'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('starts collapsed when initiallyExpanded is false',
      (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarGroup(
          label: 'Navigate',
          collapsible: true,
          initiallyExpanded: false,
          children: [
            CcSidebarItem(icon: LucideIcons.house, label: 'Dashboard'),
          ],
        ),
      ),
    );

    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('NAVIGATE'), findsOneWidget);
  });
}
