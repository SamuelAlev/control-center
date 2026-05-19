import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  testWidgets('renders label and a status dot', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcStatusTag(label: 'Connected', tone: CcStatusTone.positive),
      ),
    );

    expect(find.text('Connected'), findsOneWidget);
    expect(find.byType(CcStatusDot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('omits the dot when dot is false', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        const CcStatusTag(
          label: 'Stopped',
          tone: CcStatusTone.neutral,
          dot: false,
        ),
      ),
    );

    expect(find.text('Stopped'), findsOneWidget);
    expect(find.byType(CcStatusDot), findsNothing);
  });

  testWidgets('renders every tone without throwing', (tester) async {
    await tester.pumpWidget(
      ccTestApp(
        Column(
          children: [
            for (final tone in CcStatusTone.values)
              CcStatusTag(label: tone.name, tone: tone),
          ],
        ),
      ),
    );

    expect(find.byType(CcStatusTag), findsNWidgets(CcStatusTone.values.length));
    expect(tester.takeException(), isNull);
  });
}
