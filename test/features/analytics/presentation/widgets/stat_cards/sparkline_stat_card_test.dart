import 'package:control_center/features/analytics/presentation/widgets/stat_cards/sparkline_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../helpers/test_wrap.dart';

void main() {
  group('SparklineStatCard', () {
    testWidgets('renders title and value', (tester) async {
      await tester.pumpWidget(testWrap(
        const SparklineStatCard(
          title: 'Messages',
          value: '1,234',
          spots: [10, 20, 15, 30, 25],
        ),
      ));

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('renders with prefix icon', (tester) async {
      await tester.pumpWidget(testWrap(
        const SparklineStatCard(
          title: 'PRs',
          value: '42',
          spots: [5, 8, 12, 10, 15],
          prefix: Icon(LucideIcons.gitPullRequest, size: 16),
        ),
      ));

      expect(find.text('PRs'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.byIcon(LucideIcons.gitPullRequest), findsOneWidget);
    });

    testWidgets('renders with suffix', (tester) async {
      await tester.pumpWidget(testWrap(
        const SparklineStatCard(
          title: 'Uptime',
          value: '99.9',
          suffix: '%',
          spots: [99, 100, 99, 100, 99],
        ),
      ));

      expect(find.text('Uptime'), findsOneWidget);
      expect(find.text('99.9'), findsOneWidget);
      expect(find.text('%'), findsOneWidget);
    });

    testWidgets('renders with custom color', (tester) async {
      await tester.pumpWidget(testWrap(
        const SparklineStatCard(
          title: 'Errors',
          value: '5',
          spots: [1, 0, 2, 1, 1],
          color: Colors.red,
        ),
      ));

      expect(find.text('Errors'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('handles tap callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testWrap(
        SparklineStatCard(
          title: 'Tappable',
          value: '10',
          spots: [1, 2, 3, 4, 5],
          onTap: () => tapped = true,
        ),
      ));

      await tester.tap(find.text('Tappable'));
      expect(tapped, isTrue);
    });

    testWidgets('renders with empty sparkline', (tester) async {
      await tester.pumpWidget(testWrap(
        const SparklineStatCard(
          title: 'Empty',
          value: '0',
          spots: [],
        ),
      ));

      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('renders with single spot', (tester) async {
      await tester.pumpWidget(testWrap(
        const SparklineStatCard(
          title: 'Single',
          value: '7',
          spots: [7],
        ),
      ));

      expect(find.text('Single'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });
  });
}
