import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  const inset = EdgeInsets.symmetric(vertical: AppSpacing.sm);

  Future<void> pump(
    WidgetTester tester, {
    String? subtitle,
    bool signal = true,
  }) async {
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.topCenter,
          child: SpaceRow(
            signal: signal ? const AttentionDot(selected: false) : null,
            label: 'test',
            subtitle: subtitle == null ? null : Text(subtitle),
            selected: false,
            cardInset: inset,
            onPress: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('a quiet row starts its title at the inset, no empty column', (
    tester,
  ) async {
    await pump(tester, signal: false);

    final row = tester.getRect(find.byType(SpaceRow));
    expect(row.height, kCcSidebarItemExtent + inset.vertical);
    expect(
      tester.getTopLeft(find.text('test')).dx,
      closeTo(row.left + kSpaceSidebarPad, 0.5),
    );
    await unmount(tester);
  });

  testWidgets('the dot sits at the inset, a gap before the centred title', (
    tester,
  ) async {
    await pump(tester);

    final row = tester.getRect(find.byType(SpaceRow));
    expect(row.height, kCcSidebarItemExtent + inset.vertical);
    final dot = tester.getRect(find.byType(AttentionDot));
    final title = tester.getRect(find.text('test'));
    expect(dot.left, greaterThanOrEqualTo(row.left + kSpaceSidebarPad));
    expect(title.left - dot.right, greaterThanOrEqualTo(AppSpacing.xs));
    expect(dot.center.dy, closeTo(title.center.dy, 0.5));
    expect(dot.center.dy, closeTo(row.center.dy, 0.5));
    await unmount(tester);
  });

  testWidgets('with a subtitle the dot stays on the title line', (
    tester,
  ) async {
    await pump(tester, subtitle: '761');

    final row = tester.getRect(find.byType(SpaceRow));
    expect(row.height, greaterThan(kCcSidebarItemExtent + inset.vertical));
    final dot = tester.getCenter(find.byType(AttentionDot)).dy;
    final dotLeft = tester.getRect(find.byType(AttentionDot)).left;
    final title = tester.getRect(find.text('test'));
    final subtitle = tester.getRect(find.text('761'));
    expect(dot, closeTo(title.center.dy, 0.5));
    // Only the title makes room for the dot; the subtitle keeps the row's
    // start edge.
    expect(title.left, greaterThan(subtitle.left));
    expect(subtitle.left, lessThanOrEqualTo(dotLeft));
    await unmount(tester);
  });

  testWidgets('a rail narrower than the mark columns does not overflow', (
    tester,
  ) async {
    // The collapsed rail leaves 32px per item. Space rows keep expanded
    // geometry until the width settles, so they lay out there mid-animation.
    for (final subtitle in [null, '761']) {
      for (final indent in [
        0.0,
        kSpaceSidebarMarkSlot + kSpaceSidebarMarkGap,
      ]) {
        await tester.pumpWidget(
          testWrap(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: kCcSidebarItemExtent,
                child: CcSidebarScope(
                  collapsed: false,
                  transitioning: true,
                  child: SpaceRow(
                    signal: const AttentionDot(selected: false),
                    label: 'a long space title',
                    subtitle: subtitle == null ? null : Text(subtitle),
                    selected: false,
                    count: 12,
                    indent: indent,
                    cardInset: inset,
                    onPress: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('the trailing caption sits flush at the end for any title', (
    tester,
  ) async {
    Widget row(String label) => SpaceRow(
      signal: const AttentionDot(selected: false),
      label: label,
      trailingLabel: '5d',
      selected: false,
      onPress: () {},
    );
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyedSubtree(key: const ValueKey('short'), child: row('Hi')),
                KeyedSubtree(
                  key: const ValueKey('long'),
                  child: row(
                    'A conversation title long enough to need an ellipsis',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    Rect caption(String key) => tester.getRect(
      find.descendant(of: find.byKey(ValueKey(key)), matching: find.text('5d')),
    );
    expect(caption('short').right, closeTo(caption('long').right, 0.5));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  group('semantics', () {
    Future<SemanticsNode> rowNode(
      WidgetTester tester, {
      required bool running,
      required bool attention,
    }) async {
      await tester.pumpWidget(
        testWrap(
          Align(
            alignment: Alignment.topCenter,
            child: SpaceRow(
              signal: conversationActivityMark(
                running: running,
                attention: attention,
              ),
              label: 'test',
              selected: true,
              onPress: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      return tester.getSemantics(find.byType(SpaceRow));
    }

    testWidgets('a running row says so in its own node, not a live spinner', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final node = await rowNode(tester, running: true, attention: false);

      expect(
        node,
        isSemantics(
          label: 'test',
          value: 'Agent responding',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isLiveRegion: false,
        ),
      );
      // The spinner is painted, but its "Loading" label (merged or its own
      // node) is nowhere in the tree.
      expect(find.byType(CcSpinner), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Loading')), findsNothing);
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('the attention dot becomes the row value', (tester) async {
      final handle = tester.ensureSemantics();
      final node = await rowNode(tester, running: false, attention: true);

      expect(node, isSemantics(label: 'test', value: 'Needs your attention'));
      await unmount(tester);
      handle.dispose();
    });

    testWidgets('a quiet row carries no value', (tester) async {
      final handle = tester.ensureSemantics();
      final node = await rowNode(tester, running: false, attention: false);

      expect(node, isSemantics(label: 'test', value: ''));
      await unmount(tester);
      handle.dispose();
    });
  });
}
