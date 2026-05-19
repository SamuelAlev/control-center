import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('AgentAvatar', () {
    testWidgets('renders initials', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentAvatar(name: 'Alice Smith', size: 32, color: Colors.blue),
      ));

      expect(find.text('AS'), findsOneWidget);
    });

    testWidgets('single word name uses first letter', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentAvatar(name: 'Claude', size: 32, color: Colors.purple),
      ));

      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('two-letter name treated as single word', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentAvatar(name: 'AI', size: 32, color: Colors.green),
      ));

      // "AI" is a single part, so _initials returns "A".
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('handles multi-word names', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentAvatar(
          name: 'John Michael Doe',
          size: 40,
          color: Colors.orange,
        ),
      ));

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('empty name shows question mark', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentAvatar(name: '', size: 32, color: Colors.red),
      ));

      // Empty name produces "?" as the fallback.
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(testWrap(
        const AgentAvatar(name: 'Sam', size: 64, color: Colors.teal),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final box = container.constraints as BoxConstraints;
      expect(box.minWidth, 64);
      expect(box.minHeight, 64);
    });
  });

  group('SectionEmpty', () {
    testWidgets('renders icon and message', (tester) async {
      await tester.pumpWidget(testWrap(
        const SectionEmpty(
          icon: LucideIcons.inbox,
          message: 'No data available yet.',
        ),
      ));

      expect(find.byIcon(LucideIcons.inbox), findsOneWidget);
      expect(find.text('No data available yet.'), findsOneWidget);
    });
  });

  group('compactInt', () {
    test('formats small numbers as-is', () {
      expect(compactInt(0), '0');
      expect(compactInt(5), '5');
      expect(compactInt(999), '999');
    });

    test('formats thousands with k suffix', () {
      expect(compactInt(1000), '1.0k');
      expect(compactInt(1500), '1.5k');
      expect(compactInt(999000), '999.0k');
    });

    test('formats millions with M suffix', () {
      expect(compactInt(1000000), '1.0M');
      expect(compactInt(2300000), '2.3M');
      expect(compactInt(999000000), '999.0M');
    });

    test('large values use millions (no billions handling)', () {
      // The implementation does not handle billions; 1B+ still uses M suffix.
      expect(compactInt(1000000000), '1000.0M');
      expect(compactInt(5000000000), '5000.0M');
    });
  });
}
