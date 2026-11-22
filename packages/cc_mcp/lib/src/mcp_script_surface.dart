import 'dart:async';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_infra/cc_infra.dart' show McpToolBridge;

/// The MCP surface's side of code mode, as `repl` sees it: which tools a
/// run's scripts may call, and the gate each call goes through.
///
/// `McpToolDispatcher` implements it. `ReplMcpTool` is constructed before
/// the dispatcher exists and is bound to it afterwards.
abstract interface class McpScriptSurface {
  /// The tools a script running for [scope] may call, as descriptors: the
  /// run's tool view after the mode guard, without the tools that are not
  /// script-callable (`McpTool.scriptCallable`) and anything an agent run
  /// cannot call at all.
  Future<List<ScriptToolDescriptor>> scriptToolsFor(McpCallScope scope);

  /// Runs one nested call for [scope] through the same gate a `tools/call`
  /// passes. Never throws. [approvals] is the budget of the script (the one
  /// `repl` call) the call belongs to: what it may still ask of a person.
  Future<NestedCallOutcome> callNested(
    McpCallScope scope,
    NestedCallRequest request, {
    required ScriptApprovalBudget approvals,
  });

  /// Tells connected clients to list their tools again: a run's script
  /// surface changed (its scripts were withdrawn, or a withdrawal was
  /// forgotten and its redirect came back).
  void scriptRunsChanged();

  /// Whether a run of [scope] without scripts is listed the catalogue
  /// search (`search_tool_bm25`), so a message may point at it.
  bool offersToolSearch(McpCallScope scope);
}

/// Shows a nested call in its run's live transcript: [event] is a
/// [ToolCallEvent] or [ToolResultEvent] whose `parentToolCallId` names the
/// `repl` call, for the run whose dispatch id is [runId].
///
/// The dispatcher cannot reach a run's event stream itself (it lives in the
/// dispatch session), so the server binds this to whatever can.
typedef NestedCallEventSink =
    void Function(String runId, AgentProcessEvent event);

/// Builds the descriptor a script sees for [tool].
///
/// The schema is the one the built-in harness shows for the same tool: the
/// arguments the run's scope fills are hidden ([McpToolBridge] does the
/// hiding), because the gate forces them whatever the script passes.
/// [namespace] is `control-center` for first-party tools and the server's
/// name for a tool bridged from an external server.
ScriptToolDescriptor scriptToolDescriptor(
  McpTool tool, {
  required McpCallScope scope,
  required String namespace,
}) {
  final bridge = McpToolBridge(
    tool,
    hiddenScopeParams: hiddenScopeParams(tool, scope),
  );
  return ScriptToolDescriptor(
    name: tool.name,
    namespace: namespace,
    description: tool.description,
    inputSchema: bridge.inputSchema,
    outputSchema: tool.outputSchema,
    resultNote: tool.resultNote,
    tier: bridge.approvalTier,
    effects: tool.actionClasses,
  );
}

/// The arguments [scope] fills for [tool], by the rule the harness registry
/// uses: identity the run can supply, and `agent_id` only for a tool that
/// forces it to the caller (elsewhere it is a target).
Set<String> hiddenScopeParams(McpTool tool, McpCallScope scope) {
  bool has(String? v) => v != null && v.isNotEmpty;
  return {
    if (has(scope.workspaceId)) 'workspace_id',
    if (has(scope.conversationId)) ...{
      'conversation_id',
      McpCallScope.callerConversationKey,
    },
    if (has(scope.spaceId)) 'space_id',
    if (has(scope.agentId)) ...{
      ...McpCallScope.callerIdentityKeys,
      if (tool.forcedScopeKeys.contains('agent_id')) 'agent_id',
    },
  };
}

/// What a script's call resolves to, from the tool's [result] (plan section
/// 5, "What a nested call resolves to"):
///
/// 1. the tool's structured result, when it has one;
/// 2. otherwise its text parsed, when the text is one JSON object or array;
/// 3. otherwise the text.
///
/// An image piece is `{type: "image", mediaType, data}`, which the script's
/// `image()` accepts. A result of images only resolves to the image (one) or
/// the list of them; text with images resolves to `{text, images}`, where
/// `text` follows rules 2 and 3.
Object? nestedResultValue(CallResult result) {
  final structured = result.structured;
  if (structured != null) {
    return structured;
  }
  final text = result.content
      .where((c) => !c.isImage && c.text.isNotEmpty)
      .map((c) => c.text)
      .join('\n');
  final images = [
    for (final c in result.content)
      if (c.isImage)
        {
          'type': 'image',
          'mediaType': (c.mimeType ?? 'image/png').trim().toLowerCase(),
          'data': c.data,
        },
  ];
  if (images.isEmpty) {
    return scriptResultOfText(text);
  }
  if (text.trim().isEmpty) {
    return images.length == 1 ? images.single : images;
  }
  return {'text': scriptResultOfText(text), 'images': images};
}

/// The error message of a failed [result]: its text, or a fixed sentence
/// when the tool gave none.
String nestedErrorMessage(String toolName, CallResult result) {
  final text = result.content
      .where((c) => c.text.isNotEmpty)
      .map((c) => c.text)
      .join('\n')
      .trim();
  return text.isEmpty ? '$toolName failed without a message.' : text;
}

/// Holds a nested call's clock: its deadline, which stops while a person is
/// being waited on, and the caller's person-wait signal.
///
/// Waits nest by depth: the clock stops at the first and runs again at the
/// last, and the caller hears `true` and `false` only at those edges.
/// [settle] ends whatever is still open, once, and makes every later report
/// a no-op, so a caller that has its outcome never hears from this call
/// again.
class NestedCallClock {
  /// Starts a clock that fires `onExpired` after [deadline] of time not spent
  /// waiting on a person, signalling waits to `onPersonWait`.
  NestedCallClock({
    required Duration deadline,
    required this._onExpired,
    this._onPersonWait,
  }) : _remaining = deadline {
    _arm();
  }

  final void Function() _onExpired;
  final void Function(bool waiting)? _onPersonWait;
  Duration _remaining;
  Timer? _timer;
  final Stopwatch _running = Stopwatch();
  final Stopwatch _waiting = Stopwatch();
  int _depth = 0;
  bool _settled = false;

  /// Time spent waiting on a person so far.
  Duration get personWait => _waiting.elapsed;

  /// A person-wait begins.
  void begin() {
    if (_settled) {
      return;
    }
    _depth++;
    if (_depth > 1) {
      return;
    }
    _timer?.cancel();
    _running.stop();
    _remaining -= _running.elapsed;
    _running.reset();
    _waiting.start();
    _onPersonWait?.call(true);
  }

  /// A person-wait ends.
  void end() {
    if (_settled || _depth == 0) {
      return;
    }
    _depth--;
    if (_depth > 0) {
      return;
    }
    _waiting.stop();
    _onPersonWait?.call(false);
    _arm();
  }

  /// Stops the clock for good, closing an open wait.
  void settle() {
    if (_settled) {
      return;
    }
    _timer?.cancel();
    _running.stop();
    _waiting.stop();
    if (_depth > 0) {
      _depth = 0;
      _onPersonWait?.call(false);
    }
    _settled = true;
  }

  void _arm() {
    if (_remaining <= Duration.zero) {
      _timer = Timer(Duration.zero, _onExpired);
      return;
    }
    _running.start();
    _timer = Timer(_remaining, _onExpired);
  }
}
