import 'package:control_center/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders with child', (tester) async {
      await tester.pumpWidget(testWrap(
        const AppCard(
          child: Text('Card content'),
        ),
      ));

      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(testWrap(
        const AppCard(
          title: Text('My Card'),
          child: Text('Body'),
        ),
      ));

      expect(find.text('My Card'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      await tester.pumpWidget(testWrap(
        const AppCard(
          title: Text('Title'),
          subtitle: Text('Subtitle text'),
        ),
      ));

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testWrap(
        AppCard(
          child: const Text('Tappable card'),
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Tappable card'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tapped, isTrue);
    });

    testWidgets('renders with custom padding', (tester) async {
      await tester.pumpWidget(testWrap(
        const AppCard(
          padding: EdgeInsets.all(24),
          child: Text('Padded'),
        ),
      ));

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('renders raw variant', (tester) async {
      await tester.pumpWidget(testWrap(
        const AppCard(
          raw: true,
          child: Text('Raw card'),
        ),
      ));

      expect(find.text('Raw card'), findsOneWidget);
    });

    testWidgets('renders with image widget', (tester) async {
      await tester.pumpWidget(testWrap(
        const AppCard(
          image: Icon(Icons.image, size: 48),
          child: Text('Card with image'),
        ),
      ));

      expect(find.text('Card with image'), findsOneWidget);
    });
  });
}
