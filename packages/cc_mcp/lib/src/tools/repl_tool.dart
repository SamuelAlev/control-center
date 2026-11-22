import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/mcp_script_surface.dart';
import 'package:uuid/uuid.dart';

/// The [ScriptPastPort] of one run on the MCP endpoint, bound from its
/// attested scope: the workspace, its conversation (null when it has none)
/// and its space.
typedef McpScriptPast =
    ScriptPastPort Function({
      required String runLogId,
      required String workspaceId,
      required String? conversationId,
      required String? spaceId,
    });

/// Code mode's `repl` tool on the MCP surface, for runs driven by external
/// adapters (Claude Code, Codex, ACP).
///
/// It runs a script through the [CodeExecutionPort]; every tool the script
/// calls goes back through the dispatcher's own gate
/// ([McpScriptSurface.callNested]) under its own name, bound to the calling
/// run's attested scope. The tool itself has no effect: read tier, no effect
/// classes, never mutating (plan decision D7). Only an attested agent run
/// can use it, and only while the runner passes its self-test.
class ReplMcpTool extends McpScopedTool {
  /// Creates the tool over [executions]. [limitsFor] gives a workspace's
  /// effective limits (its `code_mode_limits` setting over the defaults).
  /// [records] are the saved executions, which a caller-chosen parent id is
  /// checked against. [past] binds what a run's scripts read of its past
  /// (`history()`); null where the server gives none, and the four calls
  /// then refuse.
  ///
  /// The dispatcher is built after its tools, so the gate is handed over
  /// later with [bind]; until then every call is refused.
  ReplMcpTool({
    required this.executions,
    required this.limitsFor,
    required this.records,
    required this.past,
  });

  /// Runs scripts.
  final CodeExecutionPort executions;

  /// The durable record of executions.
  final CodeExecutionRepository records;

  /// What a run's scripts read of its past, per run.
  final McpScriptPast? past;

  /// What a caller-chosen parent id must look like: the shape of the ids
  /// Claude Code sends. Anything else gets a minted id.
  static final RegExp _parentIdShape = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// A workspace's effective code mode limits.
  final Future<CodeModeLimits> Function(String workspaceId) limitsFor;

  McpScriptSurface? _surface;

  /// The runs whose scripts can no longer run: the dispatcher lists every
  /// tool to them and calls none of them script-only.
  final WithdrawnScriptRuns withdrawn = WithdrawnScriptRuns();

  /// Hands the tool the gate its scripts' calls go through: the dispatcher
  /// that serves it. Binding again replaces the gate.
  void bind(McpScriptSurface surface) => _surface = surface;

  static const _uuid = Uuid();

  @override
  String get name => ReplToolDescription.toolName;

  /// A script cannot start a script.
  @override
  bool get scriptCallable => false;

  /// The fixed opening of the description. `tools/list` replaces it per run
  /// with the full text, which adds what a script gets from the run's direct
  /// tools and counts its namespaces.
  @override
  String get description => ReplToolDescription.intro;

  /// [ReplToolDescription.inputSchema] plus the `workspace_id` every
  /// workspace-scoped MCP tool takes. The dispatcher forces it to the run's
  /// own workspace, so what a model passes there never matters.
  @override
  Map<String, dynamic> get inputSchema {
    final schema = ReplToolDescription.inputSchema();
    final properties = schema['properties'] as Map<String, dynamic>;
    final required = schema['required'] as List;
    return {
      ...schema,
      'properties': {
        'workspace_id': {
          'type': 'string',
          'description':
              'The workspace the run belongs to. Filled from the session.',
        },
        ...properties,
      },
      'required': ['workspace_id', ...required],
    };
  }

  @override
  bool get requiresRunGrant => true;

  @override
  Set<String> get requiredScopeKeys => const {'workspace_id'};

  @override
  bool get isMutating => false;

  @override
  Future<CallResult> runScoped(
    Map<String, dynamic> arguments,
    McpCallContext context, {
    Future<void>? abandoned,
  }) async {
    final scope = context.scope;
    if (scope == null || !scope.attested) {
      return CallResult.error(
        '$name can only be called by a Control Center agent run.',
      );
    }
    final availability = executions.availability;
    if (availability case CodeRunnerUnavailable(:final reason)) {
      // Counted like any refusal no other script would have escaped: the
      // run's client may still list `repl` from before the runner went.
      _withdraw(scope.runLogId);
      return CallResult.error(
        'Code mode is unavailable on this server: $reason\n\n'
        '${_withdrawnNotice(scope)}',
      );
    }
    final surface = _surface;
    if (surface == null) {
      return CallResult.error(
        '$name is not connected to a tool gate on this server.',
      );
    }
    final workspaceId = scope.workspaceId;
    if (workspaceId == null || workspaceId.isEmpty) {
      return CallResult.error(McpTool.missingArgument('workspace_id'));
    }
    // The run-log row is what an execution's record hangs off, and a script
    // is recorded before it starts: a run without one runs no script.
    final runId = _present(scope.runLogId);
    if (runId == null) {
      return CallResult.error(
        _present(scope.runId) == null
            ? '$name needs the run it was called from, and this call names '
                  'none.'
            : '$name is unavailable in this run: it has no run log, so its '
                  'scripts could not be recorded. Call the tools directly.',
      );
    }
    final parsed = ReplArguments.parse(arguments);
    final error = parsed.error;
    if (error != null) {
      return CallResult.error(error);
    }

    // The adapter's own id for this call when it sent a well-formed one:
    // nested calls then fold under the row its transcript already shows.
    // The caller chooses it, so it may not name a script this run already
    // ran: the new script's rows would be filed under that script's row, and
    // each repeat would cost the service one more id probe.
    final sent = context.toolUseId;
    final String parentToolCallId;
    if (sent != null && _parentIdShape.hasMatch(sent)) {
      final CodeExecutionDetail? earlier;
      try {
        earlier = await records.get(
          workspaceId,
          CodeExecution.idFor(runId: runId, toolCallId: sent),
        );
      } on Object {
        return CallResult.error(
          '$name could not check its call id against this run\'s scripts. '
          'Try again.',
        );
      }
      if (earlier != null) {
        return CallResult.error(
          'This run already ran a script under the call id "$sent". Each '
          '$name call needs a call id of its own.',
        );
      }
      parentToolCallId = sent;
    } else {
      parentToolCallId = 'repl-${_uuid.v4()}';
    }
    final tools = await surface.scriptToolsFor(scope);
    final limits = await limitsFor(workspaceId);
    final present = _present(scope.conversationId);
    // A run with no conversation of its own carries its dispatch id in that
    // slot, which names no conversation row.
    final conversationId = present == scope.runId ? null : present;
    final spaceId = _present(scope.spaceId);
    final request = CodeExecutionRequest(
      workspaceId: workspaceId,
      runId: runId,
      parentToolCallId: parentToolCallId,
      surface: CodeExecutionSurface.mcp,
      code: parsed.code,
      description: parsed.description,
      limits: limits,
      tools: tools,
      // From the attested run grant, never an argument: a read-only run's
      // scripts store and keep nothing.
      readOnly: scope.readOnly,
      // Bound from the attested scope alone, never an argument: history()
      // reads this run's conversation under its space's rule. This endpoint
      // stores no tool output of the run, so outputs, loadOutput and keep
      // refuse saying so.
      past: past?.call(
        runLogId: runId,
        workspaceId: workspaceId,
        conversationId: conversationId,
        spaceId: spaceId,
      ),
      // `store()` keys values by a real conversation and agent.
      conversationId: conversationId,
      agentId: _present(scope.agentId),
      spaceId: spaceId,
      timeoutMs: parsed.timeoutMs,
      maxOutputTokens: parsed.maxOutputTokens,
    );

    final approvals = ScriptApprovalBudget();
    final cancel = CancellationTokenSource();
    unawaited(abandoned?.then((_) => cancel.cancel('caller stopped waiting')));
    final result = await executions.execute(
      request,
      cancel: cancel.token,
      // Passed through unchanged: the service decides the execution's id
      // (a repeated tool call id gets `<id>#<n>`) and puts it in each call's
      // origin, which the approval cards then name.
      // One budget per script: what it may still ask of a person.
      callNested: (call) =>
          surface.callNested(scope, call, approvals: approvals),
    );
    final script = result.result;
    // A refusal no other script would have escaped ends the redirect for
    // the rest of the run. `repl` stays: a later script may still run.
    final kind = result.execution.errorKind;
    final withdraws =
        kind != null && CodeExecutionErrorKind.withdrawsScripts.contains(kind);
    if (withdraws) {
      _withdraw(runId);
    }
    return CallResult(
      content: [
        CallResultContent(
          type: 'text',
          text: withdraws
              ? '${script.text}\n\n${_withdrawnNotice(scope)}'
              : script.text,
        ),
        for (final image in script.images)
          CallResultContent.image(data: image.data, mimeType: image.mediaType),
      ],
      isError: script.isError,
    );
  }

  /// The sentence a refusal that withdraws [scope]'s scripts ends with:
  /// it names `search_tool_bm25` only when the run is then listed it.
  String _withdrawnNotice(McpCallScope scope) =>
      _surface?.offersToolSearch(scope) ?? false
      ? ReplToolDescription.scriptsWithdrawnMcp
      : ReplToolDescription.scriptsWithdrawnDirect;

  /// Ends the redirect for the run with [runLogId] and, when that changes
  /// what a run is listed (this run's surface, or a forgotten run's, see
  /// [WithdrawnScriptRuns.add]), tells clients to list again. A run already
  /// withdrawn changes nothing and notifies nobody.
  void _withdraw(String? runLogId) {
    final id = _present(runLogId);
    if (id != null && withdrawn.add(id)) {
      _surface?.scriptRunsChanged();
    }
  }

  static String? _present(String? value) =>
      value == null || value.isEmpty ? null : value;
}

/// The run-log ids of the runs whose scripts can no longer run
/// ([CodeExecutionErrorKind.withdrawsScripts]), at most [max] of them: past
/// that the run withdrawn longest ago is forgotten and goes back to calling
/// its script-only tools from scripts.
class WithdrawnScriptRuns {
  /// The most runs remembered.
  static const int max = 1024;

  final LinkedHashSet<String> _runs = LinkedHashSet<String>();

  /// How many runs are remembered.
  int get length => _runs.length;

  /// Whether the run with [runLogId] can no longer run scripts.
  bool contains(String runLogId) => _runs.contains(runLogId);

  /// Remembers that the run with [runLogId] can no longer run scripts.
  ///
  /// Returns whether a run's surface changed: true when the run is new here
  /// (its redirect ends), which is also the only time the run withdrawn
  /// longest ago can be forgotten (its redirect comes back). False when it
  /// was already remembered (it moves to the newest place).
  bool add(String runLogId) {
    final added = !_runs.remove(runLogId);
    _runs.add(runLogId);
    while (_runs.length > max) {
      _runs.remove(_runs.first);
    }
    return added;
  }
}
