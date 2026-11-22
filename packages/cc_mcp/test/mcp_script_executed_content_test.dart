// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_mcp/src/tools/environment_tools.dart';
import 'package:test/test.dart';

import 'code_mode_fakes.dart';

/// A script's `environment_exec` on the MCP surface: an argv whose summary
/// is over what the guard audit stores whole is refused before the service
/// runs it, and audited with all of it; at the bound it runs and the audit
/// holds it whole; the model's own call is never refused for its size.
void main() {
  const bound = ActionGuardService.maxScriptActionSummaryBytes;
  // `environment_exec: ["echo","…"]`: 18 + 11 bytes around the payload.
  const atBound = bound - 18 - 11;

  late _Environments environments;
  late List<GuardAudit> audits;
  late McpToolDispatcher dispatcher;

  final origin = ScriptCallOrigin(
    parentToolCallId: 'toolu_repl',
    executionId: 'log-1/toolu_repl#2',
  );

  setUp(() {
    environments = _Environments();
    audits = [];
    dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([
        EnvironmentExecTool(environments: environments),
      ]),
      confirmationPort: Approver(),
      actionGuard: ActionGuardService(
        repository: _AllowExec(),
        onAudit: audits.add,
      ),
    );
  });

  Future<NestedCallOutcome> scripted(int payload, {int sequence = 1}) =>
      dispatcher.callNested(
        runScope(),
        nestedRequest(
          'environment_exec',
          arguments: {
            'service': 'api',
            'command': ['echo', 'x' * payload],
          },
          origin: origin,
          sequence: sequence,
        ),
        approvals: ScriptApprovalBudget(),
      );

  test('over the bound: refused before the service runs it, and audited '
      'with all of it', () async {
    final outcome = await scripted(20000);

    expect(outcome.status, NestedCallStatus.denied);
    expect(
      outcome.errorMessage,
      contains('a command a script runs takes at most 16,384'),
    );
    expect(environments.ran, isEmpty);
    final argv = jsonEncode(['echo', 'x' * 20000]);
    final audit = audits.single;
    expect(audit.source, kScriptActionSizeSource);
    expect(audit.decision, ActionDecision.deny);
    expect(audit.actionSummary, 'environment_exec: $argv');
    expect(audit.command, argv);
    expect(audit.runId, 'log-1', reason: 'the row names the run\'s record');
  });

  test('at the bound: runs, and the audit holds the argv whole', () async {
    final outcome = await scripted(atBound);

    expect(outcome.status, NestedCallStatus.completed);
    expect(environments.ran, [
      ['echo', 'x' * atBound],
    ]);
    final argv = jsonEncode(['echo', 'x' * atBound]);
    final audit = audits.single;
    expect(audit.decision, ActionDecision.allow);
    expect(audit.actionSummary, 'environment_exec: $argv');
    expect(utf8.encode(audit.actionSummary), hasLength(bound));
    expect(audit.command, argv);
    expect(audit.runId, 'log-1');
  });

  test('one byte over the bound is refused', () async {
    final outcome = await scripted(atBound + 1);

    expect(outcome.status, NestedCallStatus.denied);
    expect(outcome.errorMessage, contains('The command is 16,385 bytes'));
    expect(environments.ran, isEmpty);
  });

  test('the model\'s own call is not refused for its size, and its audit '
      'holds all of it', () async {
    final response = await dispatcher.handleScopedRequest(
      JsonRpcRequest(
        method: 'tools/call',
        params: {
          'name': 'environment_exec',
          'arguments': {
            'service': 'api',
            'command': ['echo', 'x' * 20000],
          },
        },
        id: 1,
      ),
      scope: runScope(),
    );

    expect(response['result']['isError'], isNot(true));
    expect(environments.ran, hasLength(1));
    final argv = jsonEncode(['echo', 'x' * 20000]);
    expect(audits.single.actionSummary, 'environment_exec: $argv');
    expect(audits.single.command, argv);
    expect(audits.single.runId, 'log-1');
  });
}

/// Records what it was asked to run.
class _Environments implements EnvironmentPort {
  final ran = <List<String>>[];

  @override
  Future<EnvironmentExecResult> exec(
    String workspaceId,
    String spaceId, {
    required String service,
    required List<String> command,
    required Principal by,
  }) async {
    ran.add(command);
    return const EnvironmentExecResult(exitCode: 0, stdout: '', stderr: '');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Allows what `environment_exec` declares, so a call that is not refused
/// for its size runs.
class _AllowExec implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => [
    for (final c in [ActionClass.processSpawn, ActionClass.hostExecution])
      ActionPolicyRule(
        id: 'allow-${c.wire}',
        workspaceId: 'ws-own',
        scopeType: ActionScopeType.workspace,
        scopeId: '',
        actionClass: c,
        decision: ActionDecision.allow,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
