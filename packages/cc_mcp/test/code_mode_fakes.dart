import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/ports/mode_resolver.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/tools.dart' show ActionClass;

/// The scope the agent run gateway attests for a run in `ws-own`.
McpCallScope runScope({
  String? runLogId = 'log-1',
  String? conversationId = 'conv-1',
  String? agentId = 'agent-1',
}) => McpCallScope(
  workspaceId: 'ws-own',
  agentId: agentId,
  conversationId: conversationId,
  spaceId: 'sp-1',
  attested: true,
  runId: 'dispatch-1',
  runLogId: runLogId,
);

/// A nested call request as the execution service builds it. [origin] is
/// the execution the service says the call belongs to.
NestedCallRequest nestedRequest(
  String name, {
  Map<String, dynamic> arguments = const {},
  Duration deadline = const Duration(seconds: 30),
  CancellationToken cancel = CancellationToken.none,
  void Function(bool waiting)? onPersonWait,
  int sequence = 1,
  ScriptCallOrigin? origin,
  ScriptCallSite? site,
}) => NestedCallRequest(
  sequence: sequence,
  toolCallId: '${origin?.parentToolCallId ?? 'toolu_parent'}/$sequence',
  name: name,
  arguments: arguments,
  origin:
      origin ??
      ScriptCallOrigin(
        parentToolCallId: 'toolu_parent',
        executionId: 'log-1/toolu_parent',
      ),
  deadline: deadline,
  site: site,
  cancel: cancel,
  onPersonWait: onPersonWait,
);

/// A workspace tool that records its arguments and returns [result].
class ProbeTool extends McpTool {
  ProbeTool(
    this.name, {
    this.result,
    this.actionClasses = const {},
    this.requiresApproval = false,
    this.delay,
    this.waitsOnPerson = false,
    this.scriptCallable = true,
    this.argumentRefusal,
  });

  @override
  final String name;

  /// What a script's call is refused with, by its arguments.
  final String? Function(Map<String, dynamic> arguments)? argumentRefusal;

  @override
  String? scriptArgumentRefusal(Map<String, dynamic> arguments) =>
      argumentRefusal?.call(arguments);

  @override
  final bool scriptCallable;

  @override
  final Set<ActionClass> actionClasses;

  @override
  final bool requiresApproval;

  @override
  final bool waitsOnPerson;

  /// What a call returns; `ok` text when null.
  CallResult? result;

  /// How long a call takes.
  final Duration? delay;

  int runs = 0;
  Map<String, dynamic>? lastArgs;
  bool abandoned = false;

  @override
  String get description => 'Probe tool $name.';

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
      ApprovalPayload(title: 'Run $name?', detail: 'It does a thing.');

  @override
  Future<CallResult> runUntilAbandoned(
    Map<String, dynamic> arguments,
    Future<void> abandoned,
  ) {
    abandoned.then((_) => this.abandoned = true);
    return run(arguments);
  }

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    runs++;
    lastArgs = arguments;
    final d = delay;
    if (d != null) {
      await Future<void>.delayed(d);
    }
    return result ?? CallResult.success('ok');
  }
}

/// A tool that names no workspace: a run may not call it.
class GlobalTool extends ProbeTool {
  GlobalTool() : super('global_thing');

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};
}

/// Answers every card with [answer], after [delay], and keeps them.
class Approver implements ConfirmationPort {
  Approver({this.answer = true, this.delay});

  bool answer;
  final Duration? delay;
  final requests = <ConfirmationRequest>[];

  /// Answers handed out before [answer], one per card. Null is a card
  /// nobody answered: it calls `onUnanswered` and resolves no, as the
  /// server's pending-confirmation registry does on a timeout or an expiry.
  final queued = <bool?>[];

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    requests.add(request);
    final d = delay;
    if (d != null) {
      await Future<void>.delayed(d);
    }
    if (queued.isNotEmpty) {
      final next = queued.removeAt(0);
      if (next == null) {
        request.onUnanswered?.call();
        return false;
      }
      return next;
    }
    return answer;
  }
}

/// Resolves every conversation to [mode].
class FixedModeResolver implements ModeResolver {
  FixedModeResolver(this.mode);

  Mode mode;

  @override
  Future<Mode> resolveForConversation(
    String workspaceId,
    String? conversationId,
  ) async => mode;
}

/// Runs [script] in place of a sandbox: it gets the `callNested` the tool
/// handed over and the request, and returns the text the model reads.
class FakeExecutions implements CodeExecutionPort {
  FakeExecutions({
    this.availability = const CodeRunnerAvailability.available(),
    this.script,
    this.records,
    this.refusal,
  });

  /// When set, every script is refused with this error kind instead of run.
  String? refusal;

  /// Where a finished execution is recorded, as the service records it.
  final FakeRecords? records;

  @override
  CodeRunnerAvailability availability;

  Future<String> Function(
    ScriptNestedCall callNested,
    CodeExecutionRequest request,
  )?
  script;

  final requests = <CodeExecutionRequest>[];
  CancellationToken? lastCancel;

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) async {
    requests.add(request);
    lastCancel = cancel;
    final refused = refusal;
    final text = refused != null
        ? 'The script was not run: refused ($refused).'
        : await (script?.call(callNested, request) ?? Future.value('done'));
    final result = CodeExecutionResult(
      result: ScriptResult(
        text: text,
        isError: refused != null,
        truncated: false,
        outputChars: text.length,
      ),
      execution: CodeExecution(
        id: CodeExecution.idFor(
          runId: request.runId,
          toolCallId: request.parentToolCallId,
        ),
        runId: request.runId,
        toolCallId: request.parentToolCallId,
        surface: request.surface,
        startedAt: DateTime.now(),
        durationMs: 1,
        status: refused != null
            ? CodeExecutionStatus.refused
            : CodeExecutionStatus.completed,
        errorKind: refused,
        sourceHash: '0' * 64,
        sourceBytes: request.code.length,
        limits: CodeModeLimits.defaults,
      ),
      calls: const [],
    );
    records?.add(result.execution);
    return result;
  }
}

/// The saved executions: answers [get] for what [add] recorded.
class FakeRecords implements CodeExecutionRepository {
  final saved = <String, CodeExecution>{};
  final probed = <String>[];

  void add(CodeExecution execution) => saved[execution.id] = execution;

  @override
  Future<CodeExecutionDetail?> get(
    String workspaceId,
    String executionId,
  ) async {
    probed.add(executionId);
    final execution = saved[executionId];
    return execution == null
        ? null
        : CodeExecutionDetail(execution: execution, calls: const []);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
