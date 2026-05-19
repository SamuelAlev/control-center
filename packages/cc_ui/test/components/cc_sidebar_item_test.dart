import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets('iconBuilder replaces the font glyph and receives the state '
      'foreground color', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSidebarItem(
          icon: CcIcons.house,
          label: 'Calendar',
          iconBuilder: (color, size) => SizedBox.square(
            dimension: size,
            child: ColoredBox(color: color),
          ),
        ),
      ),
    );

    expect(find.byIcon(CcIcons.house), findsNothing);
    final box = tester.widget<SizedBox>(find.byType(SizedBox).first);
    expect(box.width, 18);
    // Unselected rows render their icon in textSecondary.
    final t = DesignSystemTokens.light();
    expect(
      tester.widget<ColoredBox>(find.byType(ColoredBox).first).color,
      t.textSecondary,
    );
  });

  testWidgets('iconBuilder is used in collapsed rail mode too', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSidebar(
          collapsed: true,
          children: [
            CcSidebarItem(
              icon: CcIcons.house,
              label: 'Calendar',
              iconBuilder: (color, size) => Text('$size'),
            ),
          ],
        ),
      ),
    );

    expect(find.byIcon(CcIcons.house), findsNothing);
    expect(find.text('18.0'), findsOneWidget);
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
      FontWeight.w700,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ink lerps in lockstep with the fill when selection toggles', (
    tester,
  ) async {
    final t = DesignSystemTokens.light();
    // ccTestApp's Overlay entry captures its first child, so prop-swapping via
    // a second pumpWidget never lands; flip `selected` from inside the tree.
    final selected = ValueNotifier(false);
    addTearDown(selected.dispose);
    await tester.pumpWidget(
      ccTestApp(
        ValueListenableBuilder<bool>(
          valueListenable: selected,
          builder: (context, sel, _) => CcSidebarItem(
            icon: CcIcons.house,
            label: 'Inbox',
            selected: sel,
            onPressed: () {},
          ),
        ),
      ),
    );
    Color ink() => tester.widget<Text>(find.text('Inbox')).style!.color!;
    expect(ink(), t.textSecondary);

    // Selecting lerps fill AND ink over CcMotion.fast: mid-flight the ink is
    // between the two endpoints — never white snapped onto the still-mid-lerp
    // fill (which would read white-on-white).
    selected.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(ink(), isNot(t.accentOn));
    expect(ink(), isNot(t.textSecondary));
    await tester.pumpAndSettle();
    expect(ink(), t.accentOn);

    // … and deselecting lerps back.
    selected.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(ink(), isNot(t.accentOn));
    expect(ink(), isNot(t.textSecondary));
    await tester.pumpAndSettle();
    expect(ink(), t.textSecondary);
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

  group('badge placement', () {
    const itemKey = ValueKey('item');

    Future<Rect> pumpAndMeasure(WidgetTester tester, Widget item) async {
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: SizedBox(
              width: 232,
              child: KeyedSubtree(key: itemKey, child: item),
            ),
          ),
        ),
      );
      return tester.getRect(find.byType(AnimatedContainer));
    }

    testWidgets('default pins the badge to the trailing gutter', (tester) async {
      final row = await pumpAndMeasure(
        tester,
        const CcSidebarItem(
          icon: CcIcons.house,
          label: 'Inbox',
          badge: Text('3'),
        ),
      );
      // Right border (1px) + the fixed right inset = the badge's distance
      // from the row's outer right edge, whatever the label's width.
      expect(row.right - tester.getTopRight(find.text('3')).dx, 11);
    });

    testWidgets(
      'badgeBesideLabel hugs the label instead of the trailing gutter',
      (tester) async {
        final row = await pumpAndMeasure(
          tester,
          const CcSidebarItem(
            icon: CcIcons.house,
            label: 'Status',
            badge: Text('3'),
            badgeBesideLabel: true,
          ),
        );
        // The badge rides INSIDE the label's paragraph as a trailing
        // WidgetSpan — the plain text carries an object-replacement char for
        // it. (WidgetSpan children report NaN geometry through getRect, so
        // everything below is measured on the paragraph's own boxes.)
        final paragraph = tester
            .renderObjectList<RenderParagraph>(find.byType(Text))
            .singleWhere((p) => p.text.toPlainText().contains('\uFFFC'));
        final plain = paragraph.text.toPlainText();
        expect(plain, contains('Status'));
        final spanStart = plain.indexOf('\uFFFC');
        expect(spanStart, greaterThan(0));
        // …exactly one small spacing step separates label and badge: the
        // span's child IS that padded badge…
        Padding? badgeParent;
        tester.element(find.text('3')).visitAncestorElements((ancestor) {
          badgeParent = ancestor.widget as Padding?;
          return false;
        });
        expect(
          badgeParent?.padding,
          const EdgeInsets.only(left: AppSpacing.sm),
        );
        // …and because the badge trails the TEXT rather than the flex slot,
        // everything after the last glyph stays empty: the words end well
        // before the row's right edge (the badge rides immediately behind
        // them through the paddings above).
        final textBoxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: spanStart),
        );
        final textEnd = paragraph.localToGlobal(
          Offset(textBoxes.last.right, 0),
        );
        // Badge (≥ a small square) + gap + trailing inset still leave more
        // than an item-height of empty row to the right.
        expect(
          row.right - textEnd.dx,
          greaterThan(kCcSidebarItemExtent + AppSpacing.sm + 11),
        );
      },
    );

    testWidgets('badgeBesideLabel ellipsizes a long label before the badge', (
      tester,
    ) async {
      const longLabel = 'A very long destination label that cannot fit';
      await pumpAndMeasure(
        tester,
        const CcSidebarItem(
          icon: CcIcons.house,
          label: longLabel,
          badge: Text('3'),
          badgeBesideLabel: true,
        ),
      );
      // The label owns the ellipsis (never the badge being clipped away) and
      // the whole layout survives without overflowing the row.
      final host = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (w) =>
                w.data == null &&
                w.textSpan!.toPlainText().startsWith(longLabel),
          );
      expect(host.overflow, TextOverflow.ellipsis);
      expect(find.text('3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
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
