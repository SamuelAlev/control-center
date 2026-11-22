@TestOn('browser')
library;

import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/plan_goal/goal_create.dart';
import 'package:cc_remote/widgets/plan_goal/schedule_create.dart';
import 'package:cc_remote/work_launcher.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

class _Launcher implements PhoneWorkLauncher {
  final goals = <({String agentId, String body, WorkTarget target})>[];
  String? runId = 'run1';
  Object? targetError;

  @override
  Future<WorkTarget> target({
    required String workspaceId,
    String? conversationId,
    String? spaceId,
  }) async {
    if (targetError != null) throw targetError!;
    return (spaceId: spaceId ?? 's1', conversationId: conversationId ?? 'c9');
  }

  @override
  Future<String?> startGoal({
    required String workspaceId,
    required WorkTarget target,
    required String agentId,
    required String body,
  }) async {
    goals.add((agentId: agentId, body: body, target: target));
    return runId;
  }
}

void main() {
  late AppLocalizations l;
  WorkRpcHost? host;
  // Made inside each test's zone, so its streams run on the test's clock.
  WorkRpcHost rpc() => host ??= WorkRpcHost();
  late _Launcher launcher;

  setUpAll(() async => l = await english());
  setUp(() {
    host = null;
    launcher = _Launcher();
  });
  tearDown(() => host?.close());

  Future<void> pump(WidgetTester tester, Widget child) => pumpWork(
    tester,
    child,
    overrides: [
      ...workOverrides(rpc(), spaces: [space('s1', 'Checkout')]),
      phoneWorkLauncherProvider.overrideWithValue(launcher),
    ],
  );

  Future<void> type(WidgetTester tester, int index, String text) async {
    final fields = find.byType(EditableText);
    await tester.ensureVisible(fields.at(index));
    await tester.enterText(fields.at(index), text);
    await tester.pump();
  }

  test('the body round-trips through the server parser', () {
    final body = phoneGoalCommandBody(
      objective: 'Make checkout fast',
      budgetMicros: 12500000,
      maxRuns: 4,
      checks: ['npm test -- --run "checkout"', '  ', 'make lint'],
    );
    final parsed = GoalCommand.parse(body);
    expect(parsed.budgetMicros, 12500000);
    expect(parsed.maxRuns, 4);
    expect(parsed.objective.trim(), 'Make checkout fast');
    expect(parsed.contract!.checks.map((c) => c.run), [
      'npm test -- --run "checkout"',
      'make lint',
    ]);
  });

  testWidgets('a goal: no kind picker; checks, budget and segment cap go '
      'into one /goal', (tester) async {
    await pump(tester, const PhoneGoalCreate(workspaceId: ws));
    await tapLabel(tester, 'Checkout');
    await tapLabel(tester, 'Builder');
    await type(tester, 0, 'Make checkout fast');
    await type(tester, 1, 'npm test');
    await tapLabel(tester, l.goalCreateAddCheck);
    await type(tester, 2, 'make lint');
    await type(tester, 3, '12.50');
    await type(tester, 4, '4');
    await tapLabel(tester, l.mobileGoalCreate);
    expect(find.text(l.mobileGoalCreateConfirm(r'$12.50')), findsOneWidget);
    await tapLabel(tester, l.mobileGoalCreate);
    expect(launcher.goals, hasLength(1));
    final sent = launcher.goals.single;
    expect(sent.agentId, 'a1');
    expect(sent.target, (spaceId: 's1', conversationId: 'c9'));
    final parsed = GoalCommand.parse(sent.body);
    expect(parsed.maxRuns, 4);
    expect(parsed.contract!.checks.map((c) => c.run), [
      'npm test',
      'make lint',
    ]);
    expect(find.text(l.mobileGoalCreateSent), findsOneWidget);
  });

  testWidgets('a body the parser refuses never leaves the phone', (
    tester,
  ) async {
    await pump(
      tester,
      const PhoneGoalCreate(workspaceId: ws, conversationId: 'c1'),
    );
    await tapLabel(tester, 'Builder');
    await type(tester, 0, 'Ship it --bogus');
    await type(tester, 2, '5');
    await tapLabel(tester, l.mobileGoalCreate);
    expect(find.text(l.goalRefusalCommandInvalid), findsOneWidget);
    expect(launcher.goals, isEmpty);
  });

  testWidgets('a bad segment cap and a server refusal show sentences', (
    tester,
  ) async {
    await pump(
      tester,
      const PhoneGoalCreate(workspaceId: ws, conversationId: 'c1'),
    );
    await tapLabel(tester, 'Builder');
    await type(tester, 0, 'Ship it');
    await type(tester, 2, '5');
    await type(tester, 3, '0');
    await tapLabel(tester, l.mobileGoalCreate);
    expect(find.text(l.goalCreateSegmentInvalid), findsOneWidget);

    await type(tester, 3, '');
    launcher.runId = null;
    await tapLabel(tester, l.mobileGoalCreate);
    await tapLabel(tester, l.mobileGoalCreate);
    expect(find.text(l.mobileGoalStartRefused), findsOneWidget);
  });

  testWidgets('a schedule every N minutes goes to wakeRules.create', (
    tester,
  ) async {
    await pump(
      tester,
      const PhoneScheduleCreate(workspaceId: ws, conversationId: 'c1'),
    );
    await tapLabel(tester, 'Builder');
    await type(tester, 0, '45');
    await type(tester, 1, 'Check the api-server deploy');
    await type(tester, 2, '3');
    await type(tester, 3, '7');
    await tapLabel(tester, l.scheduleCreateButton);
    expect(find.text(l.scheduleCreateConfirmEveryMinutes(45)), findsOneWidget);
    await tapLabel(tester, l.scheduleCreateButton);
    expect(rpc().ops, ['wakeRules.create']);
    final args = rpc().sent.single.args;
    expect(args['workspace_id'], ws);
    expect(args['conversation_id'], 'c1');
    expect(args['agent_id'], 'a1');
    expect(args['when'], 'every:45m');
    expect(args['note'], 'Check the api-server deploy');
    expect(args['cost_cap_micros'], 3000000);
    expect(args['expires_in'], '7d');
    expect(args['fire_now'], true);
  });

  testWidgets('a self-paced schedule sends next; a refusal shows its '
      'sentence', (tester) async {
    rpc().refuse = 'wake_limit_reached';
    await pump(
      tester,
      const PhoneScheduleCreate(workspaceId: ws, conversationId: 'c1'),
    );
    await tapLabel(tester, 'Builder');
    await tapLabel(tester, l.scheduleSelfPaced);
    expect(find.text(l.scheduleSelfPacedHint), findsOneWidget);
    await type(tester, 0, 'Keep going');
    await tapLabel(tester, l.scheduleCreateButton);
    await tapLabel(tester, l.scheduleCreateButton);
    expect(rpc().sent.single.args['when'], 'next');
    expect(find.text(l.wakeRuleRefusalLimitReached), findsOneWidget);
  });
}
