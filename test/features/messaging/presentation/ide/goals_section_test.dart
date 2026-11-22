import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/goals_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_card.dart';
import 'package:control_center/features/todos/providers/goal_run_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';
import '../widgets/work/work_test_harness.dart';

final _t0 = DateTime.utc(2026, 7, 1, 9);

GoalRunView _view(
  String id, {
  AgentGoalStatus status = AgentGoalStatus.active,
  DateTime? updatedAt,
}) => GoalRunView(
  goal: AgentGoalRun(
    id: id,
    workspaceId: 'ws-1',
    spaceId: 'c-1',
    conversationId: 'c-1',
    agentId: 'a-1',
    userText: 'goal $id',
    status: status,
    deadlineAt: DateTime.utc(2027, 7, 6, 9),
    costCapMicros: 50000000,
    maxRuns: 10,
    runCount: 3,
    updatedAt: updatedAt ?? _t0,
    createdAt: _t0,
  ),
  canResume: true,
  canApprove: true,
);

void main() {
  Future<void> pump(WidgetTester tester, List<GoalRunView> views) async {
    // A fresh scope per pump: overrides never carry over.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            ...workOverrides(),
            conversationAgentGoalRunsProvider(
              'c-1',
            ).overrideWith((ref) => Stream.value(views)),
          ],
          child: const SingleChildScrollView(
            child: GoalsSection(conversationId: 'c-1', workspaceId: 'ws-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders nothing when the conversation has no goals', (
    tester,
  ) async {
    await pump(tester, const []);
    expect(find.byType(GoalCard), findsNothing);
    expect(find.text('GOALS'), findsNothing);
  });

  testWidgets('one card per goal, the live count in the header', (
    tester,
  ) async {
    await pump(tester, [
      _view('a'),
      _view('b', status: AgentGoalStatus.paused),
      _view('c', status: AgentGoalStatus.completed),
    ]);
    expect(find.byType(GoalCard), findsNWidgets(3));
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('live goals sort above terminal ones; at most three terminal, '
      'newest first', (tester) async {
    await pump(tester, [
      for (var i = 0; i < 5; i++)
        _view(
          't$i',
          status: AgentGoalStatus.completed,
          updatedAt: _t0.add(Duration(hours: i)),
        ),
      _view('live'),
    ]);
    final cards = tester.widgetList<GoalCard>(find.byType(GoalCard)).toList();
    expect([for (final c in cards) c.view.goal.id], ['live', 't4', 't3', 't2']);
  });
}
