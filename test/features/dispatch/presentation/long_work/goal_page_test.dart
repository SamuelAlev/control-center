import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'long_work_harness.dart';

GoalVerification _verification() => GoalVerification(
  round: 2,
  claimSummary: 'The changelog lists every merged PR',
  checks: [
    GoalCheckResult(
      run: 'make changelog-check',
      where: GoalCheckLocation.worktree,
      exitCode: 1,
      outputTail: 'missing entry for #42',
    ),
  ],
  verdict: GoalVerdict(
    verdict: GoalVerdictOutcome.fail,
    items: [
      GoalVerdictItem(
        criterion: 'Every merged PR is listed',
        state: GoalCriterionState.unmet,
      ),
    ],
  ),
  reviewerAgentId: 'agent-2',
  at: t0,
);

void main() {
  late FakeGoalWrites repo;

  setUp(() => repo = FakeGoalWrites());

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(GoalPage)));

  Future<void> pump(
    WidgetTester tester,
    List<GoalRunView>? views, {
    Object? error,
    bool openContractEditor = false,
    TextDirection? textDirection,
  }) => pumpLongWork(
    tester,
    GoalPage(
      workspaceId: kTestWorkspaceId,
      goalId: 'goal-1',
      openContractEditor: openContractEditor,
    ),
    overrides: longWorkOverrides(
      goals: repo,
      goalViews: views,
      goalsError: error,
    ),
    textDirection: textDirection,
    settle: views != null || error != null,
  );

  GoalRunView view(AgentGoalStatus status, {GoalHold? hold, bool can = true}) =>
      GoalRunView(
        goal: goalFixture(
          status: status,
          hold: hold,
          noProgressStreak: 2,
          verification: _verification(),
          contract: GoalContract(criteria: ['Every merged PR is listed']),
        ),
        canResume: can,
        canApprove: true,
      );

  testWidgets('loading shows a spinner', (tester) async {
    await pump(tester, null);
    expect(find.byType(CcSpinner), findsWidgets);
  });

  testWidgets('a refusal shows its sentence with the unknown kind', (
    tester,
  ) async {
    await pump(tester, null, error: refusal('mystery_kind'));
    expect(find.textContaining('mystery_kind'), findsOneWidget);
  });

  testWidgets('a missing goal says so', (tester) async {
    await pump(tester, const []);
    expect(find.text(l10n(tester).goalNotFound), findsOneWidget);
  });

  testWidgets('a populated goal: objective, facts, verification, reviewer', (
    tester,
  ) async {
    await pump(tester, [view(AgentGoalStatus.active)]);
    final l = l10n(tester);
    expect(find.text('Keep the changelog current'), findsWidgets);
    expect(find.text(l.goalFactNoProgress), findsOneWidget);
    expect(find.textContaining('make changelog-check'), findsWidgets);
    expect(find.textContaining('missing entry for #42'), findsOneWidget);
    expect(find.textContaining('Every merged PR is listed'), findsWidgets);
    expect(find.textContaining('Ada'), findsWidgets);
  });

  testWidgets('pause sends agentGoalRuns pause', (tester) async {
    await pump(tester, [view(AgentGoalStatus.active)]);
    await tester.tap(find.text(l10n(tester).goalRunPause));
    await tester.pumpAndSettle();
    expect(repo.calls, ['pause:$kTestWorkspaceId:goal-1']);
  });

  testWidgets('resume is the starter\'s; a stranger sees it disabled', (
    tester,
  ) async {
    await pump(tester, [view(AgentGoalStatus.paused, can: false)]);
    final button = tester.widget<CcButton>(
      find.ancestor(
        of: find.text(l10n(tester).goalRunResume),
        matching: find.byType(CcButton),
      ),
    );
    expect(button.onPressed, isNull);
    await pump(tester, [view(AgentGoalStatus.paused)]);
    await tester.tap(find.text(l10n(tester).goalRunResume));
    await tester.pumpAndSettle();
    expect(repo.calls, ['resume:$kTestWorkspaceId:goal-1:null']);
  });

  testWidgets('approve shows only in review and confirms first', (
    tester,
  ) async {
    await pump(tester, [view(AgentGoalStatus.active)]);
    expect(find.text(l10n(tester).goalCardApprove), findsNothing);
    await pump(tester, [
      view(AgentGoalStatus.paused, hold: GoalHold.needsReview),
    ]);
    final l = l10n(tester);
    await tester.tap(find.text(l.goalCardApprove));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    await tester.tap(find.text(l.goalCardApproveConfirm));
    await tester.pump();
    expect(repo.calls, ['approve:$kTestWorkspaceId:goal-1']);
  });

  testWidgets('stop confirms, then cancels the goal', (tester) async {
    await pump(tester, [view(AgentGoalStatus.active)]);
    final l = l10n(tester);
    await tester.tap(find.text(l.goalRunStop));
    await tester.pumpAndSettle();
    expect(find.text(l.goalStopTitle), findsOneWidget);
    await tester.tap(find.text(l.goalRunStop).last);
    await tester.pumpAndSettle();
    expect(repo.calls, ['cancel:$kTestWorkspaceId:goal-1']);
  });

  testWidgets('the contract is edited only while paused', (tester) async {
    await pump(tester, [view(AgentGoalStatus.active)]);
    final edit = find.ancestor(
      of: find.text(l10n(tester).goalContractEdit),
      matching: find.byType(CcButton),
    );
    expect(tester.widget<CcButton>(edit).onPressed, isNull);

    await pump(tester, [view(AgentGoalStatus.paused)]);
    await tester.tap(find.text(l10n(tester).goalContractEdit));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('goal-criterion-0')),
      'Every merged PR is listed with its number',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).save));
    await tester.pumpAndSettle();
    expect(repo.calls, ['setContract:goal-1:1']);
    expect(repo.contract?.criteria, [
      'Every merged PR is listed with its number',
    ]);
  });

  testWidgets('?edit=contract opens the editor on a paused goal', (
    tester,
  ) async {
    await pump(tester, [
      view(AgentGoalStatus.paused),
    ], openContractEditor: true);
    expect(find.text(l10n(tester).goalContractEditTitle), findsOneWidget);
  });

  testWidgets('the checker is set through setChecker', (tester) async {
    await pump(tester, [view(AgentGoalStatus.paused)]);
    final l = l10n(tester);
    await tester.tap(find.text(l.goalCheckerChange));
    await tester.pumpAndSettle();
    expect(find.text(l.goalCheckerRecommend('Ada')), findsNothing);
    await tester.tap(find.text(l.goalCheckerNone).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ada').last);
    await tester.pumpAndSettle();
    expect(find.text(l.goalCheckerRecommend('Ada')), findsOneWidget);
    await tester.tap(find.text(l.save));
    await tester.pumpAndSettle();
    expect(repo.calls, ['setChecker:goal-1:agent-2']);
  });

  testWidgets('right to left lays the page out without errors', (tester) async {
    await pump(tester, [
      view(AgentGoalStatus.paused),
    ], textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    expect(find.text('Keep the changelog current'), findsWidgets);
  });

  testWidgets('a goal paused on usage limits says so on the page', (
    tester,
  ) async {
    final parked = GoalRunView(
      goal: goalFixture(
        status: AgentGoalStatus.paused,
        hold: GoalHold.needsReview,
      ).copyWith(holdDetail: 'limit_parks'),
      canResume: true,
      canApprove: true,
    );
    await pump(tester, [parked]);
    final l = l10n(tester);
    expect(find.text(l.goalHoldDetailLimitParks), findsOneWidget);
  });

  testWidgets('a waiting goal names when the server looks again', (
    tester,
  ) async {
    final waiting = GoalRunView(
      goal: goalFixture(hold: GoalHold.waiting).copyWith(holdUntil: later),
      canResume: true,
      canApprove: true,
    );
    await pump(tester, [waiting]);
    // The page's "next" line; the status line above it has its own words.
    expect(find.textContaining('or looks again at'), findsOneWidget);
  });

  String? tipOf(WidgetTester tester, String label) => tester
      .widget<WorkTip>(
        find.ancestor(of: find.text(label), matching: find.byType(WorkTip)),
      )
      .message;

  CcButton buttonOf(WidgetTester tester, String label) =>
      tester.widget<CcButton>(
        find.ancestor(of: find.text(label), matching: find.byType(CcButton)),
      );

  testWidgets('approve completion is offered only to whoever may close it', (
    tester,
  ) async {
    final review = goalFixture(
      status: AgentGoalStatus.paused,
      hold: GoalHold.needsReview,
    );
    await pump(tester, [
      GoalRunView(goal: review, canResume: true, canApprove: false),
    ]);
    final l = l10n(tester);
    expect(buttonOf(tester, l.goalCardApprove).onPressed, isNull);
    expect(tipOf(tester, l.goalCardApprove), l.goalCardApproveNotYours);
    await tester.tap(find.text(l.goalCardApprove));
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);

    await pump(tester, [
      GoalRunView(goal: review, canResume: false, canApprove: true),
    ]);
    expect(buttonOf(tester, l.goalCardApprove).onPressed, isNotNull);
    expect(tipOf(tester, l.goalCardApprove), isNull);
  });

  testWidgets('contract and checker change only for whoever may resume it', (
    tester,
  ) async {
    await pump(tester, [view(AgentGoalStatus.paused, can: false)]);
    final l = l10n(tester);
    for (final label in [l.goalContractEdit, l.goalCheckerChange]) {
      expect(buttonOf(tester, label).onPressed, isNull);
      expect(tipOf(tester, label), l.goalRefusalNotYours);
    }
    await tester.tap(find.text(l.goalContractEdit));
    await tester.pumpAndSettle();
    expect(find.text(l.goalContractEditTitle), findsNothing);
  });

  testWidgets('?edit=contract does not open for someone who may not edit', (
    tester,
  ) async {
    await pump(tester, [
      view(AgentGoalStatus.paused, can: false),
    ], openContractEditor: true);
    expect(find.text(l10n(tester).goalContractEditTitle), findsNothing);
  });

  GoalRunView objectiveOnly() => GoalRunView(
    goal: goalFixture(
      status: AgentGoalStatus.paused,
      verification: GoalVerification(
        round: 1,
        claimSummary: 'Done',
        claimEvidence: [
          GoalClaimEvidence(criterion: 'the objective', evidence: 'All green'),
        ],
        verdict: GoalVerdict(
          verdict: GoalVerdictOutcome.pass,
          items: [
            GoalVerdictItem(
              criterion: 'the objective',
              state: GoalCriterionState.met,
            ),
          ],
        ),
        reviewerAgentId: 'agent-2',
        at: t0,
      ),
    ),
    canResume: true,
    canApprove: true,
  );

  testWidgets('no contract says there is no machine check', (tester) async {
    await pump(tester, [objectiveOnly()]);
    final l = l10n(tester);
    expect(find.text(l.goalContractNone), findsOneWidget);
    expect(find.text(l.goalCardNoMachineCheck), findsOneWidget);
  });

  testWidgets('a verdict on the objective alone is one row about it', (
    tester,
  ) async {
    await pump(tester, [objectiveOnly()]);
    final l = l10n(tester);
    expect(
      find.text(l.goalVerdictItem(l.goalCardObjective, l.goalCardCriterionMet)),
      findsOneWidget,
    );
    expect(find.textContaining('the objective'), findsNothing);
  });

  testWidgets('the new states lay out right to left', (tester) async {
    await pump(tester, [objectiveOnly()], textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    await pump(tester, [
      GoalRunView(
        goal: goalFixture(
          status: AgentGoalStatus.paused,
          hold: GoalHold.needsReview,
        ),
        canResume: false,
        canApprove: false,
      ),
    ], textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final l = l10n(tester);
    expect(buttonOf(tester, l.goalCardApprove).onPressed, isNull);
  });
}
