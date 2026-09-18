import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('children sit flush in both modes', (tester) async {
    // No gutter between rows: a 4px gap is not tappable, so the cursor
    // would snap back to the default arrow while travelling the list.
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
      expect(second.top - first.bottom, 0, reason: 'collapsed: $collapsed');
    }
  });

  testWidgets('the collection keeps a click cursor over the rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 120,
            child: CcSidebarScope(
              collapsed: true,
              child: CcSidebarGroup(
                children: [
                  CcSidebarItem(
                    icon: CcIcons.house,
                    label: 'Dashboard',
                    onPressed: () {},
                  ),
                  CcSidebarItem(
                    icon: CcIcons.inbox,
                    label: 'Inbox',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final regions = tester.widgetList<MouseRegion>(find.byType(MouseRegion));
    expect(
      regions.any((region) => region.cursor == SystemMouseCursors.click),
      isTrue,
    );
  });

  testWidgets('composite child keeps its inner row hover wash', (tester) async {
    // A Column wrapping a CcSidebarItem is how Tickets / Service status land
    // in the app sidebar: the group must not treat that composite as a
    // disabled neighbour-stealing row, and the inner item must still wash.
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 200,
            child: CcSidebarGroup(
              children: [
                CcSidebarItem(
                  icon: CcIcons.inbox,
                  label: 'Inbox',
                  onPressed: () {},
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CcSidebarItem(
                      icon: CcIcons.listTodo,
                      label: 'Tickets',
                      onPressed: () {},
                    ),
                  ],
                ),
                CcSidebarItem(
                  icon: CcIcons.gitPullRequest,
                  label: 'Pull requests',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(location: tester.getCenter(find.text('Tickets')));
    await tester.pump();
    await tester.pump();
    await tester.pump(CcMotion.fast);

    final t = DesignSystemTokens.light();
    Color? fillFor(String label) {
      final item = find.ancestor(
        of: find.text(label),
        matching: find.byType(CcSidebarItem),
      );
      final container = tester.widget<AnimatedContainer>(
        find.descendant(of: item, matching: find.byType(AnimatedContainer)),
      );
      return (container.decoration! as BoxDecoration).color;
    }

    expect(fillFor('Tickets'), t.hover);
    expect(fillFor('Inbox'), isNot(t.hover));
    expect(fillFor('Pull requests'), isNot(t.hover));
  });
}
