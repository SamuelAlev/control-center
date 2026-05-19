import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcAvatar', () {
    testWidgets('falls back to uppercased initials', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcAvatar(initials: 'sa')),
      );

      expect(find.text('SA'), findsOneWidget);
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('falls back to an icon when no image or initials',
        (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcAvatar(icon: IconData(0x1, fontFamily: 'test')),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('honors the requested size', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcAvatar(size: 48, initials: 'AB')),
      );

      final box = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(CcAvatar),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(box.width, 48);
      expect(box.height, 48);
    });
  });
}
