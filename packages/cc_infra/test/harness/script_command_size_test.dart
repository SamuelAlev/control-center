@TestOn('!windows')
library;

import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:test/test.dart';

/// A script's shell command is at most what the guard audit stores whole, so
/// the audit holds the complete command of every call a script made; a
/// direct call's command is not refused (its transcript row holds it).
void main() {
  late Directory cwd;
  late _Rules rules;
  late _Approver approver;
  late _Counting launcher;
  late List<GuardAudit> audits;

  setUp(() {
    cwd = Directory.systemTemp.createTempSync('script_command_size_');
    rules = _Rules();
    approver = _Approver();
    launcher = _Counting();
    audits = [];
  });
  tearDown(() => cwd.deleteSync(recursive: true));

  SandboxedHarnessCommandRunner runner() => SandboxedHarnessCommandRunner(
    mode: Mode.chat,
    networkEnabled: false,
    confirmationPort: approver,
    actionGuard: ActionGuardService(
      repository: rules,
      confirmationPort: approver,
      onAudit: audits.add,
    ),
    hostProcesses: launcher,
    workspaceId: 'ws',
    agentId: 'a',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    scriptOrigins: RunScriptOrigins(runId: 'run-1'),
  );

  test('a script\'s 1 MiB command is refused before anything runs or asks, '
      'with a message that says what to do, and audited', () async {
    // A policy that would ask: the refusal comes first, so no card goes up.
    rules.add(ActionDecision.prompt);
    final command = ': ${'a' * (1024 * 1024)}';

    final res = await runner().run(
      command,
      workdir: cwd.path,
      parentToolCallId: 'toolu_repl',
    );

    expect(res.denied, isTrue);
    expect(
      res.denyReason,
      'The command is 1,048,584 bytes; a command a script runs takes at '
      'most 16,384. Write long content to a file and run that.',
    );
    expect(launcher.starts, 0, reason: 'never spawned');
    expect(approver.requests, isEmpty, reason: 'no card');
    final audit = audits.single;
    expect(audit.decision, ActionDecision.deny);
    expect(audit.source, kScriptActionSizeSource);
    expect(audit.reason, res.denyReason);
  });

  test('a script\'s command of exactly the bound runs', () async {
    rules.add(ActionDecision.allow);
    final command =
        ': ${'a' * (ActionGuardService.maxScriptActionSummaryBytes - 8)}';
    expect(
      'bash: $command'.length,
      ActionGuardService.maxScriptActionSummaryBytes,
    );

    final res = await runner().run(
      command,
      workdir: cwd.path,
      parentToolCallId: 'toolu_repl',
    );

    expect(res.denied, isFalse);
    expect(res.exitCode, 0);
    expect(launcher.starts, 1);
    expect(audits.single.actionSummary, 'bash: $command');
  });

  test('the model\'s own 100 KiB command runs: its transcript row holds it '
      'and its audit row is clipped where it is stored', () async {
    rules.add(ActionDecision.allow);
    final command = ': ${'a' * (100 * 1024)}';

    final res = await runner().run(command, workdir: cwd.path);

    expect(res.denied, isFalse);
    expect(res.exitCode, 0);
    expect(launcher.starts, 1);
    expect(audits.single.decision, ActionDecision.allow);
  });
}

class _Counting implements ToolProcessLauncher {
  int starts = 0;

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
  }) {
    starts++;
    return const HostToolProcessLauncher().start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  }
}

class _Approver implements ConfirmationPort {
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    return true;
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

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => list;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
