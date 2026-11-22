import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_catalog.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart' show ToolOutputReference;
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/code_execution_record.dart'
    show ScriptCall;
import 'package:cc_infra/src/code_mode/runner_json.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The run a [ReplTool] belongs to: whose scripts it runs, and where their
/// records and stored values go.
class ReplRunIdentity {
  /// Creates an identity. Throws [ArgumentError] when [workspaceId] or
  /// [runId] is empty.
  ReplRunIdentity({
    required this.workspaceId,
    required this.runId,
    required this.readOnly,
    required this.past,
    this.conversationId,
    this.agentId,
    this.spaceId,
    this.storeEnabled = true,
  }) {
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'must not be empty',
      );
    }
    if (runId.isEmpty) {
      throw ArgumentError.value(runId, 'runId', 'must not be empty');
    }
  }

  /// The workspace.
  final String workspaceId;

  /// The run-log id. A run without a run-log row gets no `repl`: its
  /// scripts could not be recorded.
  final String runId;

  /// The conversation, when the run has a real one. `store()` needs it.
  final String? conversationId;

  /// The agent, when the run has a real one. `store()` needs it.
  final String? agentId;

  /// The space, when the run has one.
  final String? spaceId;

  /// Whether scripts may use the store ([CodeExecutionRequest.storeEnabled]):
  /// false for a subagent, which runs as its parent's agent.
  final bool storeEnabled;

  /// Whether the run is read-only ([CodeExecutionRequest.readOnly]).
  final bool readOnly;

  /// The run's past for `history`, `outputs`, `loadOutput` and `keep`
  /// ([CodeExecutionRequest.past]); null where the run has none.
  final ScriptPastPort? past;
}

/// Whether one run's scripts still run: shared by the run's [ReplTool] and
/// its `search_tools`, and by nothing else, so a subagent (which binds its own
/// `repl`) has its own.
///
/// Once the host refuses one of the run's scripts for a reason no other
/// script would have escaped ([CodeExecutionErrorKind.withdrawsScripts]),
/// [withdrawn] stays true for the rest of the run: the `repl` result says so
/// and asks the loop to make the script-only tools direct
/// ([HarnessToolResult.withdrawsScripts]), and `search_tools` loads them
/// instead of pointing at a script.
class ReplLane {
  /// Creates the state of a run whose scripts run. [hasSearch] is whether
  /// the run has a `search_tools` to load the tools with.
  ReplLane({this.hasSearch = true});

  /// Whether the run has a `search_tools`.
  final bool hasSearch;

  bool _withdrawn = false;

  /// Whether the run's scripts can no longer run.
  bool get withdrawn => _withdrawn;

  /// Marks the run's scripts as unable to run, for the rest of the run.
  void withdraw() => _withdrawn = true;

  /// The sentence a refused script's result ends with once [withdrawn].
  String get notice => hasSearch
      ? ReplToolDescription.scriptsWithdrawnSearch
      : ReplToolDescription.scriptsWithdrawnDirect;
}

/// The namespace a script finds [tool] under: for a tool bridged from an
/// external or workspace MCP server (registered as `mcp__<server>__<tool>`),
/// [ScriptToolNamespace.external] of the server's name, which is never a
/// first-party namespace nor `script`; `control-center` for a first-party
/// MCP tool bridged into the harness; `builtin` for everything else.
String scriptNamespaceFor(HarnessTool tool) {
  if (tool is McpToolBridge) {
    final server = tool.mcpTool.serverName ?? _serverOf(tool.name);
    if (server != null && server.isNotEmpty) {
      return ScriptToolNamespace.external(server);
    }
    return ScriptToolNamespace.controlCenter;
  }
  final server = _serverOf(tool.name);
  return server == null
      ? ScriptToolNamespace.builtin
      : ScriptToolNamespace.external(server);
}

String? _serverOf(String name) {
  if (!name.startsWith('mcp__')) {
    return null;
  }
  final rest = name.substring('mcp__'.length);
  final cut = rest.indexOf('__');
  return cut <= 0 ? null : rest.substring(0, cut);
}

/// The neutral description of [tool] a script's catalog is built from: its
/// name, [scriptNamespaceFor] namespace, description, schemas, approval tier
/// and effect classes.
ScriptToolDescriptor scriptToolDescriptorFor(HarnessTool tool) =>
    ScriptToolDescriptor(
      name: tool.name,
      namespace: scriptNamespaceFor(tool),
      description: tool.description,
      inputSchema: tool.inputSchema,
      outputSchema: tool.outputSchema,
      resultNote: tool.resultNote,
      tier: tool.approvalTier,
      effects: tool.actionClasses,
    );

/// Stores a script's full output and returns the reference the result
/// names, or null when nothing was stored.
typedef ReplFullOutputSink =
    Future<ToolOutputReference?> Function(String fullOutput);

/// Code mode's one tool: runs a JavaScript script that calls the run's other
/// tools as functions (plan D1, D7).
///
/// Read tier, self-guarding and without effect classes, because the
/// interpreter has no effects of its own: every effect is a nested call,
/// gated under its own name by the loop's gate through
/// [HarnessToolContext.reentry]. Not parallel-safe, so a nested call's
/// transcript row always follows its parent's, and never callable from a
/// script, so the call tree is two levels deep.
///
/// Constructed per run with the tools a script may call; the description
/// counts them by namespace and gives the direct tools' result notes
/// ([ReplToolDescription.build]). It is built once, so it is the same bytes
/// for the whole run and stays in the cached prompt prefix.
class ReplTool extends HarnessTool {
  /// Creates the tool.
  ///
  /// [callableTools] are the run's tools a script may call: the admitted
  /// surface without the tools that are never script-callable (tools whose
  /// [HarnessTool.scriptCallable] is false, and `repl` itself, are dropped
  /// here as well). [directToolNames] are the tools the model can already
  /// call directly; their schemas are in the request, and the description
  /// gives their result notes. `fullOutputSink` stores output over the budget so
  /// `read_output` can page through it.
  ReplTool({
    required this._executor,
    required this._run,
    required List<HarnessTool> callableTools,
    required this._limits,
    Set<String> directToolNames = const {},
    Map<String, String> namespaceDescriptions = const {},
    this._fullOutputSink,
    ReplLane? lane,
  }) : lane = lane ?? ReplLane(),
       _directToolNames = Set.unmodifiable(directToolNames),
       _namespaceDescriptions = Map.unmodifiable(namespaceDescriptions),
       _tools = List.unmodifiable([
         for (final tool in callableTools)
           if (tool.scriptCallable && tool.name != ReplToolDescription.toolName)
             scriptToolDescriptorFor(tool),
       ]);

  final CodeExecutionPort _executor;
  final ReplRunIdentity _run;
  final CodeModeLimits _limits;
  final Set<String> _directToolNames;
  final Map<String, String> _namespaceDescriptions;
  final ReplFullOutputSink? _fullOutputSink;
  final List<ScriptToolDescriptor> _tools;

  /// Whether this run's scripts still run.
  final ReplLane lane;

  /// The descriptors a script's catalog is built from.
  List<ScriptToolDescriptor> get scriptTools => _tools;

  @override
  String get name => ReplToolDescription.toolName;

  @override
  late final String description = ReplToolDescription.build(
    ScriptCatalog(_tools, namespaceDescriptions: _namespaceDescriptions),
    directToolNames: _directToolNames,
  );

  @override
  late final Map<String, dynamic> inputSchema =
      ReplToolDescription.inputSchema();

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  /// Every effect is a nested call, gated under its own name.
  @override
  bool get selfGuards => true;

  @override
  Set<ActionClass> get actionClasses => const {};

  /// One script at a time per run, and nested rows must follow their parent.
  @override
  bool get parallelSafe => false;

  /// A script cannot start a script (plan D11).
  @override
  bool get scriptCallable => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final reentry = context.reentry;
    if (reentry == null) {
      return HarnessToolResult.error(
        'repl cannot run here: a script cannot start a script, and a tool '
        'called from a script cannot call tools.',
      );
    }
    final toolCallId = context.toolCallId;
    if (toolCallId == null || toolCallId.isEmpty) {
      return HarnessToolResult.error(
        'repl cannot run without a tool call id to file its calls under.',
      );
    }
    final parsed = ReplArguments.parse(args);
    final problem = parsed.error;
    if (problem != null) {
      return HarnessToolResult.error(problem);
    }
    final CodeExecutionResult outcome;
    try {
      outcome = await _executor.execute(
        CodeExecutionRequest(
          workspaceId: _run.workspaceId,
          runId: _run.runId,
          parentToolCallId: toolCallId,
          surface: CodeExecutionSurface.harness,
          code: parsed.code,
          description: parsed.description,
          limits: _limits,
          tools: _tools,
          readOnly: _run.readOnly,
          past: _run.past,
          conversationId: _run.conversationId,
          agentId: _run.agentId,
          spaceId: _run.spaceId,
          timeoutMs: parsed.timeoutMs,
          maxOutputTokens: parsed.maxOutputTokens,
          namespaceDescriptions: _namespaceDescriptions,
          storeEnabled: _run.storeEnabled,
          fullOutputSink: _fullOutputSink,
        ),
        callNested: (request) => callThroughReentry(reentry, request),
        cancel: context.cancel ?? CancellationToken.none,
      );
    } on Object catch (e, st) {
      // What the server threw can name a host path: it goes to the log.
      CcInfraLog.error('code mode: a repl call could not be run', e, st);
      return HarnessToolResult.error(
        'The script could not be run: the server failed before it started '
        '(the server log has the reason). Call the tools directly, or try '
        'again.',
      );
    }
    final result = outcome.result;
    // A refusal no other script would have escaped ends the redirect for
    // the rest of the run. `repl` stays: a later script may still run.
    final kind = outcome.execution.errorKind;
    final withdraws =
        kind != null && CodeExecutionErrorKind.withdrawsScripts.contains(kind);
    if (withdraws) {
      lane.withdraw();
    }
    return HarnessToolResult(
      content: withdraws ? '${result.text}\n\n${lane.notice}' : result.text,
      isError: result.isError,
      withdrawsScripts: withdraws,
      images: [
        for (final image in result.images.take(CodeModeLimits.maxImagesToModel))
          HarnessImageBlock(data: image.data, mediaType: image.mediaType),
      ],
      outcome: outcome.execution.status.wire,
    );
  }
}

/// Runs [request] through the loop's gate and maps how it ended to what the
/// script receives.
///
/// Calls [ToolReentry.call] before any `await`, so calls enter the gate in
/// the order the execution service issues them and the gate numbers its
/// transcript rows as the service numbers its call rows.
Future<NestedCallOutcome> callThroughReentry(
  ToolReentry reentry,
  NestedCallRequest request,
) async {
  final ToolReentryOutcome outcome;
  try {
    outcome = await reentry.call(
      request.name,
      request.arguments,
      cancel: request.cancel,
      timeout: request.deadline,
      onPersonWait: request.onPersonWait,
      onToolStarted: switch (request.onToolStarted) {
        null => null,
        final started => (verdict) => started(_decisionOf(verdict)),
      },
      site: switch (request.site) {
        null => null,
        final site => (line: site.line, column: site.column),
      },
    );
  } on Object catch (e, st) {
    // [ToolReentry.call] settles a tool's own refusals and errors as
    // outcomes and never throws: a throw is the server's fault, and its
    // text (which can name a host path) goes to the log only.
    CcInfraLog.error('code mode: the call to ${request.name} failed', e, st);
    return NestedCallOutcome(
      status: NestedCallStatus.failed,
      errorMessage:
          'The call to ${request.name} failed on the server (the server log '
          'has the reason), and its result is unknown: it may have taken '
          'effect, so check before repeating a call that changes something.',
    );
  }
  final settled = nestedOutcomeOf(outcome);
  final running = outcome.stillRunning;
  if (running == null) {
    return settled;
  }
  // The gate gave up on the call (its deadline, or the script stopped
  // waiting) after the tool started and before it returned. The call settles
  // now with its status and decision, saying the tool was still running; how
  // the tool ended afterwards goes to the server log, as a late call does on
  // MCP.
  unawaited(
    running.then(
      (result) => _logLateReturn(
        request,
        result.isError ? NestedCallStatus.failed : NestedCallStatus.completed,
      ),
      onError: (Object e) =>
          _logLateReturn(request, NestedCallStatus.failed, '$e'),
    ),
  );
  return NestedCallOutcome(
    status: settled.status,
    errorMessage: ScriptCall.stillRunningDetail,
    gateDecision: settled.gateDecision,
    durationMs: settled.durationMs,
    approvalWaitMs: settled.approvalWaitMs,
  );
}

void _logLateReturn(
  NestedCallRequest request,
  NestedCallStatus status, [
  String? error,
]) => CcInfraLog.info(
  'code mode: call ${request.sequence} (${request.name}) of '
  '${request.origin.executionId ?? request.toolCallId} '
  'returned after the script stopped waiting for it, as ${status.wire}'
  '${error == null ? '' : ': ${ScriptCall.lateOutcomeLabel(error)}'}; its '
  'record does not hold this.',
);

NestedCallGateDecision _decisionOf(ToolGateVerdict verdict) =>
    switch (verdict) {
      ToolGateVerdict.allowed => NestedCallGateDecision.allowed,
      ToolGateVerdict.approved => NestedCallGateDecision.approved,
      ToolGateVerdict.denied => NestedCallGateDecision.denied,
    };

/// What a script receives for [outcome] (plan section 5, "What a nested
/// call resolves to").
///
/// A completed call resolves to the tool's structured result when it has
/// one, else its text parsed when that is exactly one JSON object or array,
/// else the text; an image result becomes `{ type: "image", mediaType,
/// data }` (a list of them when there are several). A value over
/// [CodeModeLimits.maxNestedResultBytes] is a failure that states its size.
/// Every other status rejects with the tool's or the gate's message.
NestedCallOutcome nestedOutcomeOf(ToolReentryOutcome outcome) {
  final status = switch (outcome.status) {
    ToolReentryStatus.completed => NestedCallStatus.completed,
    ToolReentryStatus.failed => NestedCallStatus.failed,
    ToolReentryStatus.denied => NestedCallStatus.denied,
    ToolReentryStatus.cancelled => NestedCallStatus.cancelled,
    ToolReentryStatus.timedOut => NestedCallStatus.timedOut,
    ToolReentryStatus.unknownTool => NestedCallStatus.unknownTool,
    ToolReentryStatus.invalidArgs => NestedCallStatus.invalidArgs,
  };
  final gate = switch (outcome.gate?.verdict) {
    final verdict? => _decisionOf(verdict),
    null => null,
  };
  final durationMs = outcome.duration.inMilliseconds;
  final waitMs = outcome.personWait.inMilliseconds;
  final result = outcome.result;
  if (status != NestedCallStatus.completed) {
    final message = result.content.trim().isNotEmpty
        ? result.content
        : outcome.gate?.reason ??
              '${outcome.toolName} ended as ${status.wire.replaceAll('_', ' ')}.';
    return NestedCallOutcome(
      status: status,
      errorMessage: message,
      gateDecision: gate,
      durationMs: durationMs,
      approvalWaitMs: waitMs,
    );
  }
  final value = scriptValueOf(result);
  final encoded = tryJsonEncode(value);
  if (encoded == null) {
    return NestedCallOutcome(
      status: NestedCallStatus.failed,
      errorMessage:
          'The result of ${outcome.toolName} is not JSON, so a script cannot '
          'receive it.',
      gateDecision: gate,
      durationMs: durationMs,
      approvalWaitMs: waitMs,
    );
  }
  final bytes = utf8Length(encoded);
  if (bytes > CodeModeLimits.maxNestedResultBytes) {
    return NestedCallOutcome(
      status: NestedCallStatus.failed,
      errorMessage:
          'The result of ${outcome.toolName} is $bytes bytes; a script '
          'receives at most '
          '${CodeModeLimits.maxNestedResultBytes ~/ (1024 * 1024)} MiB. Narrow '
          'the request (a path, a pattern, a limit) and try again.',
      gateDecision: gate,
      durationMs: durationMs,
      approvalWaitMs: waitMs,
      resultBytes: bytes,
    );
  }
  return NestedCallOutcome(
    status: NestedCallStatus.completed,
    value: value,
    gateDecision: gate,
    durationMs: durationMs,
    approvalWaitMs: waitMs,
    resultBytes: bytes,
  );
}

/// What a script's completed call of a harness tool resolves to, before the
/// size check: the structured result when there is one, else the image
/// blocks, else the text ([scriptResultOfText]: a JSON object or array text
/// arrives parsed). The value a tool's `resultNote` describes.
Object? scriptValueOf(HarnessToolResult result) {
  final structured = result.structured;
  if (structured != null) {
    return structured;
  }
  if (result.images.isNotEmpty) {
    final blocks = [
      for (final image in result.images)
        {'type': 'image', 'mediaType': image.mediaType, 'data': image.data},
    ];
    return blocks.length == 1 ? blocks.single : blocks;
  }
  return scriptResultOfText(result.content);
}
