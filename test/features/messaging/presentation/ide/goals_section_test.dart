import 'package:cc_data/cc_data.dart' show RpcAgentGoalRunRepository;
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/presentation/ide/panels/goals_section.dart';
import 'package:control_center/features/todos/providers/goal_run_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 7, 1, 9);

AgentGoalRun _goal({
  String id = 'goal-1',
  AgentGoalKind kind = AgentGoalKind.goal,
  AgentGoalStatus status = AgentGoalStatus.active,
  String userText = 'Keep the changelog current',
  int runCount = 3,
  int? maxRuns = 10,
  int costCents = 125,
  int costCapCents = 5000,
  DateTime? updatedAt,
}) => AgentGoalRun(
  id: id,
  workspaceId: 'ws-1',
  channelId: 'c-1',
  conversationId: 'c-1',
  agentId: 'a-1',
  userText: userText,
  kind: kind,
  status: status,
  deadlineAt: DateTime(2026, 7, 6, 9),
  costCapCents: costCapCents,
  maxRuns: maxRuns,
  costCents: costCents,
  runCount: runCount,
  updatedAt: updatedAt ?? _t0,
  createdAt: _t0,
);

/// Records control calls; the watch is overridden at the provider level so
/// this fake's own stream is never used.
class _FakeGoalRunRepo extends RpcAgentGoalRunRepository {
  _FakeGoalRunRepo() : super(RemoteRpcClient(InProcessRpcChannel.pair().$2));

  final calls = <String>[];

  @override
  Future<void> pauseGoal(String workspaceId, String goalId) async =>
      calls.add('pause:$workspaceId:$goalId');

  @override
  Future<void> resumeGoal(
    String workspaceId,
    String goalId, {
    int? raiseCostCapCents,
  }) async => calls.add('resume:$workspaceId:$goalId:$raiseCostCapCents');

  @override
  Future<void> cancelGoal(String workspaceId, String goalId) async =>
      calls.add('cancel:$workspaceId:$goalId');
}

void main() {
  /// Control buttons render at size 14; status-badge glyphs reuse some of the
  /// same icons at size 12, so finds must scope on size.
  Finder controlIcon(IconData icon) => find.byWidgetPredicate(
    (w) => w is Icon && w.icon == icon && w.size == 14,
  );

  Future<_FakeGoalRunRepo> pump(
    WidgetTester tester, {
    required List<AgentGoalRun> goals,
  }) async {
    final repo = _FakeGoalRunRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentGoalRunRepositoryProvider.overrideWithValue(repo),
          conversationAgentGoalRunsProvider(
            'c-1',
          ).overrideWith((ref) => Stream.value(goals)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData(
              tokens: DesignSystemTokens.light(),
              brightness: CcBrightness.light,
            ),
            child: const CcToastScope(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: GoalsSection(channelId: 'c-1', workspaceId: 'ws-1'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    return repo;
  }

  testWidgets('renders nothing when the conversation has no goals', (
    tester,
  ) async {
    await pump(tester, goals: const []);
    expect(find.text('GOALS'), findsNothing);
  });

  testWidgets(
    'a live goal shows its objective, status, budget line, and controls',
    (tester) async {
      await pump(tester, goals: [_goal()]);

      expect(find.text('GOALS'), findsOneWidget);
      expect(find.text('Keep the changelog current'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(
        find.text('Run 3 of 10 · \$1.25 of \$50.00'),
        findsOneWidget,
        reason: 'the run/cost budget secondary line',
      );
      expect(controlIcon(AppIcons.pause), findsOneWidget);
      expect(controlIcon(AppIcons.circleStop), findsOneWidget);
    },
  );

  testWidgets('a paused goal swaps pause for resume', (tester) async {
    await pump(tester, goals: [_goal(status: AgentGoalStatus.paused)]);

    expect(find.text('Paused'), findsOneWidget);
    expect(controlIcon(AppIcons.play), findsOneWidget);
    expect(controlIcon(AppIcons.pause), findsNothing);
    expect(controlIcon(AppIcons.circleStop), findsOneWidget);
  });

  testWidgets('a terminal goal takes no commands and hides the budget line', (
    tester,
  ) async {
    await pump(tester, goals: [_goal(status: AgentGoalStatus.completed)]);

    expect(find.text('Completed'), findsOneWidget);
    expect(controlIcon(AppIcons.pause), findsNothing);
    expect(controlIcon(AppIcons.play), findsNothing);
    expect(controlIcon(AppIcons.circleStop), findsNothing);
    expect(find.textContaining('Run 3 of 10'), findsNothing);
  });

  testWidgets('tapping pause/stop/resume hits the repo with the goal id', (
    tester,
  ) async {
    final repo = await pump(
      tester,
      goals: [
        _goal(),
        _goal(id: 'goal-2', status: AgentGoalStatus.paused, userText: 'Loop'),
      ],
    );

    await tester.tap(controlIcon(AppIcons.pause));
    await tester.pump();
    await tester.tap(controlIcon(AppIcons.play));
    await tester.pump();
    await tester.tap(controlIcon(AppIcons.circleStop).first);
    await tester.pump();

    expect(repo.calls, [
      'pause:ws-1:goal-1',
      'resume:ws-1:goal-2:null',
      'cancel:ws-1:goal-1',
    ]);
  });

  testWidgets('a goal without a run budget shows the no-cap progress line', (
    tester,
  ) async {
    await pump(tester, goals: [_goal(maxRuns: null)]);

    expect(
      find.text('Run 3 · \$1.25 of \$50.00'),
      findsOneWidget,
      reason: 'no run budget: only the cost cap remains',
    );
  });

  testWidgets('resuming a budget-exhausted goal raises its cap, labeled', (
    tester,
  ) async {
    final repo = await pump(
      tester,
      goals: [
        _goal(
          status: AgentGoalStatus.budgetExhausted,
          costCents: 200,
          costCapCents: 200,
        ),
      ],
    );

    expect(find.text('Budget exhausted'), findsOneWidget);
    final resume = controlIcon(AppIcons.play);
    expect(resume, findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CcTooltip && w.message == 'Resume · raise cap to \$4.00',
      ),
      findsOneWidget,
      reason: 'the raise must be visible before the tap, not a silent double',
    );

    await tester.tap(resume);
    await tester.pump();

    expect(repo.calls, [
      'resume:ws-1:goal-1:400',
    ], reason: 'resume doubles the exhausted cap');
  });

  testWidgets('live goals sort above terminal ones', (tester) async {
    await pump(
      tester,
      goals: [
        _goal(
          id: 'g-done',
          status: AgentGoalStatus.completed,
          userText: 'Finished work',
        ),
        _goal(id: 'g-live', userText: 'Standing order'),
      ],
    );

    final liveY = tester.getTopLeft(find.text('Standing order')).dy;
    final doneY = tester.getTopLeft(find.text('Finished work')).dy;
    expect(liveY, lessThan(doneY));
  });
}
