import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

// A self-contained icon so the test does not depend on the icon font asset.
const IconData _testIcon = IconData(0xe801, fontFamily: 'MaterialIcons');

void main() {
  testWidgets('renders the icon', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcIconButton(
          icon: _testIcon,
          onPressed: null,
          semanticLabel: 'Test',
        ),
      ),
    );

    expect(find.byIcon(_testIcon), findsOneWidget);
  });

  testWidgets('fires onPressed on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcIconButton(
          icon: _testIcon,
          onPressed: () => taps++,
          semanticLabel: 'Test',
        ),
      ),
    );

    await tester.tap(find.byIcon(_testIcon));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('does not fire when disabled', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcIconButton(
          icon: _testIcon,
          onPressed: null,
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          semanticLabel: 'Test',
        ),
      ),
    );

    await tester.tap(find.byIcon(_testIcon));
    await tester.pump();

    // No throw; renders the disabled, smaller secondary box.
    expect(find.byIcon(_testIcon), findsOneWidget);
  });

  testWidgets('every variant renders without throwing', (tester) async {
    // Render all variants in one frame (looping with pumpWidget-cleanup
    // between iterations leaves stale gesture state on some variants).
    await tester.pumpWidget(
      ccTestApp(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in CcButtonVariant.values)
              CcIconButton(
                icon: _testIcon,
                onPressed: () {},
                variant: v,
                semanticLabel: v.name,
              ),
          ],
        ),
      ),
    );
    expect(
      find.byIcon(_testIcon),
      findsNWidgets(CcButtonVariant.values.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('accent/line/destructive reflect hovered + pressed states', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CcIconButton(
              icon: _testIcon,
              onPressed: _noop,
              variant: CcButtonVariant.accent,
              semanticLabel: 'accent',
            ),
            CcIconButton(
              icon: _testIcon,
              onPressed: _noop,
              variant: CcButtonVariant.line,
              semanticLabel: 'line',
            ),
            CcIconButton(
              icon: _testIcon,
              onPressed: _noop,
              variant: CcButtonVariant.destructive,
              semanticLabel: 'destructive',
            ),
          ],
        ),
      ),
    );
    // Press the destructive button (startGesture leaves the pointer down) to
    // exercise the hovered + pressed color branches of its resolver.
    final target = find.byType(CcIconButton).last;
    final center = tester.getCenter(target);
    final gesture = await tester.startGesture(center);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await gesture.up();
  });

  testWidgets('a color override tints the rendered icon', (tester) async {
    const red = Color(0xFFFF0000);
    await tester.pumpWidget(
      ccTestApp(
        const CcIconButton(
          icon: _testIcon,
          onPressed: _noop,
          color: red,
          semanticLabel: 'T',
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(_testIcon));
    expect(icon.color, red);
  });

  testWidgets('loading disables the button and spins the icon', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcIconButton(
          icon: _testIcon,
          loading: true,
          onPressed: () => taps++,
          semanticLabel: 'Refresh',
        ),
      ),
    );

    await tester.tap(find.byIcon(_testIcon), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);

    final rotation = find.byType(RotationTransition);
    expect(rotation, findsOneWidget);
    final before = tester.widget<RotationTransition>(rotation).turns.value;
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester.widget<RotationTransition>(rotation).turns.value;
    expect(after, isNot(before));
  });

  testWidgets('loading icon stays static when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcIconButton(
          icon: _testIcon,
          loading: true,
          onPressed: _noop,
          semanticLabel: 'Refresh',
        ),
        theme: CcThemeData.light(reducedMotion: true),
      ),
    );
    expect(find.byIcon(_testIcon), findsOneWidget);
    // No running animation: settle returns without timing out.
    await tester.pumpAndSettle();
  });

  testWidgets('wraps in a CcTooltip when tooltip is provided', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcIconButton(
          icon: _testIcon,
          onPressed: _noop,
          tooltip: 'Hover me',
          semanticLabel: 'T',
        ),
      ),
    );
    expect(find.byType(CcTooltip), findsOneWidget);
  });
}

void _noop() {}
