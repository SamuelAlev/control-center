import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/goal_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/active_workspace.dart';
import '../../../../../helpers/test_wrap.dart';
import 'work_test_harness.dart';

final _t0 = DateTime.utc(2026, 11, 19, 9);

AgentGoalRun goal({
  AgentGoalStatus status = AgentGoalStatus.active,
  GoalHold? hold,
  String? holdDetail,
  DateTime? holdUntil,
  GoalContract? contract,
  GoalVerification? verification,
  int runCount = 3,
  int? maxRuns = 10,
  int costMicros = 1250000,
  int costCapMicros = 5000000,
  DateTime? deadlineAt,
  String userText = 'Keep the changelog current',
}) => AgentGoalRun(
  id: 'goal-1',
  workspaceId: kTestWorkspaceId,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  agentId: 'agent-1',
  userText: userText,
  status: status,
  hold: hold,
  holdDetail: holdDetail,
  holdUntil: holdUntil,
  contract: contract,
  verification: verification,
  deadlineAt: deadlineAt ?? future,
  costCapMicros: costCapMicros,
  maxRuns: maxRuns,
  costMicros: costMicros,
  runCount: runCount,
  createdAt: _t0,
  updatedAt: _t0,
);

void main() {
  late FakeGoalRepository repo;

  setUp(() => repo = FakeGoalRepository());

  Future<void> pump(
    WidgetTester tester,
    AgentGoalRun g, {
    bool canResume = true,
    bool canApprove = true,
    TextDirection? textDirection,
  }) async {
    // A fresh scope per pump: overrides never carry over.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: workOverrides(goals: repo),
          child: SingleChildScrollView(
            child: GoalCard(
              view: GoalRunView(
                goal: g,
                canResume: canResume,
                canApprove: canApprove,
              ),
            ),
          ),
        ),
        textDirection: textDirection,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an active goal: working line, budget line, pause and stop', (
    tester,
  ) async {
    await pump(tester, goal());
    expect(find.text('Keep the changelog current'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('Working · segment 3'), findsOneWidget);
    expect(find.textContaining('Segment 3 of 10'), findsOneWidget);
    expect(find.textContaining(r'$1.25 of $5.00'), findsOneWidget);
    expect(find.textContaining(' left'), findsOneWidget);
    expect(tip('Pause goal'), findsOneWidget);
    expect(tip('Stop goal'), findsOneWidget);
    expect(tip('Resume goal'), findsNothing);
    expect(tip('Open goal'), findsOneWidget);
    await tester.tap(tip('Pause goal'));
    await tester.pump();
    await tester.tap(tip('Stop goal'));
    await tester.pump();
    expect(repo.calls, [
      'pause:$kTestWorkspaceId:goal-1',
      'cancel:$kTestWorkspaceId:goal-1',
    ]);
  });

  testWidgets('a goal past its deadline says so', (tester) async {
    await pump(tester, goal(deadlineAt: past, maxRuns: null));
    expect(find.textContaining('Past its deadline'), findsOneWidget);
    expect(find.textContaining('Segment 3'), findsOneWidget);
  });

  testWidgets('each hold reads as its sentence, with its detail', (
    tester,
  ) async {
    final cases = {
      GoalHold.waiting: 'Waiting for its next wake',
      GoalHold.verifying: 'Checking whether it is done',
      GoalHold.limit: 'Paused at the usage limit',
      GoalHold.person: 'Needs a person',
      GoalHold.byPerson: 'Paused by a person',
    };
    for (final MapEntry(:key, :value) in cases.entries) {
      await pump(tester, goal(hold: key, holdDetail: 'stalled'));
      expect(find.text(value), findsOneWidget, reason: '$key');
      expect(find.text('No progress in its last segments.'), findsOneWidget);
    }
  });

  testWidgets('waiting on owed work: when the fallback looks again, as the '
      'server sent it', (tester) async {
    await pump(tester, goal(hold: GoalHold.waiting, holdUntil: future));
    expect(
      find.textContaining('Waiting on what it set up · looks again by '),
      findsOneWidget,
    );
  });

  testWidgets('a review stopped by usage limits: limit_parks reads as its '
      'sentence', (tester) async {
    await pump(
      tester,
      goal(
        status: AgentGoalStatus.paused,
        hold: GoalHold.needsReview,
        holdDetail: 'limit_parks',
      ),
    );
    expect(
      find.text('It hit usage limits too often. Look it over, then resume.'),
      findsOneWidget,
    );
  });

  testWidgets('a hold detail with a value shows it as code; an unknown one '
      'shows the generic lead-in', (tester) async {
    await pump(
      tester,
      goal(hold: GoalHold.person, holdDetail: 'check_broken: make test'),
    );
    expect(find.text("This check can't run:"), findsOneWidget);
    expect(find.text('make test'), findsOneWidget);

    await pump(tester, goal(hold: GoalHold.person, holdDetail: 'brand_new'));
    expect(
      find.text("For a reason this version doesn't name:"),
      findsOneWidget,
    );
    expect(find.text('brand_new'), findsOneWidget);
  });

  testWidgets('a paused goal: Resume only when the server says this viewer '
      'may', (tester) async {
    await pump(tester, goal(status: AgentGoalStatus.paused));
    expect(tip('Resume goal'), findsOneWidget);
    await tester.tap(tip('Resume goal'));
    await tester.pump();
    expect(repo.calls, ['resume:$kTestWorkspaceId:goal-1:null']);

    await pump(tester, goal(status: AgentGoalStatus.paused), canResume: false);
    expect(tip('Resume goal'), findsNothing);
    expect(
      find.text(
        'Resuming it or raising its budget belongs to whoever started it.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a budget-exhausted goal offers to raise the cap, only to '
      'whoever may resume it', (tester) async {
    await pump(tester, goal(status: AgentGoalStatus.budgetExhausted));
    expect(find.text('Budget exhausted'), findsOneWidget);
    await tester.tap(find.textContaining('raise cap to'));
    await tester.pump();
    expect(repo.calls, ['resume:$kTestWorkspaceId:goal-1:10000000']);

    await pump(
      tester,
      goal(status: AgentGoalStatus.budgetExhausted),
      canResume: false,
    );
    expect(find.textContaining('raise cap to'), findsNothing);
  });

  testWidgets('approve completion: only in review, behind a confirmation', (
    tester,
  ) async {
    await pump(tester, goal());
    expect(find.text('Approve completion'), findsNothing);

    await pump(tester, goal(hold: GoalHold.needsReview));
    expect(
      find.text(
        'Waiting for review: it says it is done, and nothing confirmed it',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Approve completion'));
    await tester.pumpAndSettle();
    expect(find.text('Close this goal as done?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);

    await tester.tap(find.text('Approve completion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close as done'));
    await tester.pump();
    expect(repo.calls, ['approve:$kTestWorkspaceId:goal-1']);
  });

  testWidgets('approve completion is disabled with its reason when this '
      'viewer may not close the goal', (tester) async {
    await pump(tester, goal(hold: GoalHold.needsReview), canApprove: false);
    final button = tester.widget<CcButton>(
      find.ancestor(
        of: find.text('Approve completion'),
        matching: find.byType(CcButton),
      ),
    );
    expect(button.onPressed, isNull);
    final tooltip = tester.widget<CcTooltip>(
      find.ancestor(
        of: find.text('Approve completion'),
        matching: find.byType(CcTooltip),
      ),
    );
    expect(
      tooltip.message,
      'Only the person who started the pipeline run can approve this '
      "goal's completion.",
    );
    await tester.tap(find.text('Approve completion'));
    await tester.pumpAndSettle();
    expect(find.text('Close this goal as done?'), findsNothing);
    expect(repo.calls, isEmpty);
  });

  testWidgets('a goal with no criteria: the verdict reads as one row about '
      'the objective', (tester) async {
    await pump(
      tester,
      goal(
        hold: GoalHold.person,
        verification: GoalVerification(
          round: 1,
          claimSummary: 'done',
          verdict: GoalVerdict(
            verdict: GoalVerdictOutcome.pass,
            items: [
              GoalVerdictItem(
                criterion: 'the objective',
                state: GoalCriterionState.met,
              ),
            ],
          ),
          at: _t0,
        ),
      ),
    );
    expect(find.text('Done means'), findsOneWidget);
    expect(find.text('The objective'), findsOneWidget);
    expect(find.text('the objective'), findsNothing);
    expect(find.text('Met'), findsOneWidget);
  });

  testWidgets('right to left: the objective row keeps its mark at the start', (
    tester,
  ) async {
    await pump(
      tester,
      goal(
        hold: GoalHold.person,
        verification: GoalVerification(
          round: 1,
          claimSummary: 'done',
          verdict: GoalVerdict(
            verdict: GoalVerdictOutcome.pass,
            items: [
              GoalVerdictItem(
                criterion: 'the objective',
                state: GoalCriterionState.met,
              ),
            ],
          ),
          at: _t0,
        ),
      ),
      textDirection: TextDirection.rtl,
    );
    final text = tester.getCenter(find.text('The objective'));
    final state = tester.getCenter(find.text('Met'));
    expect(state.dx, lessThan(text.dx));
  });

  testWidgets('refusals read by kind', (tester) async {
    final sentences = {
      'goal_not_yours': 'Only the person who started this goal can do that.',
      'goal_not_paused': 'Pause the goal first.',
      'surprise_kind': 'The server refused this:',
    };
    for (final MapEntry(:key, :value) in sentences.entries) {
      repo.error = refusal(key);
      await pump(tester, goal());
      await tester.tap(tip('Pause goal'));
      await tester.pump();
      expect(find.textContaining(value), findsOneWidget, reason: key);
      await tester.pump(const Duration(seconds: 10));
    }
  });

  testWidgets('details: done means with verdicts, checks with results, '
      'verified by another agent', (tester) async {
    final g = goal(
      hold: GoalHold.needsReview,
      contract: GoalContract(
        criteria: ['tests pass', 'docs updated', 'no lint'],
        checks: [
          GoalCheck(run: 'make test'),
          GoalCheck(run: 'make lint'),
          GoalCheck(run: 'make docs'),
          GoalCheck(run: 'make slow'),
          GoalCheck(run: 'make never'),
        ],
      ),
      verification: GoalVerification(
        round: 1,
        claimSummary: 'done',
        reviewerAgentId: 'agent-2',
        verdict: GoalVerdict(
          verdict: GoalVerdictOutcome.fail,
          items: [
            GoalVerdictItem(
              criterion: 'tests pass',
              state: GoalCriterionState.met,
            ),
            GoalVerdictItem(
              criterion: 'docs updated',
              state: GoalCriterionState.unmet,
            ),
            GoalVerdictItem(
              criterion: 'no lint',
              state: GoalCriterionState.cannotTell,
            ),
          ],
          concerns: ['the **docs** are stale'],
        ),
        checks: [
          GoalCheckResult(
            run: 'make test',
            where: GoalCheckLocation.worktree,
            exitCode: 0,
          ),
          GoalCheckResult(
            run: 'make lint',
            where: GoalCheckLocation.worktree,
            exitCode: 2,
          ),
          GoalCheckResult(
            run: 'make docs',
            where: GoalCheckLocation.worktree,
            exitCode: 0,
            skippedUnchanged: true,
          ),
          GoalCheckResult(
            run: 'make slow',
            where: GoalCheckLocation.worktree,
            timedOut: true,
          ),
        ],
        at: _t0,
      ),
    );
    await pump(tester, g);
    // In review: the details start open.
    expect(find.text('Done means'), findsOneWidget);
    expect(find.text('Met'), findsOneWidget);
    expect(find.text('Not met'), findsOneWidget);
    expect(find.text("Can't tell"), findsOneWidget);
    expect(find.text('Passed'), findsOneWidget);
    expect(find.text('Failed · exit 2'), findsOneWidget);
    expect(find.text('Not rerun: nothing changed'), findsOneWidget);
    expect(find.text('Timed out'), findsOneWidget);
    expect(find.text('Not run yet'), findsOneWidget);
    expect(find.text('Last check: not done'), findsOneWidget);
    expect(find.text('the **docs** are stale'), findsOneWidget);
    expect(find.text('Verified by Ada'), findsOneWidget);
  });

  testWidgets('details: no machine check offers to add one; a self-check '
      'says so', (tester) async {
    await pump(
      tester,
      goal(
        hold: GoalHold.person,
        contract: GoalContract(criteria: ['ship it']),
        verification: GoalVerification(
          round: 1,
          claimSummary: 'done',
          verdict: GoalVerdict(verdict: GoalVerdictOutcome.pass),
          at: _t0,
        ),
      ),
    );
    expect(find.text('No machine check'), findsOneWidget);
    expect(find.text('Add a check'), findsOneWidget);
    expect(
      find.text('Verified by itself (no separate checker)'),
      findsOneWidget,
    );
  });

  testWidgets('details stay closed on a working goal until opened', (
    tester,
  ) async {
    await pump(tester, goal(contract: GoalContract(criteria: ['ship it'])));
    expect(find.text('Show details'), findsOneWidget);
    await tester.tap(find.text('Show details'));
    await tester.pumpAndSettle();
    expect(find.text('Hide details'), findsOneWidget);
    expect(find.text('ship it'), findsOneWidget);
  });

  testWidgets('a terminal goal has no live controls', (tester) async {
    await pump(tester, goal(status: AgentGoalStatus.completed));
    expect(tip('Pause goal'), findsNothing);
    expect(tip('Stop goal'), findsNothing);
    expect(tip('Open goal'), findsOneWidget);
    expect(find.text('Working · segment 3'), findsNothing);
  });

  testWidgets('objective text with markdown and control sequences stays '
      'inert', (tester) async {
    await pump(tester, goal(userText: '# Ship [it](https://x.test)\u0007 now'));
    expect(find.text('# Ship [it](https://x.test)\uFFFD now'), findsOneWidget);
  });

  testWidgets('right to left: the objective glyph leads from the right', (
    tester,
  ) async {
    await pump(tester, goal(), textDirection: TextDirection.rtl);
    final title = tester.getCenter(find.text('Keep the changelog current'));
    final badge = tester.getCenter(find.text('Active'));
    expect(badge.dx, lessThan(title.dx));
  });
}
