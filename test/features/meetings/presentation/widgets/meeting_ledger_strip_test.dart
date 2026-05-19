import 'package:control_center/features/meetings/presentation/widgets/meeting_ledger_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('MeetingLedgerStrip', () {
    testWidgets('renders all four numbers', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const MeetingLedgerStrip(
            thisWeek: 5,
            recorded: Duration(hours: 2, minutes: 30),
            openActions: 3,
            decisions: 12,
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.text('2h 30m'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders its labels', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const MeetingLedgerStrip(
            thisWeek: 1,
            recorded: Duration(minutes: 20),
            openActions: 0,
            decisions: 0,
          ),
        ),
      );

      // Labels are rendered uppercase — the mono eyebrow treatment.
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('RECORDED'), findsOneWidget);
      expect(find.text('OPEN ACTIONS'), findsOneWidget);
      expect(find.text('DECISIONS'), findsOneWidget);
    });

    testWidgets('renders zero values', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const MeetingLedgerStrip(
            thisWeek: 0,
            recorded: Duration.zero,
            openActions: 0,
            decisions: 0,
          ),
        ),
      );

      expect(find.text('0'), findsNWidgets(3));
      expect(find.text('0m'), findsOneWidget);
    });

    testWidgets('renders with large values', (tester) async {
      await tester.pumpWidget(
        testWrap(
          const MeetingLedgerStrip(
            thisWeek: 50,
            recorded: Duration(hours: 15, minutes: 42),
            openActions: 27,
            decisions: 150,
          ),
        ),
      );

      expect(find.text('50'), findsOneWidget);
      expect(find.text('15h 42m'), findsOneWidget);
      expect(find.text('27'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('wraps instead of overflowing on a narrow viewport', (
      tester,
    ) async {
      await tester.pumpWidget(
        testWrap(
          const SizedBox(
            width: 320,
            child: MeetingLedgerStrip(
              thisWeek: 3,
              recorded: Duration(hours: 1),
              openActions: 1,
              decisions: 4,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1h 00m'), findsOneWidget);
    });

    testWidgets('accents the open-actions value only when there are any', (
      tester,
    ) async {
      Color colorOfValueAfter(String label) {
        // The value Text directly follows its label inside the entry Row.
        final row = find.ancestor(
          of: find.text(label),
          matching: find.byType(Row),
        );
        final value = find.descendant(
          of: row.first,
          matching: find.byType(Text),
        );
        return tester.widget<Text>(value.at(1)).style!.color!;
      }

      await tester.pumpWidget(
        testWrap(
          const MeetingLedgerStrip(
            thisWeek: 1,
            recorded: Duration(minutes: 5),
            openActions: 0,
            decisions: 0,
          ),
        ),
      );
      final quiet = colorOfValueAfter('OPEN ACTIONS');

      await tester.pumpWidget(
        testWrap(
          const MeetingLedgerStrip(
            thisWeek: 1,
            recorded: Duration(minutes: 5),
            openActions: 4,
            decisions: 0,
          ),
        ),
      );
      final loud = colorOfValueAfter('OPEN ACTIONS');

      // The screen's one accent spend on this strip is earned, not permanent.
      expect(loud, isNot(quiet));
    });
  });
}
