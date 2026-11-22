// Call sites on the harness path, from the REAL runner (CC_CODEMODE_RUNNER)
// through the real loop and `repl` to the nested transcript rows: each row
// names where in the script its call was made, and nothing the gate builds
// (guard decision, approval card and its fingerprint, audit row and its
// digest, the result's digest of nested calls) changes with the site.
import 'dart:convert';

import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_request_extractor.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/dispatch/nested_call_rows.dart';
import 'package:cc_infra/src/harness/harness_run_factory.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:cc_infra/src/messaging/transcript_folder.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

/// Three calls on lines 1, 3 and 5. Each site is the call's member name.
const _onThreeLines =
    "const a = await tools.lookup({ path: 'a' });\n"
    '\n'
    "  await tools.write_note({ path: 'b', text: 'x' });\n"
    'const c =\n'
    "    await tools.lookup({ path: 'c' });\n"
    'return 1;';

/// The same three calls, with the same arguments, on one line.
const _onOneLine =
    "const a = await tools.lookup({ path: 'a' }); "
    "await tools.write_note({ path: 'b', text: 'x' }); "
    "const c = await tools.lookup({ path: 'c' }); return 1;";

class _Tool extends HarnessTool {
  _Tool(this.name, {this.approvalTier = ToolApprovalTier.read})
    : actionClasses = approvalTier == ToolApprovalTier.read
          ? const {}
          : const {ActionClass.workspaceMutation};

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  @override
  final Set<ActionClass> actionClasses;

  @override
  String get description => 'The $name tool.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  String? executedContent(Map<String, dynamic> args) =>
      approvalTier == ToolApprovalTier.read ? null : jsonEncode(args);

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('{"ok": true}');
}

/// Sends one `repl` call with [code], keeps the digest of nested calls its
/// result block carries, then answers in text.
class _Provider extends LlmProviderPort {
  _Provider(this.code);

  final String code;
  List<HarnessNestedToolCall>? digest;
  int _calls = 0;

  @override
  String get displayName => 'call sites';
  @override
  String get defaultModel => 'test-model';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (_calls++ == 0) {
      yield LlmToolUseDelta(
        id: 'call_repl',
        name: 'repl',
        argumentsJson: jsonEncode({'code': code, 'description': 'sites'}),
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
      return;
    }
    for (final block in messages.last.content) {
      if (block is HarnessToolResultBlock && block.toolUseId == 'call_repl') {
        digest = block.nestedCalls;
      }
    }
    yield const LlmTextDelta('Done.');
    yield const LlmDone(stopReason: LlmStopReason.endTurn);
  }
}

class _Rules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async {
    final now = DateTime.utc(2026);
    return [
      ActionPolicyRule(
        id: 'space-mutation-prompt',
        workspaceId: 'ws-1',
        scopeType: ActionScopeType.space,
        scopeId: 'space-1',
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

/// What one run produced: the nested rows, and every object the gate built.
typedef _Run = ({
  List<ToolSegment> rows,
  List<String> gateInputs,
  List<String> audits,
  List<String> cards,
  String digest,
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
  final runner = realRunnerPath();
  late CodeSandboxProcess process;
  late CodeExecutionService service;

  setUp(() async {
    process = CodeSandboxProcess(executable: runner);
    final availability = await process.selfTest();
    expect(availability.isAvailable, isTrue, reason: '$availability');
    service = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: MemoryStore(),
      serverProcessCap: 2,
    );
  });

  tearDown(() async {
    await service.dispose();
    expect(process.liveProcessCount, 0);
  });

  Future<_Run> run(String code) async {
    final tools = [
      _Tool('lookup'),
      _Tool('write_note', approvalTier: ToolApprovalTier.write),
    ];
    final repl = ReplTool(
      executor: service,
      run: ReplRunIdentity(
        workspaceId: 'ws-1',
        runId: 'run-1',
        readOnly: false,
        past: null,
      ),
      callableTools: tools,
      limits: CodeModeLimits(),
    );
    final approver = _Approver();
    final audits = <GuardAudit>[];
    final guard = ActionGuardService(
      repository: _Rules(),
      confirmationPort: approver,
      onAudit: audits.add,
    );
    final gateInputs = <String>[];
    final provider = _Provider(code);
    final rows = NestedCallRows();
    final folder = TranscriptFolder(onUpdate: (_, {required structural}) {});
    await for (final event in const AgentLoopRunner().run(
      history: <HarnessMessage>[],
      userMessage: 'go',
      tools: [repl, ...tools],
      provider: provider,
      config: AgentLoopConfig(
        tools: LoopToolConfig(
          autoApprove: false,
          nestedCallRefusal: (tool, args) {
            gateInputs.add('refusal ${tool.name} ${jsonEncode(args)}');
            return null;
          },
          // As the run's gate does it: the guard is asked with what the
          // request carries, and only that.
          approvalCallback: (request) async {
            final tool = request.tool;
            final args = request.args;
            gateInputs.add(
              'approval ${tool.name} ${jsonEncode(args)} '
              '${request.origin.toolCallId} '
              '${request.origin.parentToolUseId}',
            );
            if (tool.name == 'repl') {
              return const ToolGateDecision.allow();
            }
            final verdict = await guard.check(
              workspaceId: 'ws-1',
              classes: tool.actionClasses,
              spaceId: 'space-1',
              runId: 'run-1',
              agentId: 'agent-1',
              actionSummary: tool.name,
              executed: tool.executedContent(args),
              request: const ActionRequestExtractor().extract(
                args,
                classes: tool.actionClasses,
                tool: tool.name,
              ),
              origin: ScriptCallOrigin(
                parentToolCallId: request.origin.parentToolUseId!,
                executionId: 'run-1/call_repl',
              ),
              onPersonWait: request.onPersonWait,
            );
            return verdict.allowed
                ? ToolGateDecision.allow(askedPerson: verdict.prompted)
                : ToolGateDecision.deny(reason: verdict.reason ?? 'denied');
          },
        ),
      ),
    )) {
      final transcript = await harnessTranscriptEvent(
        event,
        imageRefs: (_, _) async => const [],
      );
      if (transcript == null) {
        continue;
      }
      final kept = rows.bound(transcript);
      if (kept != null) {
        folder.add(kept);
      }
    }
    return (
      rows: [
        for (final s in folder.segments)
          if (s is ToolSegment && s.parentToolCallId == 'call_repl') s,
      ],
      gateInputs: gateInputs,
      audits: [for (final a in audits) _audit(a)],
      cards: [for (final c in approver.requests) _card(c)],
      digest: jsonEncode([
        for (final c in provider.digest ?? const <HarnessNestedToolCall>[])
          c.toJson(),
      ]),
    );
  }

  test('three calls on known lines give three nested rows with their '
      'sites', () async {
    final r = await run(_onThreeLines);

    expect(r.rows.map((s) => s.toolName), ['lookup', 'write_note', 'lookup']);
    expect(r.rows.map((s) => s.toolCallId), [
      'call_repl/1',
      'call_repl/2',
      'call_repl/3',
    ]);
    expect(r.rows.map((s) => s.status), everyElement(ToolSegmentStatus.ok));
    expect(r.rows.map((s) => s.callSite), [
      ScriptCallSite(1, 23),
      ScriptCallSite(3, 15),
      ScriptCallSite(5, 17),
    ]);
    // The write was put to the guard, which asked, and audited it.
    expect(r.cards, hasLength(1));
    expect(r.audits, isNotEmpty);
  });

  test('the same calls from other lines build the same guard decisions, '
      'cards, fingerprints, audit rows, digests and gate inputs', () async {
    final apart = await run(_onThreeLines);
    final together = await run(_onOneLine);

    // The sites differ...
    expect(together.rows.map((s) => s.callSite), [
      ScriptCallSite(1, 23),
      ScriptCallSite(1, 58),
      ScriptCallSite(1, 118),
    ]);
    expect(
      together.rows.map((s) => s.callSite),
      isNot(apart.rows.map((s) => s.callSite)),
    );
    // ...and nothing the gate built does.
    expect(together.gateInputs, apart.gateInputs);
    expect(together.gateInputs, isNotEmpty);
    expect(together.audits, apart.audits);
    expect(together.cards, apart.cards);
    expect(together.digest, apart.digest);
    expect(together.digest, contains('write_note'));
  });

  test('a nested call event keeps its site on the wire, and a call the '
      'model made has none', () async {
    final nested = ToolCallEvent(
      toolName: 'lookup',
      toolCallId: 'call_repl/1',
      parentToolCallId: 'call_repl',
      callSite: ScriptCallSite(3, 15),
    );
    final wire = AgentProcessEventCodec.toWire(nested);
    expect(wire['callSite'], [3, 15]);
    final back = AgentProcessEventCodec.fromWire(wire) as ToolCallEvent;
    expect(back.callSite, ScriptCallSite(3, 15));

    final direct = AgentProcessEventCodec.toWire(
      ToolCallEvent(toolName: 'lookup', toolCallId: 'c1'),
    );
    expect(direct.containsKey('callSite'), isFalse);
    // A site out of range on the wire is dropped, never thrown.
    final bad = AgentProcessEventCodec.fromWire({
      ...wire,
      'callSite': [0, 1],
    });
    expect((bad as ToolCallEvent).callSite, isNull);
  });
}
