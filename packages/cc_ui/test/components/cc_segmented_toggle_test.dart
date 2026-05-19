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

  testWidgets('only the selected segment is a tab stop', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcSegmentedToggle<String>(
          segments: segments,
          value: 'oldest',
          onChanged: (_) {},
        ),
      ),
    );

    final focusable = tester
        .widgetList<CcTappable>(find.byType(CcTappable))
        .where((t) => t.canRequestFocus)
        .length;
    expect(focusable, 1);
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

  testWidgets('changing the segment count rebuilds the focus nodes', (
    tester,
  ) async {
    var count = 2;
    late void Function(void Function()) setStateOf;
    await tester.pumpWidget(
      ccTestApp(
        StatefulBuilder(
          builder: (context, setState) {
            setStateOf = setState;
            return CcSegmentedToggle<String>(
              segments: [
                for (var i = 0; i < count; i++)
                  CcSegment(value: 'v$i', label: 'Segment $i'),
              ],
              value: 'v0',
              onChanged: (_) {},
            );
          },
        ),
      ),
    );
    expect(find.text('Segment 1'), findsOneWidget);

    setStateOf(() => count = 4);
    await tester.pumpAndSettle();
    expect(find.text('Segment 3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('CcSegment compares by value, label and icon', () {
    const a = CcSegment(value: 'x', label: 'X');
    const b = CcSegment(value: 'x', label: 'X');
    const c = CcSegment(value: 'x', label: 'X', icon: IconData(0xe800));
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
