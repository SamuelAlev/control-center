@TestOn('!windows')
library;

import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:test/test.dart';

/// What `bash` reports as a wait on a person, and which script its cards
/// name: only a real ask counts, whether the runner, the action guard or the
/// agent run gateway (through [CommandWaitRelay]) asks.
void main() {
  late Directory cwd;
  late _Rules rules;
  late _Approver approver;
  late RunScriptOrigins origins;
  late List<GuardAudit> audits;

  setUp(() {
    audits = [];
    cwd = Directory.systemTemp.createTempSync('harness_wait_');
    rules = _Rules();
    approver = _Approver();
    origins = RunScriptOrigins(runId: 'run-1');
  });
  tearDown(() => cwd.deleteSync(recursive: true));

  SandboxedHarnessCommandRunner runner({
    bool guarded = true,
    CommandWaitRelay? callWaits,
    ToolProcessLauncher hostProcesses = const HostToolProcessLauncher(),
  }) => SandboxedHarnessCommandRunner(
    mode: Mode.chat,
    networkEnabled: false,
    confirmationPort: approver,
    actionGuard: guarded
        ? ActionGuardService(
            repository: rules,
            confirmationPort: approver,
            onAudit: audits.add,
          )
        : null,
    hostProcesses: hostProcesses,
    workspaceId: 'ws',
    agentId: 'a',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    scriptOrigins: origins,
    callWaits: callWaits,
  );

  group('the action guard', () {
    test('a guarded command nobody is asked about reports no wait', () async {
      rules.add(ActionDecision.allow);
      final reports = <bool>[];

      final res = await runner().run(
        'echo hello',
        workdir: cwd.path,
        personWait: reports.add,
      );

      expect(res.exitCode, 0);
      expect(reports, isEmpty);
      expect(approver.requests, isEmpty);
    });

    test('a guarded command a rule denies reports no wait', () async {
      rules.add(ActionDecision.deny);
      final reports = <bool>[];

      final res = await runner().run(
        'echo hello',
        workdir: cwd.path,
        personWait: reports.add,
      );

      expect(res.denied, isTrue);
      expect(reports, isEmpty);
    });

    test('a prompted command reports one wait around the ask, and its card '
        'names the script\'s running execution', () async {
      rules.add(ActionDecision.prompt);
      origins.begin('toolu_repl', 'run-1/toolu_repl#2');
      // How many cards had been shown at each report.
      final reports = <(bool, int)>[];

      final res = await runner().run(
        'echo hello',
        workdir: cwd.path,
        personWait: (waiting) =>
            reports.add((waiting, approver.requests.length)),
        parentToolCallId: 'toolu_repl',
      );

      expect(res.exitCode, 0);
      expect(reports, [(true, 0), (false, 1)]);
      expect(
        approver.requests.single.origin,
        ScriptCallOrigin(
          parentToolCallId: 'toolu_repl',
          executionId: 'run-1/toolu_repl#2',
        ),
      );
    });

    test('the model\'s own command has a card with no origin', () async {
      rules.add(ActionDecision.prompt);

      await runner().run('echo hello', workdir: cwd.path);

      expect(approver.requests.single.origin, isNull);
    });
  });

  test('the command net\'s own card names the script too', () async {
    final reports = <bool>[];
    approver.answer = false;

    await runner(guarded: false).run(
      'npm publish',
      workdir: cwd.path,
      personWait: reports.add,
      parentToolCallId: 'toolu_repl',
    );

    expect(reports, [true, false]);
    expect(
      approver.requests.single.origin,
      ScriptCallOrigin(parentToolCallId: 'toolu_repl'),
      reason: 'no execution registered: the card names none',
    );
  });

  group('a script\'s command', () {
    test('answered yes after its call was cancelled never runs', () async {
      rules.add(ActionDecision.prompt);
      final marker = File('${cwd.path}/ran');
      final cancel = CancellationTokenSource();
      approver
        ..delay = const Duration(milliseconds: 80)
        ..onAsk = () => cancel.cancel('the script stopped waiting');

      final res = await runner().run(
        'touch ran',
        workdir: cwd.path,
        cancel: cancel.token,
        parentToolCallId: 'toolu_repl',
      );

      expect(approver.requests.single.withdrawn, isNotNull);
      expect(res.denied, isTrue);
      expect(res.stderr, startsWith('Command cancelled before it ran'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(marker.existsSync(), isFalse);
      // A late yes is nobody's answer: the script was not declined.
      expect(origins.approvalsOf('toolu_repl').declined, isFalse);
    });

    test(
      'the net\'s card answered yes after cancellation never runs',
      () async {
        final cancel = CancellationTokenSource();
        approver
          ..delay = const Duration(milliseconds: 80)
          ..onAsk = () => cancel.cancel('the script stopped waiting');

        final res = await runner(guarded: false).run(
          'npm publish',
          workdir: cwd.path,
          cancel: cancel.token,
          parentToolCallId: 'toolu_repl',
        );

        expect(approver.requests.single.withdrawn, isNotNull);
        expect(res.denied, isTrue);
        expect(res.stderr, startsWith('Command cancelled before it ran'));
      },
    );

    test('after a declined card, the next that needs a person is refused '
        'without asking; a command nobody is asked about still runs', () async {
      rules.add(ActionDecision.prompt);
      origins.begin('toolu_repl', 'run-1/toolu_repl');
      approver.answer = false;

      await runner().run(
        'echo one',
        workdir: cwd.path,
        parentToolCallId: 'toolu_repl',
      );
      approver.answer = true;
      final second = await runner().run(
        'echo two',
        workdir: cwd.path,
        parentToolCallId: 'toolu_repl',
      );
      final net = await runner(
        guarded: false,
      ).run('npm publish', workdir: cwd.path, parentToolCallId: 'toolu_repl');

      expect(second.denied, isTrue);
      expect(second.stderr, contains('already declined'));
      // Audited as the denial nobody was asked about, with its true reason.
      final refusedAudit = audits.lastWhere(
        (a) => a.actionSummary.contains('echo two'),
      );
      expect(refusedAudit.decision, ActionDecision.deny);
      expect(refusedAudit.prompted, isFalse);
      expect(refusedAudit.reason, contains('already declined'));
      expect(net.denied, isTrue);
      expect(approver.requests, hasLength(1));

      final plain = await runner(
        guarded: false,
      ).run('echo three', workdir: cwd.path, parentToolCallId: 'toolu_repl');
      expect(plain.stdout.trim(), 'three');
    });

    test('a card nobody answered is no person\'s verdict, on the guard\'s '
        'card and the command net\'s, and is audited apart from a decline; '
        'the script\'s next command asks again', () async {
      rules.add(ActionDecision.prompt);
      origins.begin('toolu_repl', 'run-1/toolu_repl');
      approver.unanswered = true;

      final guarded = await runner().run(
        'echo one',
        workdir: cwd.path,
        parentToolCallId: 'toolu_repl',
      );
      expect(guarded.denied, isTrue);
      expect(guarded.personVerdict, isNull);
      expect(guarded.stderr, contains('Nobody answered'));
      expect(audits.last.prompted, isTrue);
      expect(audits.last.unanswered, isTrue);

      final net = await runner(
        guarded: false,
      ).run('npm publish', workdir: cwd.path, parentToolCallId: 'toolu_repl');
      expect(net.denied, isTrue);
      expect(net.personVerdict, isNull);
      expect(net.stderr, contains(kUnansweredCardReason));
      expect(net.stderr, isNot(contains('by user')));
      expect(approver.requests, hasLength(2));

      // A person's decline is still recorded as one.
      approver
        ..unanswered = false
        ..answer = false;
      final declined = await runner().run(
        'echo two',
        workdir: cwd.path,
        parentToolCallId: 'toolu_repl',
      );
      expect(declined.personVerdict, ToolGateVerdict.denied);
      expect(audits.last.unanswered, isFalse);
      expect(approver.requests, hasLength(3));
    });

    test(
      'asks a person at most ${CodeModeLimits.maxApprovalAsks} times',
      () async {
        rules.add(ActionDecision.prompt);
        origins.begin('toolu_repl', 'run-1/toolu_repl');
        final results = [
          for (var i = 0; i <= CodeModeLimits.maxApprovalAsks; i++)
            await runner().run(
              'true',
              workdir: cwd.path,
              parentToolCallId: 'toolu_repl',
            ),
        ];

        expect(approver.requests, hasLength(CodeModeLimits.maxApprovalAsks));
        expect(results.last.denied, isTrue);
        expect(results.last.stderr, contains('maxApprovalAsks'));
        // The model's own command is not a script's: it still asks.
        await runner().run('true', workdir: cwd.path);
        expect(
          approver.requests,
          hasLength(CodeModeLimits.maxApprovalAsks + 1),
        );
      },
    );
  });

  test('commands of one script that ask together put up at most '
      '${CodeModeLimits.maxApprovalAsks} cards', () async {
    rules.add(ActionDecision.prompt);
    origins.begin('toolu_repl', 'run-1/toolu_repl');
    approver.delay = const Duration(milliseconds: 100);
    final results = await Future.wait([
      for (var i = 0; i < 30; i++)
        runner().run('true', workdir: cwd.path, parentToolCallId: 'toolu_repl'),
    ]);

    expect(approver.requests, hasLength(CodeModeLimits.maxApprovalAsks));
    final refused = [
      for (final r in results)
        if (r.denied) r,
    ];
    expect(refused, hasLength(30 - CodeModeLimits.maxApprovalAsks));
    expect(
      refused.map((r) => r.stderr),
      everyElement(contains('maxApprovalAsks')),
    );
    expect(
      audits.where((a) => a.reason.contains('maxApprovalAsks')),
      hasLength(30 - CodeModeLimits.maxApprovalAsks),
    );
  });

  test('a card the resolution did not foresee is refused once the script '
      'may not ask any more, without a card', () async {
    rules.add(ActionDecision.prompt);
    origins.begin('toolu_repl', 'run-1/toolu_repl');
    for (var i = 0; i < CodeModeLimits.maxApprovalAsks; i++) {
      await runner().run(
        'true',
        workdir: cwd.path,
        parentToolCallId: 'toolu_repl',
      );
    }
    expect(approver.requests, hasLength(CodeModeLimits.maxApprovalAsks));
    // The policy allows when the call is resolved and asks when it is
    // checked, as when a rule is edited in between.
    final allow = _Rules()..add(ActionDecision.allow);
    rules.queued.addAll([allow.list, rules.list]);

    final res = await runner().run(
      'true',
      workdir: cwd.path,
      parentToolCallId: 'toolu_repl',
    );

    expect(res.denied, isTrue);
    expect(res.stderr, contains('maxApprovalAsks'));
    expect(approver.requests, hasLength(CodeModeLimits.maxApprovalAsks));
  });

  group('waits the gateway holds', () {
    test('a running command is registered with the relay, its environment '
        'carries the registration, and it is released when the command '
        'ends', () async {
      final relay = _Relay();
      rules.add(ActionDecision.allow);
      final reports = <bool>[];

      final res = await runner(callWaits: relay).run(
        r'printf %s "$CC_TEST_CALL"; true',
        workdir: cwd.path,
        personWait: reports.add,
      );

      expect(res.stdout, 'call-1');
      expect(relay.registered, 1);
      expect(relay.released, 1);
      // The relay's listener is the call's own.
      relay.listeners.single(true);
      relay.listeners.single(false);
      expect(reports, [true, false]);
    });

    test('a command that cannot start is released too', () async {
      final relay = _Relay();
      rules.add(ActionDecision.allow);

      final res = await runner(
        callWaits: relay,
        hostProcesses: _Failing(),
      ).run('echo hello', workdir: cwd.path, personWait: (_) {});

      expect(res.exitCode, 1);
      expect(res.stderr, contains('Failed to run command'));
      expect(relay.registered, 1);
      expect(relay.released, 1);
    });

    test(
      'a command that is refused before it runs registers nothing',
      () async {
        final relay = _Relay();
        rules.add(ActionDecision.deny);

        await runner(
          callWaits: relay,
        ).run('echo hello', workdir: cwd.path, personWait: (_) {});

        expect(relay.registered, 0);
      },
    );

    test('a caller with no listener registers nothing', () async {
      final relay = _Relay();
      rules.add(ActionDecision.allow);

      final res = await runner(
        callWaits: relay,
      ).run(r'printf %s "${CC_TEST_CALL:-none}"', workdir: cwd.path);

      expect(res.stdout, 'none');
      expect(relay.registered, 0);
    });
  });
}

class _Relay implements CommandWaitRelay {
  int registered = 0;
  int released = 0;
  final listeners = <PersonWaitListener>[];
  final decisions = <void Function(bool approved)>[];

  @override
  CommandWait register(
    PersonWaitListener listener,
    Map<String, String> env, {
    required void Function(bool approved) decided,
  }) {
    registered++;
    listeners.add(listener);
    decisions.add(decided);
    return CommandWait(
      environment: {'CC_TEST_CALL': 'call-$registered'},
      release: () => released++,
    );
  }

  @override
  void Function() holdScriptApprovals(ScriptApprovalBudget approvals) => () {};
}

class _Failing implements ToolProcessLauncher {
  @override
  bool get confined => false;

  @override
  Future<void> release() async {}

  @override
  Future<Process> start(
    String executable,
    List<String> args, {
    required String workingDirectory,
    Map<String, String>? environment,
  }) async => throw const ProcessException('bash', [], 'no such program');
}

class _Approver implements ConfirmationPort {
  bool answer = true;
  Duration? delay;

  /// Every card comes down with nobody's answer: `onUnanswered`, then no,
  /// as the server's pending-confirmation registry does on an expiry.
  bool unanswered = false;

  /// Runs as each card goes up.
  void Function()? onAsk;
  final requests = <ConfirmationRequest>[];

  /// Answers [answer] after [delay], whether or not the card was withdrawn
  /// meanwhile: a late answer.
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    onAsk?.call();
    final d = delay;
    if (d != null) {
      await Future<void>.delayed(d);
    }
    if (unanswered) {
      request.onUnanswered?.call();
      return false;
    }
    return answer;
  }
}

/// One workspace rule about running anything at all.
class _Rules implements ActionPolicyRepository {
  final list = <ActionPolicyRule>[];

  void add(ActionDecision decision) {
    final now = DateTime.now();
    list.add(
      ActionPolicyRule(
        id: 'spawn-${decision.wire}',
        workspaceId: 'ws',
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: ActionClass.processSpawn,
        decision: decision,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Read once each before [list]: a policy that changes between reads.
  final queued = <List<ActionPolicyRule>>[];

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async =>
      queued.isEmpty ? list : queued.removeAt(0);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
