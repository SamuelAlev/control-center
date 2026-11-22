// Call sites on the MCP path, from the REAL runner (CC_CODEMODE_RUNNER)
// through the execution service and `McpToolDispatcher.callNested` to the
// nested transcript rows: each row names where in the script its call was
// made, and nothing the dispatcher's gate builds (guard decision, approval
// card and its fingerprint, audit row and its digest) changes with the site.
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_mode_store_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_infra/src/code_mode/bundled_code_runner.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/dispatch/nested_call_rows.dart';
import 'package:cc_infra/src/messaging/transcript_folder.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:test/test.dart';

/// Three calls on lines 1, 3 and 5. Each site is the call's member name.
const _onThreeLines =
    "const a = await tools.lookup({ path: 'a' });\n"
    '\n'
    "  await tools.write_note({ path: 'b' });\n"
    'const c =\n'
    "    await tools.ask_note({ path: 'c' });\n"
    'return 1;';

/// The same three calls, with the same arguments, on one line.
const _onOneLine =
    "const a = await tools.lookup({ path: 'a' }); "
    "await tools.write_note({ path: 'b' }); "
    "const c = await tools.ask_note({ path: 'c' }); return 1;";

const _scope = McpCallScope(
  workspaceId: 'ws-own',
  agentId: 'agent-1',
  conversationId: 'conv-1',
  spaceId: 'sp-1',
  attested: true,
  runId: 'dispatch-1',
  runLogId: 'log-1',
);

class _Tool extends McpTool {
  _Tool(
    this.name, {
    this.actionClasses = const {},
    this.requiresApproval = false,
  });

  @override
  final String name;
  @override
  final Set<ActionClass> actionClasses;
  @override
  final bool requiresApproval;

  @override
  String get description => 'The $name tool.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'path': {'type': 'string'},
    },
    'required': ['workspace_id'],
  };

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) =>
      ApprovalPayload(title: 'Run $name?', detail: 'path ${arguments['path']}');

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async =>
      CallResult.success('{"ok": true}');
}

class _Rules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    final now = DateTime.utc(2026);
    return [
      ActionPolicyRule(
        id: 'space-mutation-prompt',
        workspaceId: 'ws-own',
        scopeType: ActionScopeType.space,
        scopeId: 'sp-1',
        actionClass: ActionClass.workspaceMutation,
        decision: ActionDecision.prompt,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

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

/// Takes every record write; the record is not what these tests read.
class _Executions implements CodeExecutionRepository {
  @override
  Future<void> begin(
    String workspaceId,
    CodeExecution execution, {
    required String source,
  }) async {}

  @override
  Future<CodeExecutionAppendOutcome> appendCall(
    String workspaceId,
    CodeExecutionCall call,
  ) async => CodeExecutionAppendOutcome.appended;

  @override
  Future<CodeExecutionFinishResult> finish(
    String workspaceId,
    CodeExecution execution, {
    required CodeExecutionPayload payload,
    required List<CodeExecutionCall> calls,
  }) async => CodeExecutionFinishResult.finished;

  @override
  Future<bool> close(
    String workspaceId,
    String executionId, {
    required CodeExecutionStatus status,
    required String errorKind,
    required int durationMs,
  }) async => true;

  @override
  Future<int> highestIdSuffix(
    String workspaceId, {
    required String runId,
    required String toolCallId,
  }) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Scripts here store nothing.
class _NoStore implements CodeModeStoreRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What one script produced: the nested rows, and what the gate built.
typedef _Run = ({
  List<ToolSegment> rows,
  List<NestedCallRequest> requests,
  List<String> audits,
  List<String> cards,
});

String _audit(GuardAudit a) => jsonEncode({
  'workspaceId': a.workspaceId,
  'decision': a.decision.name,
  'reason': a.reason,
  'source': a.source,
  'agentId': a.agentId,
  'spaceId': a.spaceId,
  'actionSummary': a.actionSummary,
  'actionClasses': a.actionClasses,
  'ruleId': a.ruleId,
  'prompted': a.prompted,
  'runId': a.runId,
  'command': a.command,
  // The audit row's digest, as the server's sink computes it.
  'argsDigest': a.command == null
      ? null
      : canonicalHash({'command': a.command}),
});

String _card(ConfirmationRequest c) => jsonEncode({
  'spaceId': c.spaceId,
  'title': c.title,
  'detail': c.detail,
  'conversationId': c.conversationId,
  'severity': c.severity.name,
  'command': c.command,
  'kind': c.kind.name,
  'rememberChoice': c.rememberChoice?.name,
  'fingerprint': c.fingerprint,
  'workspaceId': c.workspaceId,
  'actionClasses': c.actionClasses,
  'agentId': c.agentId,
  'constraintJson': c.constraintJson,
  'origin': '${c.origin?.parentToolCallId}|${c.origin?.executionId}',
});

void main() {
  final runner = Platform.environment[BundledCodeRunner.environmentOverride];
  final skip = runner == null || runner.isEmpty || !File(runner).existsSync()
      ? 'set CC_CODEMODE_RUNNER to the built code mode runner'
      : null;

  late CodeSandboxProcess process;
  late CodeExecutionService service;

  setUp(() async {
    process = CodeSandboxProcess(executable: runner!);
    final availability = await process.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
    service = CodeExecutionService(
      sandbox: process,
      executions: _Executions(),
      store: _NoStore(),
      serverProcessCap: 2,
    );
  });

  tearDown(() async {
    await service.dispose();
    expect(process.liveProcessCount, 0);
  });

  /// Runs [code] as the MCP `repl` tool does: the run's script tools, one
  /// approval budget, every nested call through `callNested`.
  Future<_Run> run(String code) async {
    final approver = _Approver();
    final audits = <GuardAudit>[];
    final dispatcher = McpToolDispatcher(
      registry: McpToolRegistry([
        _Tool('lookup'),
        _Tool('write_note', actionClasses: {ActionClass.workspaceMutation}),
        _Tool('ask_note', requiresApproval: true),
      ]),
      confirmationPort: approver,
      actionGuard: ActionGuardService(
        repository: _Rules(),
        confirmationPort: approver,
        onAudit: audits.add,
      ),
    );
    final rows = NestedCallRows();
    final folder = TranscriptFolder(onUpdate: (_, {required structural}) {});
    dispatcher.nestedEvents = (runId, event) {
      expect(runId, 'dispatch-1');
      final kept = rows.bound(event);
      if (kept != null) {
        folder.add(kept);
      }
    };
    final requests = <NestedCallRequest>[];
    final approvals = ScriptApprovalBudget();
    final result = await service.execute(
      CodeExecutionRequest(
        readOnly: false,
        past: null,
        workspaceId: 'ws-own',
        runId: 'log-1',
        parentToolCallId: 'toolu_repl',
        surface: CodeExecutionSurface.mcp,
        code: code,
        description: 'sites',
        limits: CodeModeLimits(),
        tools: await dispatcher.scriptToolsFor(_scope),
      ),
      callNested: (call) {
        requests.add(call);
        return dispatcher.callNested(_scope, call, approvals: approvals);
      },
    );
    expect(
      result.execution.status,
      CodeExecutionStatus.completed,
      reason: result.result.text,
    );
    return (
      rows: [
        for (final s in folder.segments)
          if (s is ToolSegment && s.parentToolCallId == 'toolu_repl') s,
      ],
      requests: requests,
      audits: [for (final a in audits) _audit(a)],
      cards: [for (final c in approver.requests) _card(c)],
    );
  }

  test('three calls on known lines give three nested rows with their '
      'sites', () async {
    final r = await run(_onThreeLines);

    expect(r.rows.map((s) => s.toolName), ['lookup', 'write_note', 'ask_note']);
    expect(r.rows.map((s) => s.toolCallId), [
      'toolu_repl/1',
      'toolu_repl/2',
      'toolu_repl/3',
    ]);
    expect(r.rows.map((s) => s.status), everyElement(ToolSegmentStatus.ok));
    expect(r.rows.map((s) => s.callSite), [
      ScriptCallSite(1, 23),
      ScriptCallSite(3, 15),
      ScriptCallSite(5, 17),
    ]);
    // The request into the gate carries the site; the gate's cards (one from
    // the guard, one from the tool's tier) and audit rows were built.
    expect(r.requests.map((q) => q.site), r.rows.map((s) => s.callSite));
    expect(r.cards, hasLength(2));
    expect(r.audits, isNotEmpty);
  }, skip: skip);

  test('the same calls from other lines build the same guard decisions, '
      'cards, fingerprints and audit rows', () async {
    final apart = await run(_onThreeLines);
    final together = await run(_onOneLine);

    expect(together.rows.map((s) => s.callSite), [
      ScriptCallSite(1, 23),
      ScriptCallSite(1, 58),
      ScriptCallSite(1, 107),
    ]);
    expect(
      together.requests.map((q) => q.site),
      isNot(apart.requests.map((q) => q.site)),
    );
    // Everything else the gate was handed is the same.
    String handed(NestedCallRequest q) => jsonEncode([
      q.sequence,
      q.toolCallId,
      q.name,
      q.arguments,
      q.origin.parentToolCallId,
      q.origin.executionId,
    ]);
    expect(
      together.requests.map(handed).toList(),
      apart.requests.map(handed).toList(),
    );
    expect(together.audits, apart.audits);
    expect(together.cards, apart.cards);
    expect(together.cards.join(), contains('fingerprint'));
  }, skip: skip);
}
