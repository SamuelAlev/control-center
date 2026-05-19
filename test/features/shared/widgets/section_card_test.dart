import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  group('SectionCard', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionCard(label: 'SETTINGS'),
      ));

      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionCard(
          label: 'CONTENT',
          child: Text('Body content'),
        ),
      ));

      expect(find.text('Body content'), findsOneWidget);
    });

    testWidgets('renders title widget', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionCard(
          label: 'SECTION',
          title: Text('My Title'),
        ),
      ));

      expect(find.text('My Title'), findsOneWidget);
    });

    testWidgets('renders subtitle', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionCard(
          label: 'SECTION',
          subtitle: Text('Subtitle text'),
        ),
      ));

      expect(find.text('Subtitle text'), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionCard(
          label: 'SECTION',
          trailing: Icon(LucideIcons.settings),
        ),
      ));

      expect(find.byIcon(LucideIcons.settings), findsOneWidget);
    });

    testWidgets('renders with custom padding', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionCard(
          label: 'CUSTOM',
          padding: EdgeInsets.all(24),
          child: Text('Padded'),
        ),
      ));

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('renders without header when no header props provided', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionCard(
          child: Text('No header'),
        ),
      ));

      expect(find.text('No header'), findsOneWidget);
    });
  });
}
