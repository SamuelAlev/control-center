import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcAlert', () {
    testWidgets('renders its title', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcAlert(title: 'Heads up')),
      );

      expect(find.text('Heads up'), findsOneWidget);
    });

    testWidgets('renders the description and icon', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcAlert(
            title: 'Build failed',
            variant: CcAlertVariant.danger,
            icon: IconData(0x1, fontFamily: 'test'),
            description: Text('See logs'),
          ),
        ),
      );

      expect(find.text('Build failed'), findsOneWidget);
      expect(find.text('See logs'), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('omits the description when not provided', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcAlert(title: 'Only title', variant: CcAlertVariant.success),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });
}
