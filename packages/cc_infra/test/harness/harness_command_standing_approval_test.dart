@TestOn('!windows')
library;

import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_constraint.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:test/test.dart';

/// "Approve for 8 hours" on the harness shell's command net: the net asks on
/// its own (policy allows `git reset --hard`), and a standing approval of the
/// exact command spares the next ask.
void main() {
  late Directory cwd;
  late _Rules rules;
  late _Approver approver;

  setUp(() {
    cwd = Directory.systemTemp.createTempSync('harness_standing_');
    rules = _Rules();
    approver = _Approver();
  });
  tearDown(() => cwd.deleteSync(recursive: true));

  SandboxedHarnessCommandRunner runner() => SandboxedHarnessCommandRunner(
    mode: Mode.chat,
    networkEnabled: false,
    confirmationPort: approver,
    actionGuard: ActionGuardService(
      repository: rules,
      confirmationPort: approver,
    ),
    hostProcesses: const HostToolProcessLauncher(),
    workspaceId: 'ws',
    agentId: 'a',
    conversationId: 'conv-1',
    spaceId: 'space-1',
  );

  // In a scratch directory that is no repository, so git only complains.
  Future<bool> run(String command) async =>
      !(await runner().run(command, workdir: cwd.path)).denied;

  test('the net card offers it, and the same command then runs unasked; '
      'another command asks', () async {
    expect(await run('git reset --hard'), isTrue);
    final card = approver.requests.single;
    expect(card.rememberChoice, isNotNull);
    expect(card.actionClasses, ['processSpawn']);
    expect(
      ActionConstraint.decode(card.constraintJson),
      const ActionConstraint(commands: ['git reset --hard']),
    );
    rules.remember(card);

    expect(await run('git reset --hard'), isTrue);
    expect(approver.requests, hasLength(1));

    expect(await run('git reset --hard HEAD~1'), isTrue);
    expect(approver.requests, hasLength(2));
  });

  test('a plain allow rule does not spare the net', () async {
    final now = DateTime.now();
    rules.list.add(
      ActionPolicyRule(
        id: 'allow',
        workspaceId: 'ws',
        scopeType: ActionScopeType.space,
        scopeId: 'space-1',
        actionClass: ActionClass.processSpawn,
        decision: ActionDecision.allow,
        constraint: const ActionConstraint(commands: ['git reset --hard']),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await run('git reset --hard');
    expect(approver.requests, hasLength(1));
  });

  test('an expired approval asks again', () async {
    await run('git reset --hard');
    rules.remember(
      approver.requests.single,
      expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
    );
    await run('git reset --hard');
    expect(approver.requests, hasLength(2));
  });

  test('a deny still denies', () async {
    await run('git reset --hard');
    rules.remember(approver.requests.single);
    final now = DateTime.now();
    rules.list.add(
      ActionPolicyRule(
        id: 'deny',
        workspaceId: 'ws',
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: ActionClass.processSpawn,
        decision: ActionDecision.deny,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(await run('git reset --hard'), isFalse);
    expect(approver.requests, hasLength(1));
  });

  test('the mode net\'s own deny is not something to approve', () async {
    // Written by hand: no card offers it, and none would help.
    final now = DateTime.now();
    rules.list.add(
      ActionPolicyRule(
        id: 'standing',
        workspaceId: 'ws',
        scopeType: ActionScopeType.space,
        scopeId: 'space-1',
        actionClass: ActionClass.processSpawn,
        decision: ActionDecision.allow,
        provenance: 'remembered',
        constraint: const ActionConstraint(commands: ['sudo true']),
        expiresAt: now.add(const Duration(hours: 8)),
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(await run('sudo true'), isFalse);
    expect(approver.requests, isEmpty);
  });
}

/// Writes what `confirmation.respond` writes for a space-scoped remember.
class _Rules implements ActionPolicyRepository {
  final list = <ActionPolicyRule>[];

  void remember(ConfirmationRequest request, {DateTime? expiresAt}) {
    final now = DateTime.now();
    for (final wire in request.actionClasses) {
      list.add(
        ActionPolicyRule(
          id: 'remembered-$wire-${list.length}',
          workspaceId: request.workspaceId!,
          scopeType: ActionScopeType.space,
          scopeId: request.spaceId,
          actionClass: ActionClass.fromWire(wire),
          decision: ActionDecision.allow,
          provenance: 'remembered',
          constraint: ActionConstraint.decode(request.constraintJson),
          expiresAt: expiresAt ?? now.add(const Duration(hours: 8)),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => list;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Approver implements ConfirmationPort {
  final requests = <ConfirmationRequest>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    return true;
  }
}
