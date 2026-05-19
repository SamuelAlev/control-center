import 'package:control_center/features/analytics/domain/entities/leaderboard_entry.dart';
import 'package:control_center/features/analytics/presentation/widgets/leaderboard_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  group('LeaderboardWidget', () {
    testWidgets('renders with entries', (tester) async {
      await tester.pumpWidget(testWrap(
        LeaderboardWidget(
          entries: const [
            LeaderboardEntry(agentId: 'a1', agentName: 'Alice', score: 100, rank: 1),
            LeaderboardEntry(agentId: 'a2', agentName: 'Bob', score: 75, rank: 2),
            LeaderboardEntry(agentId: 'a3', agentName: 'Charlie', score: 50, rank: 3),
          ],
          selectedWindow: '7d',
          onWindowChanged: (_) {},
        ),
      ));

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
      expect(find.text('100 pts'), findsOneWidget);
      expect(find.text('75 pts'), findsOneWidget);
      expect(find.text('50 pts'), findsOneWidget);
    });

    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(testWrap(
        LeaderboardWidget(
          entries: const [],
          selectedWindow: 'Today',
          onWindowChanged: (_) {},
        ),
      ));

      // Should show "No data" localized text
      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('renders different time windows', (tester) async {
      await tester.pumpWidget(testWrap(
        LeaderboardWidget(
          entries: const [
            LeaderboardEntry(agentId: 'a1', agentName: 'Alice', score: 100, rank: 1),
          ],
          selectedWindow: '30d',
          onWindowChanged: (_) {},
        ),
      ));

      expect(find.text('30d'), findsOneWidget);
    });

    testWidgets('calls onWindowChanged when segment changes', (tester) async {
      String selected = '7d';
      await tester.pumpWidget(testWrap(
        LeaderboardWidget(
          entries: const [
            LeaderboardEntry(agentId: 'a1', agentName: 'Alice', score: 100, rank: 1),
          ],
          selectedWindow: selected,
          onWindowChanged: (v) => selected = v,
        ),
      ));

      await tester.tap(find.text('Today'));
      expect(selected, 'Today');
    });

    testWidgets('renders single entry', (tester) async {
      await tester.pumpWidget(testWrap(
        const LeaderboardWidget(
          entries: [
            LeaderboardEntry(agentId: 'a1', agentName: 'Solo', score: 42, rank: 1),
          ],
          selectedWindow: '7d',
          onWindowChanged: _noop,
        ),
      ));

      expect(find.text('Solo'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('42 pts'), findsOneWidget);
    });
  });
}

void _noop(String _) {}
