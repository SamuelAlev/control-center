@TestOn('browser')
library;

import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/goal_review_prompt.dart'
    show goalReviewObjectiveCriterion;
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/plan_goal/goal_detail.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

final _at = DateTime.utc(2026, 11, 20, 10);

AgentGoalRun _goal({
  AgentGoalStatus status = AgentGoalStatus.active,
  GoalHold? hold,
  String? holdDetail,
  int costMicros = 2000000,
  int costCapMicros = 10000000,
  GoalContract? contract,
  GoalVerification? verification,
  int parkCount = 0,
  String? summary,
}) => AgentGoalRun(
  id: 'g1',
  workspaceId: ws,
  spaceId: 's1',
  conversationId: 'c1',
  agentId: 'a1',
  userText: 'Make the shop-ui checkout tests pass',
  costCapMicros: costCapMicros,
  costMicros: costMicros,
  status: status,
  maxRuns: 6,
  runCount: 2,
  hold: hold,
  holdDetail: holdDetail,
  contract: contract,
  verification: verification,
  parkCount: parkCount,
  summary: summary,
  createdAt: _at,
  updatedAt: _at,
);

void main() {
  late AppLocalizations l;
  WorkRpcHost? host;
  // Made inside each test's zone, so its streams run on the test's clock.
  WorkRpcHost rpc() => host ??= WorkRpcHost();

  setUpAll(() async => l = await english());
  setUp(() => host = null);
  tearDown(() => host?.close());

  Future<void> pump(
    WidgetTester tester,
    AgentGoalRun goal, {
    bool canResume = true,
    bool canApprove = true,
    WorkspaceRole role = WorkspaceRole.member,
    TextDirection? direction,
  }) => pumpWork(
    tester,
    PhoneGoalDetail(
      view: GoalRunView(
        goal: goal,
        canResume: canResume,
        canApprove: canApprove,
      ),
      workspaceId: ws,
    ),
    overrides: workOverrides(rpc(), role: role),
    direction: direction,
  );

  testWidgets('a working goal says so, shows segments and money, and offers '
      'pause and cancel', (tester) async {
    await pump(tester, _goal());
    expect(find.text(l.goalHoldWorking(2)), findsOneWidget);
    expect(find.text(l.goalSegments(2, 6)), findsOneWidget);
    expect(find.textContaining(r'$2.00'), findsWidgets);
    expect(find.text(l.goalNoMachineCheck), findsOneWidget);
    expect(find.text(l.mobileGoalPause), findsOneWidget);
    expect(find.text(l.mobileGoalStop), findsOneWidget);
    expect(find.text(l.mobileGoalResume), findsNothing);
    expect(find.text(l.goalApprove), findsNothing);

    await tapLabel(tester, l.mobileGoalPause);
    expect(rpc().ops, ['agentGoalRuns.pause']);
    expect(rpc().sent.single.args, {'workspace_id': ws, 'goal_id': 'g1'});
  });

  testWidgets('cancel asks first, then sends agentGoalRuns.cancel', (
    tester,
  ) async {
    await pump(tester, _goal());
    await tapLabel(tester, l.mobileGoalStop);
    expect(find.text(l.mobileGoalStopConfirm), findsOneWidget);
    expect(rpc().ops, isEmpty);
    await tapLabel(tester, l.mobileGoalStop);
    expect(rpc().ops, ['agentGoalRuns.cancel']);
  });

  testWidgets('a goal in review offers approval behind the confirm sheet', (
    tester,
  ) async {
    await pump(
      tester,
      _goal(status: AgentGoalStatus.paused, hold: GoalHold.needsReview),
    );
    expect(find.text(l.goalHoldNeedsReview), findsOneWidget);
    await tapLabel(tester, l.goalApprove);
    expect(find.text(l.goalApproveBody), findsOneWidget);
    await tapLabel(tester, l.goalApproveConfirm);
    expect(rpc().ops, ['agentGoalRuns.approveCompletion']);
  });

  testWidgets('approval is offered only when the server says this viewer may '
      'approve; otherwise it is disabled with the not-yours sentence', (
    tester,
  ) async {
    await pump(
      tester,
      _goal(status: AgentGoalStatus.paused, hold: GoalHold.needsReview),
      canApprove: false,
    );
    expect(find.text(l.goalApprove), findsOneWidget);
    expect(find.text(l.goalRefusalNotYours), findsOneWidget);
    await tester.tap(find.text(l.goalApprove));
    await tester.pumpAndSettle();
    expect(find.text(l.goalApproveBody), findsNothing);
    expect(rpc().ops, isEmpty);
  });

  testWidgets('the checker picker shows only to a viewer who may resume', (
    tester,
  ) async {
    final gone = _goal(
      status: AgentGoalStatus.paused,
      hold: GoalHold.person,
      holdDetail: 'checker_unavailable',
    );
    await pump(tester, gone);
    expect(find.text(l.goalChooseChecker), findsOneWidget);
    await pump(tester, gone, canResume: false);
    expect(find.text(l.goalChooseChecker), findsNothing);
  });

  testWidgets('resume and raising the budget only show when the server says '
      'this viewer may resume', (tester) async {
    await pump(
      tester,
      _goal(status: AgentGoalStatus.paused, hold: GoalHold.byPerson),
      canResume: false,
    );
    expect(find.text(l.goalHoldByPerson), findsOneWidget);
    expect(find.text(l.mobileGoalResume), findsNothing);
    expect(find.text(l.goalResumeNotYours), findsOneWidget);
    expect(find.text(l.mobileGoalStop), findsOneWidget);

    await pump(
      tester,
      _goal(
        status: AgentGoalStatus.budgetExhausted,
        costMicros: 10000000,
        costCapMicros: 10000000,
      ),
      canResume: false,
    );
    expect(find.text(l.goalHoldBudget), findsOneWidget);
    expect(find.textContaining(r'$20.00'), findsNothing);
    expect(find.text(l.goalResumeNotYours), findsOneWidget);
  });

  testWidgets('raising the budget resumes with the new cap', (tester) async {
    await pump(
      tester,
      _goal(
        status: AgentGoalStatus.budgetExhausted,
        costMicros: 10000000,
        costCapMicros: 10000000,
      ),
    );
    await tapLabel(tester, l.mobileGoalRaiseTo(r'$20.00'));
    await tapLabel(tester, l.mobileGoalRaiseBudget);
    expect(rpc().ops, ['agentGoalRuns.resume']);
    expect(rpc().sent.single.args['raise_cost_cap_micros'], 20000000);
  });

  testWidgets('a refusal shows its sentence, an unknown kind the generic '
      'lead-in with the kind', (tester) async {
    rpc().refuse = 'goal_not_yours';
    await pump(
      tester,
      _goal(status: AgentGoalStatus.paused, hold: GoalHold.byPerson),
    );
    await tapLabel(tester, l.mobileGoalResume);
    expect(find.text(l.goalRefusalNotYours), findsOneWidget);
    expect(find.textContaining('Refused in English'), findsNothing);

    rpc().refuse = 'goal_something_new';
    await tapLabel(tester, l.mobileGoalResume);
    expect(find.text(l.workRefusalUnknown), findsOneWidget);
    expect(find.text('goal_something_new'), findsOneWidget);
  });

  testWidgets('hold details: a broken check shows its command, a limit its '
      'parks, an unknown detail its raw text', (tester) async {
    await pump(
      tester,
      _goal(
        status: AgentGoalStatus.paused,
        hold: GoalHold.person,
        holdDetail: 'check_broken: npm test',
      ),
    );
    expect(find.text(l.goalHoldPerson), findsOneWidget);
    expect(find.text(l.goalHoldDetailCheckBroken), findsOneWidget);
    expect(find.text('npm test'), findsOneWidget);

    await pump(tester, _goal(hold: GoalHold.limit, parkCount: 3));
    expect(find.text(l.goalHoldLimit), findsOneWidget);
    expect(find.text(l.goalHoldLimitParks(3, 8)), findsOneWidget);

    await pump(
      tester,
      _goal(
        status: AgentGoalStatus.paused,
        hold: GoalHold.person,
        holdDetail: 'brand_new_detail',
      ),
    );
    expect(find.text(l.workKindUnknown), findsOneWidget);
    expect(find.text('brand_new_detail'), findsOneWidget);
  });

  testWidgets('the contract and the last verification, and who verified it', (
    tester,
  ) async {
    final verification = GoalVerification(
      round: 2,
      claimSummary: 'All checkout tests pass now.',
      checks: [
        GoalCheckResult(
          run: 'npm test',
          where: GoalCheckLocation.worktree,
          exitCode: 1,
          outputTail: '1 failing',
        ),
      ],
      verdict: GoalVerdict(
        verdict: GoalVerdictOutcome.fail,
        items: [
          GoalVerdictItem(
            criterion: 'Checkout works',
            state: GoalCriterionState.unmet,
            evidence: 'The test still fails.',
          ),
        ],
        concerns: ['Flaky network mock'],
      ),
      reviewerAgentId: 'a2',
      at: _at,
    );
    await pump(
      tester,
      _goal(
        contract: GoalContract(
          criteria: ['Checkout works'],
          checks: [GoalCheck(run: 'npm test')],
          boundaries: 'Only touch shop-ui',
        ),
        verification: verification,
      ),
    );
    expect(find.text(l.goalDoneMeans), findsOneWidget);
    expect(find.text('npm test'), findsNWidgets(2));
    expect(find.text('Only touch shop-ui'), findsOneWidget);
    expect(find.text(l.goalCheckFailed(1)), findsOneWidget);
    expect(find.text('1 failing'), findsOneWidget);
    expect(find.text(l.goalVerdictFail), findsOneWidget);
    expect(find.text(l.goalCriterionUnmet), findsOneWidget);
    expect(find.text('Flaky network mock'), findsOneWidget);
    expect(find.text(l.goalVerifiedBy('Reviewer')), findsOneWidget);

    await pump(
      tester,
      _goal(
        verification: GoalVerification(
          round: 1,
          claimSummary: 'Done.',
          reviewerAgentId: 'a1',
          at: _at,
        ),
      ),
    );
    expect(find.text(l.goalVerifiedBySelf), findsOneWidget);
  });

  testWidgets('a goal with no criteria shows its verdict as one row about the '
      'objective', (tester) async {
    await pump(
      tester,
      _goal(
        verification: GoalVerification(
          round: 1,
          claimSummary: 'Done.',
          verdict: GoalVerdict(
            verdict: GoalVerdictOutcome.pass,
            items: [
              GoalVerdictItem(
                criterion: goalReviewObjectiveCriterion,
                state: GoalCriterionState.met,
                evidence: 'The tests pass.',
              ),
            ],
          ),
          reviewerAgentId: 'a2',
          at: _at,
        ),
      ),
    );
    expect(find.text(l.goalVerdictObjective), findsOneWidget);
    expect(find.text(goalReviewObjectiveCriterion), findsNothing);
    expect(find.text(l.goalCriterionMet), findsOneWidget);
  });

  testWidgets('agent text is inert: a markdown summary renders as typed', (
    tester,
  ) async {
    await pump(tester, _goal(summary: '**bold** [link](https://x.test)'));
    expect(find.text('**bold** [link](https://x.test)'), findsOneWidget);
  });

  testWidgets('a viewer sees the goal without any controls', (tester) async {
    await pump(tester, _goal(), role: WorkspaceRole.viewer);
    expect(find.text(l.mobileGoalPause), findsNothing);
    expect(find.text(l.mobileGoalStop), findsNothing);
  });

  testWidgets('right to left: the hold line and controls lay out mirrored', (
    tester,
  ) async {
    await pump(
      tester,
      _goal(status: AgentGoalStatus.paused, hold: GoalHold.needsReview),
      direction: TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
    final hold = tester.getRect(find.text(l.goalHoldNeedsReview));
    final glyph = tester.getRect(find.byIcon(AppIcons.user));
    // The hold glyph leads the sentence, so under RTL it sits to its right.
    expect(glyph.left, greaterThanOrEqualTo(hold.right - 1));
  });
}
