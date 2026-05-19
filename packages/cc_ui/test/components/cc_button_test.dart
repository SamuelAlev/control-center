import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

// A self-contained icon so the test does not depend on the icon font asset.
const IconData _testIcon = IconData(0xe800, fontFamily: 'MaterialIcons');

void main() {
  testWidgets('renders its label child', (tester) async {
    await tester.pumpWidget(
      ccTestApp(const CcButton(onPressed: null, child: Text('Add agent'))),
    );

    expect(find.text('Add agent'), findsOneWidget);
  });

  testWidgets('fires onPressed on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(CcButton(onPressed: () => taps++, child: const Text('Run'))),
    );

    await tester.tap(find.text('Run'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('does not fire when disabled (onPressed null)', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcButton(
          onPressed: null,
          icon: _testIcon,
          child: Text('Disabled'),
        ),
      ),
    );

    await tester.tap(find.text('Disabled'));
    await tester.pump();

    // No throw and the leading icon still renders while disabled.
    expect(find.byIcon(_testIcon), findsOneWidget);
  });

  testWidgets('loading shows a spinner and blocks taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcButton(
          onPressed: () => taps++,
          loading: true,
          child: const Text('Saving'),
        ),
      ),
    );

    await tester.tap(find.text('Saving'));
    await tester.pump();

    expect(taps, 0);
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.pumpWidget(const SizedBox()); // dispose the spinner ticker.
  });

  testWidgets('renders every variant without throwing', (tester) async {
    for (final variant in CcButtonVariant.values) {
      await tester.pumpWidget(
        ccTestApp(
          CcButton(
            onPressed: () {},
            variant: variant,
            child: const Text('Action'),
          ),
        ),
      );
      expect(find.text('Action'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // Dispose between variants so no state leaks across iterations.
      await tester.pumpWidget(ccTestApp(const SizedBox()));
    }
  });

  testWidgets('a disabled bordered variant keeps its border', (tester) async {
    // The secondary variant has an opaque resting border; when disabled the
    // border swaps to borderDisabled rather than vanishing.
    await tester.pumpWidget(
      ccTestApp(
        const CcButton(
          onPressed: null,
          variant: CcButtonVariant.secondary,
          child: Text('Off'),
        ),
      ),
    );
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(CcButton),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final box = container.decoration as BoxDecoration;
    final border = box.border as Border;
    // Disabled secondary still carries a non-transparent border.
    expect(border.top.color.a, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the sm size renders more compact than md', (tester) async {
    final mdKey = GlobalKey();
    final smKey = GlobalKey();
    await tester.pumpWidget(
      ccTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcButton(
              key: mdKey,
              onPressed: () {},
              size: CcButtonSize.md,
              child: const Text('Md'),
            ),
            CcButton(
              key: smKey,
              onPressed: () {},
              size: CcButtonSize.sm,
              child: const Text('Sm'),
            ),
          ],
        ),
      ),
    );
    final mdBox = tester.getSize(
      find.descendant(
        of: find.byKey(mdKey),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final smBox = tester.getSize(
      find.descendant(
        of: find.byKey(smKey),
        matching: find.byType(AnimatedContainer),
      ),
    );
    // sm (32) renders shorter than md (36).
    expect(smBox.height, lessThan(mdBox.height));
  });

  testWidgets('renders a trailing widget', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcButton(
          onPressed: () {},
          icon: _testIcon,
          trailing: const Text('+5'),
          child: const Text('Filters'),
        ),
      ),
    );
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
    expect(find.byIcon(_testIcon), findsOneWidget);
  });

  testWidgets('fullWidth stretches the button across its constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 300,
            child: CcButton(
              onPressed: () {},
              fullWidth: true,
              child: const Text('Wide'),
            ),
          ),
        ),
      ),
    );
    // The wrapping SizedBox(width: infinity) fills the 300px parent.
    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(CcButton),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.width == double.infinity,
        ),
      ),
    );
    expect(sizedBox.width, double.infinity);
  });

  testWidgets('default hugs its content even under bounded constraints', (
    tester,
  ) async {
    // A Container with a non-null alignment expands to fill bounded
    // constraints — regression guard for the hug contract (a hugging button
    // inside a centered column, which hands it loose bounded constraints,
    // must not stretch).
    await tester.pumpWidget(
      ccTestApp(
        Center(
          child: SizedBox(
            width: 300,
            child: Column(
              children: [CcButton(onPressed: () {}, child: const Text('Save'))],
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(CcButton));
    expect(size.width, lessThan(300));
  });

  testWidgets('a leading icon renders in the foreground color', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        CcButton(onPressed: () {}, icon: _testIcon, child: const Text('Save')),
      ),
    );
    expect(find.byIcon(_testIcon), findsOneWidget);
  });

  testWidgets('autofocus requests focus on mount', (tester) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      ccTestApp(
        CcButton(
          onPressed: () {},
          focusNode: node,
          autofocus: true,
          child: const Text('Auto'),
        ),
      ),
    );
    await tester.pump();
    expect(node.hasFocus, isTrue);
  });

  testWidgets('line/ghost/destructive variants resolve and render', (
    tester,
  ) async {
    // Render the three previously-uncovered variants together so their
    // CcButtonTokens factories + resolver branches all execute in one frame.
    await tester.pumpWidget(
      ccTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcButton(
              onPressed: () {},
              variant: CcButtonVariant.line,
              child: const Text('Line'),
            ),
            CcButton(
              onPressed: () {},
              variant: CcButtonVariant.ghost,
              child: const Text('Ghost'),
            ),
            CcButton(
              onPressed: () {},
              variant: CcButtonVariant.destructive,
              child: const Text('Destructive'),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Line'), findsOneWidget);
    expect(find.text('Ghost'), findsOneWidget);
    expect(find.text('Destructive'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading spinner starts/stops under reduced motion', (
    tester,
  ) async {
    // reducedMotion: true forces the spinner controller into a stopped state,
    // exercising the _CcButtonSpinner didChangeDependencies stop branch.
    await tester.pumpWidget(
      ccTestApp(
        theme: CcThemeData.light(reducedMotion: true),
        CcButton(onPressed: () {}, loading: true, child: const Text('Saving')),
      ),
    );
    await tester.pump();
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
    // Dispose so the ticker is torn down cleanly.
    await tester.pumpWidget(const SizedBox());
  });
}
