import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_checks_editor.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_contract_editor.dart';
import 'package:control_center/features/dispatch/presentation/widgets/goals/goal_launch_options.dart';
import 'package:control_center/features/messaging/presentation/widgets/guided_goal_dialog.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'long_work_harness.dart';

void main() {
  group('contract editor limits', () {
    late GoalContract? contract;
    late bool valid;

    Future<AppLocalizations> pump(
      WidgetTester tester,
      GoalContract? initial,
    ) async {
      await pumpLongWork(
        tester,
        SingleChildScrollView(
          child: GoalContractEditor(
            initial: initial,
            onChanged: (c, v) {
              contract = c;
              valid = v;
            },
          ),
        ),
        overrides: longWorkOverrides(),
      );
      return AppLocalizations.of(
        tester.element(find.byType(GoalContractEditor)),
      );
    }

    CcButton button(WidgetTester tester, String label) =>
        tester.widget<CcButton>(
          find.ancestor(of: find.text(label), matching: find.byType(CcButton)),
        );

    testWidgets('at most 12 criteria', (tester) async {
      final l = await pump(
        tester,
        GoalContract(criteria: [for (var i = 0; i < 11; i++) 'Criterion $i']),
      );
      expect(button(tester, l.goalContractAddCriterion).onPressed, isNotNull);
      await tester.tap(find.text(l.goalContractAddCriterion));
      await tester.pumpAndSettle();
      expect(button(tester, l.goalContractAddCriterion).onPressed, isNull);
      expect(find.text(l.goalContractCriteriaFull(12)), findsOneWidget);
    });

    testWidgets('a criterion holds at most 300 characters', (tester) async {
      await pump(tester, GoalContract(criteria: ['Short']));
      await tester.enterText(
        find.byKey(const ValueKey('goal-criterion-0')),
        'x' * 320,
      );
      await tester.pumpAndSettle();
      expect(valid, isTrue);
      expect(contract?.criteria.single.length, 300);
    });

    testWidgets('at most 5 checks, each up to 1,800 seconds', (tester) async {
      final l = await pump(
        tester,
        GoalContract(
          checks: [for (var i = 0; i < 4; i++) GoalCheck(run: 'make t$i')],
        ),
      );
      await tester.tap(find.text(l.goalContractAddCheck));
      await tester.pumpAndSettle();
      expect(button(tester, l.goalContractAddCheck).onPressed, isNull);
      expect(find.text(l.goalContractChecksFull(5)), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('goal-check-timeout-0')),
        '1801',
      );
      await tester.pumpAndSettle();
      expect(valid, isFalse);
      expect(find.text(l.goalContractTimeoutRange(1800)), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('goal-check-timeout-0')),
        '1800',
      );
      await tester.pumpAndSettle();
      expect(find.byType(GoalChecksEditor), findsOneWidget);
    });
  });

  group('composeGoalBody', () {
    test(
      'flags first, objective, then the checks section the server reads',
      () {
        final body = composeGoalBody(
          'Ship the release notes',
          GoalLaunchChoice(
            checks: [GoalCheck(run: 'make check', timeoutSeconds: 600)],
            checkerAgentId: 'agent-2',
            fresh: true,
            assume: true,
          ),
        );
        expect(
          body,
          startsWith('--checker agent-2 --fresh --unattended assume Ship'),
        );
        final parsed = GoalCommand.parse(body);
        expect(parsed.objective, 'Ship the release notes');
        expect(parsed.checkerRef, 'agent-2');
        expect(parsed.fresh, isTrue);
        expect(parsed.contract?.checks.single.run, 'make check');
        expect(parsed.contract?.checks.single.timeoutSeconds, 600);
      },
    );

    test('a flag the objective already carries is not repeated', () {
      final body = composeGoalBody(
        '--fresh Ship it',
        const GoalLaunchChoice(fresh: true),
      );
      expect(GoalCommand.parse(body).fresh, isTrue);
      expect('--fresh'.allMatches(body), hasLength(1));
    });

    test('no choice leaves the objective as written', () {
      expect(composeGoalBody('Ship it', const GoalLaunchChoice()), 'Ship it');
    });
  });

  testWidgets('the guided dialog adds the checker and options to the body', (
    tester,
  ) async {
    String? result;
    await pumpLongWork(
      tester,
      Builder(
        builder: (context) => CcButton(
          onPressed: () async {
            result = await showCcDialog<String>(
              context: context,
              builder: (_) => GuidedGoalDialog(
                rough: 'ship notes',
                goalAgentId: 'agent-1',
                step: (_) async =>
                    const GuidedGoalStepResult(objective: 'Ship the notes'),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
      overrides: longWorkOverrides(),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(
      tester.element(find.byType(GuidedGoalDialog)),
    );
    expect(find.text(l.goalCheckerNoneWeaker), findsOneWidget);
    await tester.tap(find.text(l.goalCheckerNone));
    await tester.pumpAndSettle();
    // The goal's own agent (Rex) is not a choice.
    expect(find.text('Rex'), findsNothing);
    await tester.tap(find.text('Ada').last);
    await tester.pumpAndSettle();
    expect(find.text(l.goalCheckerRecommend('Ada')), findsOneWidget);
    await tester.tap(find.text(l.goalLaunchFresh));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CcCheckbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.guidedGoalStart));
    await tester.pumpAndSettle();
    expect(result, '--checker agent-2 --fresh Ship the notes');
  });
}
