import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:control_center/features/analytics/presentation/widgets/activity_timeline.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

AgentRunLog _run({
  required String id,
  required String agentId,
  required DateTime startedAt,
  RunStatus status = RunStatus.completed,
}) {
  return AgentRunLog(
    id: id,
    agentId: agentId,
    startedAt: startedAt,
    status: status,
  );
}

void main() {
  group('ActivityTimeline', () {
    testWidgets('renders completed runs', (tester) async {
      await tester.pumpWidget(testWrap(
        ActivityTimeline(
          runs: [
            _run(
              id: '1',
              agentId: 'claude-sonnet',
              startedAt: DateTime.now().subtract(const Duration(minutes: 5)),
            ),
            _run(
              id: '2',
              agentId: 'gpt-4o',
              startedAt: DateTime.now().subtract(const Duration(minutes: 15)),
            ),
          ],
        ),
      ));

      expect(find.text('claude-sonnet'), findsOneWidget);
      expect(find.text('gpt-4o'), findsOneWidget);
      expect(find.text('5m ago'), findsOneWidget);
      expect(find.text('15m ago'), findsOneWidget);
    });

    testWidgets('renders error runs', (tester) async {
      await tester.pumpWidget(testWrap(
        ActivityTimeline(
          runs: [
            _run(
              id: '1',
              agentId: 'buggy-agent',
              startedAt: DateTime.now().subtract(const Duration(hours: 2)),
              status: RunStatus.error,
            ),
          ],
        ),
      ));

      expect(find.text('buggy-agent'), findsOneWidget);
      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('limits to 10 most recent runs', (tester) async {
      final runs = List.generate(
        15,
        (i) => _run(
          id: '$i',
          agentId: 'agent-$i',
          startedAt: DateTime.now().subtract(Duration(minutes: i)),
        ),
      );
      await tester.pumpWidget(testWrap(
        ActivityTimeline(runs: runs),
      ));

      // Should only show first 10
      expect(find.text('agent-0'), findsOneWidget);
      expect(find.text('agent-9'), findsOneWidget);
      // 10th and beyond should not be shown
      expect(find.text('agent-10'), findsNothing);
    });

    testWidgets('renders empty list', (tester) async {
      await tester.pumpWidget(testWrap(
        const ActivityTimeline(runs: []),
      ));

      // No agent IDs should be shown
      expect(find.text('claude-sonnet'), findsNothing);
    });

    testWidgets('renders runs from hours ago', (tester) async {
      await tester.pumpWidget(testWrap(
        ActivityTimeline(
          runs: [
            _run(
              id: '1',
              agentId: 'old-agent',
              startedAt: DateTime.now().subtract(const Duration(hours: 5)),
            ),
          ],
        ),
      ));

      expect(find.text('5h ago'), findsOneWidget);
    });

    testWidgets('renders runs from days ago', (tester) async {
      await tester.pumpWidget(testWrap(
        ActivityTimeline(
          runs: [
            _run(
              id: '1',
              agentId: 'ancient-agent',
              startedAt: DateTime.now().subtract(const Duration(days: 3)),
            ),
          ],
        ),
      ));

      expect(find.text('3d ago'), findsOneWidget);
    });
  });
}
