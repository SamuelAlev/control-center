import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../cc_test_app.dart';

void main() {
  testWidgets('renders icon and label', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcSidebarItem(icon: CcIcons.house, label: 'Dashboard')),
    );

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(CcIcons.house), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Dashboard')).style?.fontWeight,
      CcTypography.regularWeight,
    );
  });

  testWidgets('fires onPressed when tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcSidebarItem(
          icon: CcIcons.bot,
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
          icon: CcIcons.house,
          label: 'Dashboard',
          collapsed: true,
        ),
      ),
    );

    expect(find.text('Dashboard'), findsNothing);
    expect(find.byIcon(CcIcons.house), findsOneWidget);
  });

  testWidgets(
    'scope transitioning fades the label and drops the badge from layout',
    (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcSidebarScope(
            collapsed: false,
            transitioning: true,
            child: CcSidebarItem(
              icon: CcIcons.house,
              label: 'Dashboard',
              badge: Text('3'),
            ),
          ),
        ),
      );

      // Label is still in the tree (geometry is stable) but fading out.
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('Dashboard'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, 0);
      // The badge left the layout entirely (it would overflow the animating
      // width).
      expect(find.text('3'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected renders without throwing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarItem(
          icon: CcIcons.house,
          label: 'Dashboard',
          selected: true,
        ),
      ),
    );

    expect(find.byType(CcSidebarItem), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Dashboard')).style?.fontWeight,
      CcTypography.mediumWeight,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a trailing badge when provided', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarItem(
          icon: CcIcons.house,
          label: 'Inbox',
          badge: Text('3'),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('interactive item reflects hovered + pressed backgrounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSidebarItem(icon: CcIcons.house, label: 'Hover me', onPressed: () {}),
      ),
    );
    // Pressing the row (startGesture leaves the pointer down) executes the
    // hovered + pressed branches of _background.
    final target = find.byType(CcSidebarItem);
    final center = tester.getCenter(target);
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await gesture.up();
  });

  testWidgets('collapsed item with a badge keeps the badge content', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSidebarItem(
          icon: CcIcons.house,
          label: 'Inbox',
          collapsed: true,
          badge: Text('3'),
        ),
      ),
    );
    // Collapsed rail mode hides the label text but never degrades the badge
    // to a bare dot — the count survives the rail.
    expect(find.text('Inbox'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded item is a fixed 32px tall row (design rule)', (
    tester,
  ) async {
    // The expanded invariant: the row is always [kCcSidebarItemExtent] (32px)
    // tall, whatever width the enclosing sidebar hands it.
    for (final width in <double>[120, 232, 400]) {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: width,
              child: const CcSidebarItem(icon: CcIcons.house, label: 'Inbox'),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(AnimatedContainer));
      expect(
        size.height,
        kCcSidebarItemExtent,
        reason: 'expanded row must stay 32px tall at width $width',
      );
    }
  });

  testWidgets('collapsed item renders as a fixed 32px square (design rule)', (
    tester,
  ) async {
    // The rail invariant: a collapsed item's button is always 32×32
    // ([kCcSidebarItemExtent]), whatever width the enclosing sidebar hands
    // it.
    for (final width in <double>[48, 64, 120]) {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: width,
              child: const CcSidebarItem(
                icon: CcIcons.house,
                label: 'Inbox',
                collapsed: true,
              ),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(AnimatedContainer));
      expect(
        size,
        const Size(kCcSidebarItemExtent, kCcSidebarItemExtent),
        reason: 'rail button must stay 32×32 at content width $width',
      );
    }
  });
}
