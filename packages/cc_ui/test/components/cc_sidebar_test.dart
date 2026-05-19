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

  testWidgets('draws a trailing borderPrimary hairline against the content', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebar(
          children: [CcSidebarItem(icon: CcIcons.house, label: 'Dashboard')],
        ),
      ),
    );

    // The sidebar's own surface container is the AnimatedContainer ANCESTOR
    // of the body ListView — items run their own AnimatedContainers below it.
    final container = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.byType(ListView),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(border.right.color, CcThemeData.light().tokens.borderPrimary);
    expect(border.right.width, 1);
    expect(border.top.style, BorderStyle.none);
    expect(border.bottom.style, BorderStyle.none);
    expect(border.left.style, BorderStyle.none);
  });

  testWidgets('selected item is a solid brand fill with bold accentOn ink', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSidebar(
          children: [
            CcSidebarItem(
              icon: CcIcons.house,
              label: 'Dashboard',
              selected: true,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );

    final t = DesignSystemTokens.light();
    // The selected row is a SOLID brand fill — the design system's selected
    // state — with no chip, hairline or indicator bar. `bgBrandSolid`, not the
    // raw `accent` signal: white clears 4.5:1 on it in both brightnesses.
    final selected = tester.widgetList<Container>(find.byType(Container)).where(
      (c) => (c.decoration as BoxDecoration?)?.color == t.bgBrandSolid,
    );
    expect(selected, isNotEmpty);
    // … and its content rides that fill in `accentOn` ink at BOLD weight.
    final style = tester.widget<Text>(find.text('Dashboard')).style;
    expect(style?.color, t.accentOn);
    expect(style?.fontWeight, FontWeight.w700);
    // The brand focus ring would vanish against the brand fill, so on the
    // selected row it recolors to `accentOn` rather than offsetting away.
    final tappable = tester.widget<CcTappable>(find.byType(CcTappable));
    expect(tappable.focusRingColor, t.accentOn);
    expect(tappable.focusRingOffset, 0);
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

  testWidgets('pinned children hold their place while the body scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        SizedBox(
          height: 400,
          child: CcSidebar(
            pinnedChildren: const [
              CcSidebarItem(icon: CcIcons.house, label: 'Dashboard'),
            ],
            children: [
              for (var i = 0; i < 40; i++)
                CcSidebarItem(icon: CcIcons.bot, label: 'Space $i'),
            ],
          ),
        ),
      ),
    );

    final pinnedTop = tester.getTopLeft(find.text('Dashboard')).dy;
    await tester.drag(find.text('Space 1'), const Offset(0, -200));
    await tester.pump();

    // The body moved; the pinned row did not.
    expect(find.text('Space 0'), findsNothing);
    expect(tester.getTopLeft(find.text('Dashboard')).dy, pinnedTop);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a body too short for the pinned block does not overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        SizedBox(
          height: 120,
          child: CcSidebar(
            pinnedChildren: [
              for (var i = 0; i < 20; i++)
                CcSidebarItem(icon: CcIcons.house, label: 'Nav $i'),
            ],
            children: const [CcSidebarItem(icon: CcIcons.bot, label: 'Space')],
          ),
        ),
      ),
    );

    // The pinned block is capped at 60% of the body, so the scrolling list
    // keeps a usable slice instead of being squeezed into a negative size.
    expect(find.text('Space'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
