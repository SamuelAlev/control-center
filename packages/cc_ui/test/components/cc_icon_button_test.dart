import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

// A self-contained icon so the test does not depend on the lucide font asset.
const IconData _testIcon = IconData(0xe801, fontFamily: 'MaterialIcons');

void main() {
  testWidgets('renders the icon', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcIconButton(icon: _testIcon, onPressed: null),
      ),
    );

    expect(find.byIcon(_testIcon), findsOneWidget);
  });

  testWidgets('fires onPressed on tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcIconButton(icon: _testIcon, onPressed: () => taps++),
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
        ),
      ),
    );

    await tester.tap(find.byIcon(_testIcon));
    await tester.pump();

    // No throw; renders the disabled, smaller secondary box.
    expect(find.byIcon(_testIcon), findsOneWidget);
  });
}
