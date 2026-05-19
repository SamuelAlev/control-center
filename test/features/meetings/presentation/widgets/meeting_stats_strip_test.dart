import 'package:control_center/features/meetings/presentation/widgets/meeting_stats_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MeetingStatsStrip', () {
    testWidgets('renders four stat cards', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatsStrip(
          thisWeek: 5,
          recorded: Duration(hours: 2, minutes: 30),
          openActions: 3,
          decisions: 12,
        ),
      ));

      // The stats strip should render all four values.
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2h 30m'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders zero values', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatsStrip(
          thisWeek: 0,
          recorded: Duration.zero,
          openActions: 0,
          decisions: 0,
        ),
      ));

      expect(find.text('0'), findsNWidgets(3));
      expect(find.text('0m'), findsOneWidget);
    });

    testWidgets('renders with large values', (tester) async {
      await tester.pumpWidget(testWrap(
        const MeetingStatsStrip(
          thisWeek: 50,
          recorded: Duration(hours: 15, minutes: 42),
          openActions: 27,
          decisions: 150,
        ),
      ));

      expect(find.text('50'), findsOneWidget);
      expect(find.text('15h 42m'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('adapts to narrow width with 2 columns', (tester) async {
      // Constrain to a narrow viewport to trigger 2-column layout.
      await tester.pumpWidget(testWrap(
        const SizedBox(
          width: 400,
          child: MeetingStatsStrip(
            thisWeek: 3,
            recorded: Duration(hours: 1),
            openActions: 1,
            decisions: 4,
          ),
        ),
      ));

      expect(find.text('3'), findsOneWidget);
      expect(find.text('1h 00m'), findsOneWidget);
    });
  });
}
