import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  testWidgets('renders header, items and footer', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          header: Text('Workspace'),
          footer: Text('Account'),
          children: [
            CcSidebarItem(icon: CcIcons.house, label: 'Dashboard'),
            CcSidebarItem(icon: CcIcons.bot, label: 'Agents'),
          ],
        ),
      ),
    );

    expect(find.text('Workspace'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected item uses a brand-tinted fill with a brand border', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          children: [
            CcSidebarItem(
              icon: CcIcons.house,
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
    final selected = tester.widgetList<Container>(find.byType(Container)).where(
      (c) {
        final deco = c.decoration;
        if (deco is! BoxDecoration) return false;
        final border = deco.border;
        return deco.color == t.accentSoft &&
            border is Border &&
            border.top.color == t.accent &&
            border.top.width == 1;
      },
    );
    expect(selected, isNotEmpty);
  });

  testWidgets('collapsed sidebar hides labels', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          collapsed: true,
          children: [
            CcSidebarItem(icon: CcIcons.house, label: 'Dashboard'),
            CcSidebarItem(icon: CcIcons.bot, label: 'Agents'),
          ],
        ),
      ),
    );

    expect(find.text('Dashboard'), findsNothing);
    expect(find.text('Agents'), findsNothing);
    expect(find.byIcon(CcIcons.house), findsOneWidget);
  });

  testWidgets('renders a trailing border when supplied', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          trailingBorder: BorderSide(color: Color(0xFF112233), width: 1),
          children: [CcSidebarItem(icon: CcIcons.house, label: 'Dashboard')],
        ),
      ),
    );
    // A trailingBorder paints a right-hand Border on the sidebar surface.
    expect(tester.takeException(), isNull);
  });

  testWidgets('CcSidebarScope exposes the collapsed flag', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          collapsed: true,
          children: [CcSidebarItem(icon: CcIcons.house, label: 'Dashboard')],
        ),
      ),
    );
    // CcSidebarScope.collapsedOf reads the inherited collapsed flag.
    final read = CcSidebarScope.collapsedOf(
      tester.element(find.byIcon(CcIcons.house)),
    );
    expect(read, isTrue);
  });

  testWidgets(
    'toggling collapsed rebuilds dependent items (updateShouldNotify)',
    (tester) async {
      var collapsed = false;
      late void Function(void Function()) mutate;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              mutate = setState;
              return CcSidebar(
                collapsed: collapsed,
                children: const [
                  CcSidebarItem(icon: CcIcons.house, label: 'Dashboard'),
                ],
              );
            },
          ),
        ),
      );
      // Expanded shows the label.
      expect(find.text('Dashboard'), findsOneWidget);

      // Flip to collapsed — the scope's updateShouldNotify fires and the item
      // rebuilds into rail mode (label hidden).
      mutate(() => collapsed = true);
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'collapsing defers the scope flip until the width animation settles',
    (tester) async {
      var collapsed = false;
      late void Function(void Function()) mutate;
      await tester.pumpWidget(
        ccTestApp(
          StatefulBuilder(
            builder: (context, setState) {
              mutate = setState;
              return CcSidebar(
                collapsed: collapsed,
                children: const [
                  CcSidebarItem(icon: CcIcons.house, label: 'Dashboard'),
                ],
              );
            },
          ),
        ),
      );

      // Start collapsing: the width begins animating, but the scope keeps the
      // expanded geometry — the item is still a full-width row (label laid
      // out, fading) and the scope reports transitioning.
      mutate(() => collapsed = true);
      await tester.pump();
      // The label is still laid out (fading via AnimatedOpacity).
      expect(find.text('Dashboard'), findsOneWidget);
      expect(
        CcSidebarScope.collapsedOf(tester.element(find.byIcon(CcIcons.house))),
        isFalse,
      );
      expect(
        CcSidebarScope.transitioningOf(
          tester.element(find.byIcon(CcIcons.house)),
        ),
        isTrue,
      );

      // After the animation the scope lands on the rail: label gone.
      await tester.pumpAndSettle();
      expect(find.text('Dashboard'), findsNothing);
      expect(
        CcSidebarScope.transitioningOf(
          tester.element(find.byIcon(CcIcons.house)),
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('expanding flips the scope up front', (tester) async {
    var collapsed = true;
    late void Function(void Function()) mutate;
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            mutate = setState;
            return CcSidebar(
              collapsed: collapsed,
              children: const [
                CcSidebarItem(icon: CcIcons.house, label: 'Dashboard'),
              ],
            );
          },
        ),
      ),
    );
    expect(find.text('Dashboard'), findsNothing);

    // Start expanding: rows flip to the expanded geometry immediately (their
    // icon already sits at the rail square's x, so nothing moves) while the
    // width animates out.
    mutate(() => collapsed = false);
    await tester.pump();
    expect(
      CcSidebarScope.collapsedOf(tester.element(find.byIcon(CcIcons.house))),
      isFalse,
    );
    expect(
      CcSidebarScope.transitioningOf(
        tester.element(find.byIcon(CcIcons.house)),
      ),
      isTrue,
    );

    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(
      CcSidebarScope.transitioningOf(
        tester.element(find.byIcon(CcIcons.house)),
      ),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
