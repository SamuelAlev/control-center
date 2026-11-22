import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart' show ToolOutputReference;

/// One nested tool call, as the execution service hands it to the surface's
/// gate.
class NestedCallRequest {
  /// Creates a request. Throws [ArgumentError] when [sequence] is below one
  /// or [name] is empty.
  NestedCallRequest({
    required this.sequence,
    required this.toolCallId,
    required this.name,
    required this.arguments,
    required this.origin,
    required this.deadline,
    required this.site,
    this.cancel = CancellationToken.none,
    this.onPersonWait,
    this.onToolStarted,
  }) {
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'must be at least 1');
    }
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
  }

  /// One-based position in the script's call order.
  final int sequence;

  /// The nested transcript id
  /// ([CodeExecutionCall.nestedToolCallId]): the gate emits its call and
  /// result events under it, with the `repl` call as parent.
  final String toolCallId;

  /// The tool's raw name, already resolved from the identifier the script
  /// used. The gate looks it up in the run's admitted surface, never in the
  /// raw registry.
  final String name;

  /// The argument object.
  final Map<String, dynamic> arguments;

  /// Marks approval cards and questions this call raises as coming from the
  /// script.
  final ScriptCallOrigin origin;

  /// How long the call may run, waits on a person excluded: the script's
  /// remaining time, at most the loop's tool timeout.
  final Duration deadline;

  /// Fires when the script ends or the run stops before the call settles.
  final CancellationToken cancel;

  /// Called with `true` when the call starts waiting on a person (an approval
  /// card, a question, a command prompt inside a self-guarding tool) and with
  /// `false` when that wait ends. The service holds the script's wall-clock
  /// deadline in between, so a person can take as long as they need. Waits
  /// may nest; every `true` is followed by one `false`.
  final void Function(bool waiting)? onPersonWait;

  /// Called once, when the gate has let the call through and the tool itself
  /// starts, with the decision it passed. From then on the call cannot be
  /// withdrawn: a script that ends before the tool returns is recorded with
  /// the tool still running, not as a call that never ran.
  final void Function(NestedCallGateDecision decision)? onToolStarted;

  /// Where in the script the call was made, or null when the runner reported
  /// no position. For the nested transcript row only: a display hint from
  /// the process that runs model-written code, which no gate decision,
  /// approval, audit entry, digest or fingerprint may read.
  final ScriptCallSite? site;
}

/// How a nested call ended, as the surface's gate reports it.
class NestedCallOutcome {
  /// Creates an outcome. Throws [ArgumentError] when a duration or size is
  /// negative, or a non-completed outcome has no [errorMessage].
  NestedCallOutcome({
    required this.status,
    this.value,
    this.errorMessage,
    this.gateDecision,
    this.durationMs = 0,
    this.approvalWaitMs = 0,
    this.resultBytes = 0,
  }) {
    for (final (v, name) in [
      (durationMs, 'durationMs'),
      (approvalWaitMs, 'approvalWaitMs'),
      (resultBytes, 'resultBytes'),
    ]) {
      if (v < 0) {
        throw ArgumentError.value(v, name, 'must not be negative');
      }
    }
    if (status != NestedCallStatus.completed &&
        (errorMessage == null || errorMessage!.isEmpty)) {
      throw ArgumentError.value(
        errorMessage,
        'errorMessage',
        'a call that did not complete must say why',
      );
    }
  }

  /// How it ended.
  final NestedCallStatus status;

  /// What the script's promise resolves to, JSON-serialisable: the tool's
  /// structured result when it has one, else its text parsed when that is
  /// one JSON object or array, else the text. An image result is
  /// `{ type: "image", mediaType, data }`. Null for a call that did not
  /// complete.
  final Object? value;

  /// The tool's or the gate's message, for a call that did not complete. The
  /// script's promise rejects with an `Error` carrying it.
  final String? errorMessage;

  /// What the gate decided, or null when the call never reached it.
  final NestedCallGateDecision? gateDecision;

  /// Milliseconds from start to settle, waits included.
  final int durationMs;

  /// Milliseconds spent waiting on a person.
  final int approvalWaitMs;

  /// Size of the result in UTF-8 bytes.
  final int resultBytes;
}

/// Runs one nested call through the surface's own gate and reports how it
/// ended. Never throws: every failure is an outcome.
///
/// The harness backs it with `ToolReentry`, the MCP surface with
/// `McpToolDispatcher.callNested`. The service applies the per-call caps,
/// the question cap and the lanes before calling it; the gate applies
/// everything a model-issued call gets (hooks, approval, policy, the tool's
/// own execution).
typedef ScriptNestedCall =
    Future<NestedCallOutcome> Function(NestedCallRequest request);

/// One `repl` call to run.
class CodeExecutionRequest {
  /// Creates a request. Throws [ArgumentError] when an id is empty.
  CodeExecutionRequest({
    required this.workspaceId,
    required this.runId,
    required this.parentToolCallId,
    required this.surface,
    required this.code,
    required this.description,
    required this.limits,
    required this.tools,
    required this.readOnly,
    required this.past,
    this.conversationId,
    this.agentId,
    this.spaceId,
    this.timeoutMs,
    this.maxOutputTokens,
    this.namespaceDescriptions = const {},
    this.storeEnabled = true,
    this.fullOutputSink,
    this.runTree,
  }) {
    for (final (value, name) in [
      (workspaceId, 'workspaceId'),
      (runId, 'runId'),
      (parentToolCallId, 'parentToolCallId'),
      if (runTree case final tree?) (tree, 'runTree'),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
  }

  /// The workspace the run belongs to.
  final String workspaceId;

  /// The run (run-log id).
  final String runId;

  /// The `repl` tool call's id: the parent of every nested call.
  final String parentToolCallId;

  /// Which surface is asking.
  final CodeExecutionSurface surface;

  /// The script source.
  final String code;

  /// The one-line label the model gave. The record keeps it as
  /// [CodeExecution.boundDescription] makes it.
  final String description;

  /// The workspace's effective limits. The service applies the model's
  /// [timeoutMs] and [maxOutputTokens] with [CodeModeLimits.clamp].
  final CodeModeLimits limits;

  /// The callable set: what the run's admitted surface lets a script call,
  /// already without the tools that are never script-callable (`repl`,
  /// `checkpoint`, `rewind`, `search_tools`, `list_my_tools`).
  final List<ScriptToolDescriptor> tools;

  /// Whether the run is read-only (a goal's reviewer, an improvement
  /// review): nothing its scripts do may outlive the run. `store()` throws
  /// and `keep()` rejects; `load()`, `storedKeys()`, `history()`,
  /// `outputs()` and `loadOutput()` still read.
  final bool readOnly;

  /// The run's past and its kept values (`history`, `outputs`, `keep`,
  /// `loadOutput`), bound to the run by the surface; null where the surface
  /// has none (the MCP endpoint, which keeps no transcript or output store
  /// of the run), and those calls then reject saying so.
  final ScriptPastPort? past;

  /// The conversation, when the run has one. `store()` needs it.
  final String? conversationId;

  /// The agent, when the run has one. `store()` needs it.
  final String? agentId;

  /// The space, when the run has one.
  final String? spaceId;

  /// The model's `timeout_ms`, when given.
  final int? timeoutMs;

  /// The model's `max_output_tokens`, when given.
  final int? maxOutputTokens;

  /// Descriptions of external MCP servers, by namespace.
  final Map<String, String> namespaceDescriptions;

  /// Whether the script may use the store. False gives it none, as a run
  /// without a conversation or agent has none (`load()` returns nothing,
  /// `store()` throws, the result says so), while the record still names the
  /// conversation and agent: a subagent runs as its parent's agent, and its
  /// scripts must not read or overwrite what the parent's scripts keep.
  final bool storeEnabled;

  /// Stores the script's full output when it is over the model's budget, and
  /// returns the reference the result's omission marker names, or null when
  /// nothing was stored. Null when the surface has no output store (the MCP
  /// surface): the cut then says the original was not kept.
  ///
  /// Per request, not per service, because the store and its scope belong to
  /// the surface and the run: the harness passes one bound to the run's
  /// `ToolOutputStore` so `read_output` can page through the original.
  final Future<ToolOutputReference?> Function(String fullOutput)?
  fullOutputSink;

  /// The run tree the script belongs to: an opaque key shared by a run and
  /// its subagents, whose scripts together hold at most half of their
  /// workspace's runner slots. Null when the run is a tree of its own (it
  /// has no subagents that run scripts, as on the MCP surface); the tree is
  /// then [runId].
  final String? runTree;

  /// This request as a script of the run tree [tree].
  CodeExecutionRequest inRunTree(String tree) => CodeExecutionRequest(
    workspaceId: workspaceId,
    runId: runId,
    parentToolCallId: parentToolCallId,
    surface: surface,
    code: code,
    description: description,
    limits: limits,
    tools: tools,
    readOnly: readOnly,
    past: past,
    conversationId: conversationId,
    agentId: agentId,
    spaceId: spaceId,
    timeoutMs: timeoutMs,
    maxOutputTokens: maxOutputTokens,
    namespaceDescriptions: namespaceDescriptions,
    storeEnabled: storeEnabled,
    fullOutputSink: fullOutputSink,
    runTree: tree,
  );
}

/// What a `repl` call returns: the text the model reads and the durable
/// record.
class CodeExecutionResult {
  /// Creates a result.
  const CodeExecutionResult({
    required this.result,
    required this.execution,
    required this.calls,
  });

  /// The text, error flag and images for the model.
  final ScriptResult result;

  /// The execution as it ended. Recorded unless it was refused before it
  /// was admitted.
  final CodeExecution execution;

  /// The nested call rows, by sequence.
  final List<CodeExecutionCall> calls;
}

/// The one entry point both surfaces use to run a script.
///
/// The implementation admits the call (per-run and server-wide runner
/// slots), builds the catalog from [CodeExecutionRequest.tools], starts a
/// runner, answers discovery and `models.*` calls itself, sends tool calls to
/// the [ScriptNestedCall] it was given, buffers store writes and commits them
/// when the script completes, shapes the output, and persists the execution.
abstract interface class CodeExecutionPort {
  /// Whether scripts can run on this host.
  CodeRunnerAvailability get availability;

  /// Runs [request], calling [callNested] for each tool call the script
  /// makes. [cancel] stops the script; in-flight nested calls are cancelled
  /// and given [CodeModeLimits.nestedSettleGraceMs] to settle.
  ///
  /// Never throws for anything the script or the runner did: those are
  /// statuses on the result. A request refused before it is admitted
  /// (oversized source, code mode unavailable, another script of the run
  /// still running, no free runner, a run with no run log) is a
  /// [CodeExecutionStatus.refused] result and is not recorded: it did
  /// nothing. Every admitted script is recorded from the moment it is
  /// admitted.
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  });
}
