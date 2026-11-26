import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  const segments = <CcSegment<String>>[
    CcSegment(value: 'recent', label: 'Recent'),
    CcSegment(value: 'oldest', label: 'Oldest'),
    CcSegment(value: 'largest', label: 'Largest'),
  ];

  testWidgets('renders every segment label', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: segments,
          value: 'recent',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Oldest'), findsOneWidget);
    expect(find.text('Largest'), findsOneWidget);
  });

  testWidgets('fires onChanged with the tapped value', (tester) async {
    String? changed;
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: segments,
          value: 'recent',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.text('Oldest'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(changed, 'oldest');
  });

  testWidgets('re-tapping the selected segment does not fire', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: segments,
          value: 'recent',
          onChanged: (_) => calls++,
        ),
      ),
    );

    await tester.tap(find.text('Recent'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(calls, 0);
  });

  testWidgets('works with a non-String type parameter', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSegmentedToggle<int>(
          segments: [
            CcSegment(value: 0, label: 'Off'),
            CcSegment(value: 1, label: 'On'),
          ],
          value: 0,
          onChanged: null,
        ),
      ),
    );

    expect(find.text('Off'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
    expect(find.byType(CcSegmentedToggle<int>), findsOneWidget);
  });

  testWidgets('renders a single segment', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: const [CcSegment(value: 'only', label: 'Only')],
          value: 'only',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Only'), findsOneWidget);
  });

  testWidgets('renders a leading icon when provided', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: const [
            CcSegment(value: 'diff', label: 'Diff', icon: IconData(0xe800)),
            CcSegment(value: 'preview', label: 'Preview'),
          ],
          value: 'diff',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.byType(Icon), findsOneWidget);
  });

  testWidgets('icon-only segments hide the label and keep a tooltip', (
    tester,
  ) async {
    const grid = IconData(0xe800);
    const list = IconData(0xe801);
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: const [
            CcSegment(
              value: 'grid',
              label: 'Grid view',
              icon: grid,
              iconOnly: true,
            ),
            CcSegment(
              value: 'list',
              label: 'List view',
              icon: list,
              iconOnly: true,
            ),
          ],
          value: 'grid',
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Grid view'), findsNothing);
    expect(find.text('List view'), findsNothing);
    expect(find.byIcon(grid), findsOneWidget);
    expect(find.byIcon(list), findsOneWidget);
    expect(
      tester
          .widgetList<CcTooltip>(find.byType(CcTooltip))
          .map((t) => t.message),
      ['Grid view', 'List view'],
    );
  });

  testWidgets('icon-only tap fires onChanged', (tester) async {
    const list = IconData(0xe801);
    String? changed;
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: const [
            CcSegment(
              value: 'grid',
              label: 'Grid view',
              icon: IconData(0xe800),
              iconOnly: true,
            ),
            CcSegment(
              value: 'list',
              label: 'List view',
              icon: list,
              iconOnly: true,
            ),
          ],
          value: 'grid',
          onChanged: (v) => changed = v,
        ),
      ),
    );

    await tester.tap(find.byIcon(list));
    await tester.pump(const Duration(milliseconds: 200));
    expect(changed, 'list');
  });

  testWidgets('a null onChanged disables the control', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcSegmentedToggle<String>(
          segments: segments,
          value: 'recent',
          onChanged: null,
        ),
      ),
    );

    // Every segment reports disabled, so nothing is focusable or tappable.
    for (final tappable in tester.widgetList<CcTappable>(
      find.byType(CcTappable),
    )) {
      expect(tappable.enabled, isFalse);
    }
    await tester.tap(find.text('Oldest'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the size ramp lands on 32 / 40', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        Column(
          children: [
            CcSegmentedToggle<String>(
              key: const Key('sm'),
              segments: segments,
              value: 'recent',
              onChanged: (_) {},
            ),
            CcSegmentedToggle<String>(
              key: const Key('md'),
              segments: segments,
              value: 'recent',
              size: CcSegmentedToggleSize.md,
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byKey(const Key('sm'))).height, 32);
    expect(tester.getSize(find.byKey(const Key('md'))).height, 40);
  });

  testWidgets('selected fill covers the track hairline in the fill color', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: CcSegmentedToggle<String>(
            key: const Key('sm'),
            segments: segments,
            value: 'recent',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    // Covering the 1px track hairline (instead of sitting inside it) is what
    // makes the selected edge the fill color. The fill must be the full 32px
    // track, not the 30px inset a BoxDecoration border would leave.
    final track = tester.getSize(find.byKey(const Key('sm')));
    final fillFinder = find.descendant(
      of: find.ancestor(
        of: find.text('Recent'),
        matching: find.byType(CcTappable),
      ),
      matching: find.byType(AnimatedContainer),
    );
    final fill = tester.widget<AnimatedContainer>(fillFinder);
    expect(track.height, 32);
    expect(tester.getSize(fillFinder).height, 32);
    final decoration = fill.decoration! as BoxDecoration;
    expect(decoration.color, isNotNull);
    expect(decoration.border?.top.color, decoration.color);
  });

  // Regression: the fill used to animate as one color from the brand fill to a
  // transparent hover wash. In dark mode the wash is white-based, so the
  // straight RGB midpoint flashed pale grey on both segments at every change.
  testWidgets(
    'a selection change fades the fill without passing through grey',
    (tester) async {
      final dark = CcThemeData.dark();
      final fillRgb = CcButtonTokens.primary(
        dark.tokens,
      ).bg.withValues(alpha: 1);
      var value = 'recent';
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: StatefulBuilder(
              builder: (context, setState) => CcSegmentedToggle<String>(
                segments: segments,
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
          theme: dark,
        ),
      );

      await tester.tap(find.text('Oldest'));
      await tester.pump();
      await tester.pump(CcMotion.moderate ~/ 2);

      for (final label in ['Recent', 'Oldest']) {
        // The fill is the layer painting both a color and the 1px edge; the
        // focus ring is border-only.
        final fills = tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.ancestor(
                  of: find.text(label),
                  matching: find.byType(CcTappable),
                ),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.border != null && d.color != null)
            .toList();
        expect(fills, hasLength(1), reason: '$label has one fill layer');
        final color = fills.single.color!;
        expect(color.a, inExclusiveRange(0, 1), reason: '$label is mid-fade');
        expect(
          color.withValues(alpha: 1),
          fillRgb,
          reason: '$label fades only the fill alpha',
        );
      }
    },
  );

  testWidgets('fullWidth gives every segment the same width', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 400,
            child: CcSegmentedToggle<String>(
              segments: segments,
              value: 'recent',
              fullWidth: true,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final widths = [
      for (final label in ['Recent', 'Oldest', 'Largest'])
        tester
            .getSize(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(CcTappable),
              ),
            )
            .width,
    ];
    expect(widths[0], closeTo(widths[1], 0.01));
    expect(widths[1], closeTo(widths[2], 0.01));
  });

  testWidgets('arrow keys move the selection and wrap', (tester) async {
    var value = 'recent';
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcSegmentedToggle<String>(
            segments: segments,
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );

    // Tap the selected segment to focus it (roving tabindex), then drive by
    // keyboard. Tapping the selected one is a no-op for selection.
    await tester.tap(find.text('Recent'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 'oldest');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 'recent');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 'largest');
  });

  testWidgets('Home selects the first and End the last', (tester) async {
    var value = 'oldest';
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcSegmentedToggle<String>(
            segments: segments,
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Oldest'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(value, 'recent');

    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    expect(value, 'largest');
  });

  testWidgets('the toggle is one Tab stop and Tab leaves it', (tester) async {
    final before = FocusNode(debugLabel: 'before');
    final after = FocusNode(debugLabel: 'after');
    addTearDown(before.dispose);
    addTearDown(after.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: before,
              child: const SizedBox(width: 20, height: 20),
            ),
            CcSegmentedToggle<String>(
              segments: segments,
              value: 'oldest',
              onChanged: (_) {},
            ),
            Focus(
              focusNode: after,
              child: const SizedBox(width: 20, height: 20),
            ),
          ],
        ),
      ),
    );
    before.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, 'Oldest'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(after.hasPrimaryFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, 'Oldest'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(before.hasPrimaryFocus, isTrue);
  });

  testWidgets('with nothing selected the first segment is the Tab stop', (
    tester,
  ) async {
    final before = FocusNode(debugLabel: 'before');
    addTearDown(before.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Focus(
              focusNode: before,
              child: const SizedBox(width: 20, height: 20),
            ),
            CcSegmentedToggle<String>(
              segments: segments,
              value: 'none',
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    before.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_hasFocus(tester, 'Recent'), isTrue);
  });

  testWidgets('arrow keys move focus with the selection, mirrored in RTL', (
    tester,
  ) async {
    var value = 'oldest';
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcSegmentedToggle<String>(
            segments: segments,
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.tap(find.text('Oldest'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(value, 'largest');
    expect(_hasFocus(tester, 'Largest'), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(value, 'oldest');
  });

  testWidgets('arrow up/down are left to directional focus', (tester) async {
    var value = 'oldest';
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) => CcSegmentedToggle<String>(
            segments: segments,
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Oldest'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(value, 'oldest');
  });

  testWidgets('the selected segment rings in its label colour', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: segments,
          value: 'oldest',
          onChanged: (_) {},
        ),
      ),
    );
    final t = CcThemeData.light().tokens;
    final selected = tester.widget<CcTappable>(
      find.ancestor(of: find.text('Oldest'), matching: find.byType(CcTappable)),
    );
    final other = tester.widget<CcTappable>(
      find.ancestor(of: find.text('Recent'), matching: find.byType(CcTappable)),
    );
    // The accent ring would vanish into the selected ink fill.
    expect(selected.focusRingColor, CcButtonTokens.primary(t).fg);
    expect(other.focusRingColor, t.focusRing);
  });

  testWidgets('the track grows with the text size and keeps 32 at 1x', (
    tester,
  ) async {
    final scale = ValueNotifier<double>(1);
    addTearDown(scale.dispose);
    await tester.pumpWidget(
      ccTestApp(
        ValueListenableBuilder<double>(
          valueListenable: scale,
          builder: (context, factor, _) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(factor)),
            child: Center(
              child: CcSegmentedToggle<String>(
                key: const Key('toggle'),
                segments: segments,
                value: 'recent',
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(const Key('toggle'))).height, 32);

    scale.value = 2;
    await tester.pumpAndSettle();
    final track = tester.getRect(find.byKey(const Key('toggle')));
    final label = tester.getRect(find.text('Recent'));
    expect(track.height, greaterThan(32));
    expect(track.top, lessThanOrEqualTo(label.top));
    expect(track.bottom, greaterThanOrEqualTo(label.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the selected segment is announced as selected', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: segments,
          value: 'oldest',
          onChanged: (_) {},
        ),
      ),
    );

    expect(
      tester.getSemantics(find.text('Oldest')),
      matchesSemantics(
        label: 'Oldest',
        hasSelectedState: true,
        isSelected: true,
        isButton: true,
        isEnabled: true,
        isFocusable: true,
        hasEnabledState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('focus stays on its segment when the count changes', (
    tester,
  ) async {
    final count = ValueNotifier(2);
    addTearDown(count.dispose);
    await tester.pumpWidget(
      ccTestApp(
        ValueListenableBuilder<int>(
          valueListenable: count,
          builder: (context, n, _) => CcSegmentedToggle<String>(
            segments: [
              for (var i = 0; i < n; i++)
                CcSegment(value: 'v$i', label: 'Segment $i'),
            ],
            value: 'v1',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.text('Segment 1'));
    await tester.pump();
    expect(_hasFocus(tester, 'Segment 1'), isTrue);

    count.value = 4;
    await tester.pumpAndSettle();
    expect(find.text('Segment 3'), findsOneWidget);
    expect(_hasFocus(tester, 'Segment 1'), isTrue);
    expect(tester.takeException(), isNull);
  });

  test('CcSegment compares by value, label, icon and iconOnly', () {
    const a = CcSegment(value: 'x', label: 'X');
    const b = CcSegment(value: 'x', label: 'X');
    const c = CcSegment(value: 'x', label: 'X', icon: IconData(0xe800));
    const d = CcSegment(
      value: 'x',
      label: 'X',
      icon: IconData(0xe800),
      iconOnly: true,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
    expect(c, isNot(d));
  });
}

/// Whether the segment labelled [label] holds primary focus.
bool _hasFocus(WidgetTester tester, String label) =>
    Focus.of(tester.element(find.text(label))).hasPrimaryFocus;
