import 'package:cc_ui/src/components/cc_sidebar.dart';
import 'package:cc_ui/src/components/cc_sidebar_item.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders header, items and footer', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          header: Text('Workspace'),
          footer: Text('Account'),
          children: [
            CcSidebarItem(icon: LucideIcons.house, label: 'Dashboard'),
            CcSidebarItem(icon: LucideIcons.bot, label: 'Agents'),
          ],
        ),
      ),
    );

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected item uses a brand-tinted fill with a brand border',
      (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          children: [
            CcSidebarItem(
              icon: LucideIcons.house,
              label: 'Dashboard',
              selected: true,
            ),
          ],
        ),
      ),
    );

    final t = DesignSystemTokens.light();
    // The selected row carries the brand-tinted fill (accentSoft) wrapped in a
    // 1px accent border, with no left indicator bar.
    final selected = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
      final deco = c.decoration;
      if (deco is! BoxDecoration) return false;
      final border = deco.border;
      return deco.color == t.accentSoft &&
          border is Border &&
          border.top.color == t.accent &&
          border.top.width == 1;
    });
    expect(selected, isNotEmpty);
  });

  testWidgets('collapsed sidebar hides labels', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          collapsed: true,
          children: [
            CcSidebarItem(icon: LucideIcons.house, label: 'Dashboard'),
            CcSidebarItem(icon: LucideIcons.bot, label: 'Agents'),
          ],
        ),
      ),
    );

    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Agents'), findsNothing);
    expect(find.byIcon(LucideIcons.house), findsOneWidget);
  });
}
