import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

// A self-contained icon so the test does not depend on the lucide font asset.
const IconData _testIcon = IconData(0xe800, fontFamily: 'MaterialIcons');

void main() {
  testWidgets('renders its label child', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcButton(onPressed: null, child: Text('Add agent')),
      ),
    );

    expect(find.text('Add agent'), findsOneWidget);
  });

  testWidgets('fires onPressed on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcButton(
          onPressed: () => taps++,
          child: const Text('Run'),
        ),
      ),
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

    // No throw, and the leading icon still renders while disabled.
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
}
