import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  testWidgets('renders uppercase label and children', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarGroup(
          label: 'Navigate',
          children: [CcSidebarItem(icon: CcIcons.house, label: 'Dashboard')],
        ),
      ),
    );

    expect(find.text('NAVIGATE'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('collapsible header toggles children visibility', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarGroup(
          label: 'Navigate',
          collapsible: true,
          children: [CcSidebarItem(icon: CcIcons.house, label: 'Dashboard')],
        ),
      ),
    );

    expect(find.text('Dashboard'), findsOneWidget);

    await tester.tap(find.text('NAVIGATE'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNothing);
  });

  testWidgets('starts collapsed when initiallyExpanded is false', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarGroup(
          label: 'Navigate',
          collapsible: true,
          initiallyExpanded: false,
          children: [CcSidebarItem(icon: CcIcons.house, label: 'Dashboard')],
        ),
      ),
    );

    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('NAVIGATE'), findsOneWidget);
  });

  testWidgets('children are separated by a 4px gap in both modes', (
    tester,
  ) async {
    // The inter-item rhythm is owned by the group (design rule): sibling
    // items are exactly [AppSpacing.xs] (4px) apart, expanded and collapsed.
    for (final collapsed in <bool>[false, true]) {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 120,
              child: CcSidebarScope(
                collapsed: collapsed,
                child: const CcSidebarGroup(
                  children: [
                    CcSidebarItem(icon: CcIcons.house, label: 'Dashboard'),
                    CcSidebarItem(icon: CcIcons.inbox, label: 'Inbox'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final first = tester.getRect(find.byType(AnimatedContainer).first);
      final second = tester.getRect(find.byType(AnimatedContainer).last);
      expect(
        second.top - first.bottom,
        AppSpacing.xs,
        reason: 'group children must sit 4px apart (collapsed: $collapsed)',
      );
    }
  });
}
