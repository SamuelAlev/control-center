import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/orchestration/domain/ports/orchestration_cap_raiser.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_budget_gate.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_domain/features/pipelines/domain/templates/goal_pursue_config.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/orchestration/providers/orchestration_providers.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_config_editor.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_type_visuals.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_work_notices.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'long_work_harness.dart';

class _FakeRaiser implements OrchestrationCapRaiser {
  final calls = <String>[];

  /// Thrown by the next raise, then cleared.
  Object? refuse;

  @override
  Future<OrchestrationCapRaise> raiseCap(
    String workspaceId,
    String orchestrationId,
    int maxCostMicros,
  ) async {
    calls.add('$workspaceId:$orchestrationId:$maxCostMicros');
    if (refuse case final e?) {
      refuse = null;
      throw e;
    }
    return (oldMicros: 2000000, newMicros: maxCostMicros);
  }
}

void main() {
  group('the goal.pursue node type', () {
    test('ships in the library, an agent node with a target icon', () {
      final type = defaultNodeTypeLibrary().byId('goal.pursue')!;
      expect(type.defaultBodyKey, kGoalPursueBodyKey);
      expect(visualForNodeTypeId('goal.pursue').icon, AppIcons.target);
      // Dropped as is, only the agent is missing.
      expect(GoalPursueConfig.errorsOf(type.defaultConfig), [
        'goal.pursue needs an agentId: the agent that pursues it',
      ]);
    });

    test('unknown ids still fall back to the plain node glyph', () {
      expect(visualForNodeTypeId('nope').icon, AppIcons.circle);
    });
  });

  group('the goal node editor', () {
    late PipelineStepDefinition latest;

    Future<AppLocalizations> pump(WidgetTester tester) async {
      final type = defaultNodeTypeLibrary().byId('goal.pursue')!;
      final step = PipelineStepDefinition(
        id: 'goal-step',
        kind: StepKind.listen,
        bodyKey: kGoalPursueBodyKey,
        config: type.defaultConfig,
      );
      latest = step;
      await pumpLongWork(
        tester,
        NodeConfigEditor(
          step: step,
          allSteps: [step],
          workspaceAgents: testAgents,
          workspaceRepos: const [],
          onChange: (s) => latest = s,
          onDelete: () {},
        ),
        overrides: longWorkOverrides(),
      );
      return AppLocalizations.of(tester.element(find.byType(NodeConfigEditor)));
    }

    testWidgets('shows objective, budget, caps, contract and what is missing', (
      tester,
    ) async {
      final l = await pump(tester);
      expect(find.text(l.nodeConfigObjective), findsOneWidget);
      expect(find.text(l.nodeConfigAgent), findsOneWidget);
      expect(find.text(l.goalNodeNeedsAgent), findsOneWidget);
      expect(find.text(l.goalNodeNeedsObjective), findsNothing);
      expect(find.text(l.goalNodeContract), findsOneWidget);
    });

    testWidgets('writes valid numbers into the extras and flags bad ones', (
      tester,
    ) async {
      final l = await pump(tester);
      await tester.enterText(
        find.byKey(const ValueKey('goal-node-budget')),
        '12.5',
      );
      await tester.enterText(
        find.byKey(const ValueKey('goal-node-max-runs')),
        '40',
      );
      await tester.pumpAndSettle();
      expect(latest.config.extras['budgetMicros'], 12500000);
      expect(latest.config.extras['maxRuns'], 40);

      await tester.enterText(
        find.byKey(const ValueKey('goal-node-deadline')),
        '9999',
      );
      await tester.pumpAndSettle();
      expect(find.text(l.goalNodeRange(2160)), findsOneWidget);
      expect(latest.config.extras.containsKey('deadlineHours'), isFalse);

      await tester.enterText(
        find.byKey(const ValueKey('goal-node-budget')),
        '',
      );
      await tester.pumpAndSettle();
      expect(find.text(l.goalNodeBudgetRange(1000)), findsOneWidget);
    });

    testWidgets('a criterion lands in the node contract', (tester) async {
      final l = await pump(tester);
      await tester.tap(find.text(l.goalContractAddCriterion));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('goal-criterion-0')),
        'The notes list every PR',
      );
      await tester.pumpAndSettle();
      expect(latest.config.extras['contract'], {
        'criteria': ['The notes list every PR'],
        'checks': <Object?>[],
      });
    });
  });

  group('run notices', () {
    PipelineRun run(Map<String, dynamic> state) => PipelineRun(
      id: 'run-1',
      templateId: 'tpl-1',
      workspaceId: kTestWorkspaceId,
      status: PipelineRunStatus.suspended,
      state: state,
      startedAt: t0,
    );

    testWidgets('nothing when the run waits on neither', (tester) async {
      await pumpLongWork(
        tester,
        PipelineRunWorkNotices(run: run(const {})),
        overrides: longWorkOverrides(),
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('a goal step links to the goal page', (tester) async {
      await pumpLongWork(
        tester,
        PipelineRunWorkNotices(run: run({goalPursueStateKey('s1'): 'goal-1'})),
        overrides: longWorkOverrides(
          goalViews: [GoalRunView(goal: goalFixture(), canResume: true, canApprove: true)],
        ),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(PipelineRunWorkNotices)),
      );
      expect(find.text(l.pipelineRunGoalStep('s1')), findsOneWidget);
      expect(find.text(l.pipelineRunOpenGoal), findsOneWidget);
      expect(find.text(l.goalRunStatusActive), findsOneWidget);
    });

    PipelineRun held({bool? canRaiseCap}) => PipelineRun(
      id: 'run-1',
      templateId: 'tpl-1',
      workspaceId: kTestWorkspaceId,
      status: PipelineRunStatus.suspended,
      state: {
        kBudgetHoldStateKey: {
          'reason': kOrchestrationBudgetHoldReason,
          'orchestration_id': 'orch-1',
          'cap_micros': 2000000,
          'spent_micros': 2100000,
          'held_at': t0.toIso8601String(),
        },
      },
      startedAt: t0,
      canRaiseCap: canRaiseCap,
    );

    Future<AppLocalizations> pumpHold(
      WidgetTester tester,
      _FakeRaiser raiser, {
      bool? canRaiseCap = true,
      TextDirection textDirection = TextDirection.ltr,
    }) async {
      await pumpLongWork(
        tester,
        PipelineRunWorkNotices(run: held(canRaiseCap: canRaiseCap)),
        overrides: [
          ...longWorkOverrides(),
          orchestrationCapRaiserProvider.overrideWithValue(raiser),
        ],
        textDirection: textDirection,
      );
      return AppLocalizations.of(
        tester.element(find.byType(PipelineRunWorkNotices)),
      );
    }

    Future<void> enter(WidgetTester tester, String dollars) async {
      await tester.enterText(
        find.byKey(const ValueKey('raise-cap-dollars')),
        dollars,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a budget hold explains itself and raises through raiseCap', (
      tester,
    ) async {
      final raiser = _FakeRaiser();
      final l = await pumpHold(tester, raiser);
      expect(find.text(l.pipelineRunHeldBudget), findsOneWidget);
      expect(find.textContaining(r'$2.10'), findsOneWidget);
      await tester.tap(find.text(l.pipelineRunRaiseCap));
      await tester.pumpAndSettle();
      // Upward only: not above what was spent, and at most $1,000.
      await enter(tester, '2');
      expect(find.text(l.raiseCapMustExceed(r'$2.10')), findsOneWidget);
      await enter(tester, '1001');
      expect(find.text(l.raiseCapAtMost(r'$1,000.00')), findsOneWidget);
      await enter(tester, '10');
      await tester.tap(find.text(l.raiseCapConfirm).last);
      await tester.pumpAndSettle();
      expect(raiser.calls, ['$kTestWorkspaceId:orch-1:10000000']);
      expect(find.byType(CcDialog), findsNothing);
    });

    testWidgets('only a viewer the server allows sees Raise cap', (
      tester,
    ) async {
      for (final allowed in [false, null]) {
        final l = await pumpHold(tester, _FakeRaiser(), canRaiseCap: allowed);
        expect(find.text(l.pipelineRunHeldBudget), findsOneWidget);
        expect(find.text(l.pipelineRunRaiseCap), findsNothing);
      }
    });

    testWidgets('a lost race shows the fresh cap and checks against it', (
      tester,
    ) async {
      final raiser = _FakeRaiser()
        ..refuse = RemoteRpcException(-32009, 'changed', {
          'kind': 'orchestration_cap_changed',
          'max_cost_micros': 15000000,
        });
      final l = await pumpHold(tester, raiser);
      await tester.tap(find.text(l.pipelineRunRaiseCap));
      await tester.pumpAndSettle();
      await enter(tester, '10');
      await tester.tap(find.text(l.raiseCapConfirm).last);
      await tester.pumpAndSettle();
      expect(find.byType(CcDialog), findsOneWidget);
      expect(find.text(l.orchestrationRefusalCapChanged), findsOneWidget);
      expect(find.text(l.raiseCapNowAt(r'$15.00')), findsOneWidget);
      expect(find.text(l.raiseCapMustExceed(r'$15.00')), findsOneWidget);
      await enter(tester, '20');
      await tester.tap(find.text(l.raiseCapConfirm).last);
      await tester.pumpAndSettle();
      expect(raiser.calls.last, '$kTestWorkspaceId:orch-1:20000000');
      expect(find.byType(CcDialog), findsNothing);
    });

    testWidgets('each refusal kind has its sentence; an unknown one its kind', (
      tester,
    ) async {
      final raiser = _FakeRaiser();
      final l = await pumpHold(tester, raiser);
      await tester.tap(find.text(l.pipelineRunRaiseCap));
      await tester.pumpAndSettle();
      for (final (kind, sentence) in [
        ('orchestration_not_yours', l.orchestrationRefusalNotYours),
        ('orchestration_cap_invalid', l.orchestrationRefusalCapInvalid),
        ('mystery_kind', '${l.workRefusalUnknown} mystery_kind'),
      ]) {
        raiser.refuse = refusal(kind);
        await tester.tap(find.text(l.raiseCapConfirm).last);
        await tester.pumpAndSettle();
        expect(find.text(sentence), findsOneWidget, reason: kind);
      }
    });

    testWidgets('right to left lays the hold and dialog out', (tester) async {
      final l = await pumpHold(
        tester,
        _FakeRaiser(),
        textDirection: TextDirection.rtl,
      );
      await tester.tap(find.text(l.pipelineRunRaiseCap));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CcDialog), findsOneWidget);
    });
  });
}
