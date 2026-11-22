import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_approval_budget.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/modes/read_only_run_profile.dart';
import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart'
    show EnforcementLevel;
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_request_extractor.dart';
import 'package:cc_domain/features/guardrails/domain/services/policy_resolver.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';
import 'package:cc_mcp/src/mcp_protocol.dart';
import 'package:cc_mcp/src/mcp_run_tool_surface.dart';
import 'package:cc_mcp/src/mcp_scoped_tool.dart';
import 'package:cc_mcp/src/mcp_script_surface.dart';
import 'package:cc_mcp/src/mcp_unknown_tool_message.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Ceiling on text and ordinary tool result characters.
///
/// 1 MiB bounds search/message text and untrusted result payloads. The
/// first-party render_media image pieces have a separate per-image cap below.
/// Bridged external tools are capped tighter (256 KB, `tool_bridge.dart`).
const int _maxResultChars = 1024 * 1024;

/// Image payloads have a separate per-image budget from text metadata.
const int _maxRenderMediaImageChars = 5 * 1024 * 1024;

/// Mcp tool dispatcher.
///
/// Also the MCP surface's code mode gate ([McpScriptSurface]): a script's
/// nested call runs through the same gate as a `tools/call`.
class McpToolDispatcher implements RpcDispatcher, McpScriptSurface {
  /// Creates a new [Mcp tool dispatcher].
  McpToolDispatcher({
    required this.registry,
    this.modeGuard,
    this.confirmationPort,
    this.commandPolicy,
    this.actionGuard,
    this.approvalMode = ApprovalMode.alwaysAsk,
    this.isWorkspaceReadOnly,
  });

  /// Registry of available MCP tools used to handle incoming requests.
  final McpToolRegistry registry;

  /// The standing approval posture (PRD 01 phase 1.5). Each tool resolves a
  /// per-args [CapabilityTier]; tiers at or below this mode's ceiling
  /// auto-approve, anything above prompts via [confirmationPort]. The default
  /// `always-ask` preserves CC's historical "mutating tools prompt" behaviour.
  ///
  /// Mutable so the host's `McpClientControl.setApprovalMode` can re-point the
  /// gate at runtime without rebuilding the dispatcher (one dispatcher backs
  /// both the MCP HTTP server and the RPC transport, so a single assignment
  /// updates every surface at once).
  ApprovalMode approvalMode;

  /// Optional guard that filters mutating tools out by conversation mode
  /// (review / plan). When null the dispatcher applies no per-mode gating.
  final ModeToolGuard? modeGuard;

  /// What a run sees and may call from a script ([McpRunToolSurface]).
  late final McpRunToolSurface _surface = McpRunToolSurface(
    registry: registry,
    modeGuard: modeGuard,
  );

  /// Optional command policy for shell-command-producing tools. When set,
  /// the dispatcher extracts the command string from common argument keys
  /// (`command`, `cmd`) and evaluates it: deny→error, prompt→approval,
  /// allow→proceed.
  final CommandPolicy? commandPolicy;

  /// Optional port for surfacing destructive-action confirmations.
  /// When null, [McpTool.requiresApproval] is ignored.
  final ConfirmationPort? confirmationPort;

  /// Optional unified-guardrail "effect net" (PRD 24 §3). When set, every tool
  /// that DECLARES a non-empty [McpTool.actionClasses] set is checked against
  /// the workspace's action policy before it runs: `allow` proceeds, `deny`
  /// refuses with an informative terminal reason and `prompt` surfaces ONE
  /// confirmation via the [ConfirmationPort] (fail-closed when no approver).
  /// Null on clients/tests that do not inject it; the server wires it in.
  final ActionGuardService? actionGuard;

  /// Whether a workspace's database is read-only (its integrity check
  /// failed). A mutating tool ([McpTool.isMutating]) aimed at such a
  /// workspace is refused before it runs, the same refusal the `repo/call`
  /// dispatcher gives; read tools still run. Null skips the gate.
  final bool Function(String workspaceId)? isWorkspaceReadOnly;

  /// Where a script's nested calls are shown live, under their `repl` call,
  /// in the run's transcript. Late-bound by the server, which owns the runs;
  /// null shows nothing live (the execution service still records every
  /// call).
  NestedCallEventSink? nestedEvents;

  static const _protocolVersion = mcpProtocolVersion;

  /// Dispatches a JSON-RPC [request] to the appropriate handler and returns the result.
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) =>
      handleScopedRequest(request);

  /// Like [handleRequest], but with a transport-derived identity [scope].
  ///
  /// The MCP HTTP transport passes the attested grant of the agent run whose
  /// secret the request carried, so `tools/call` arguments are
  /// workspace-forced / identity-filled exactly like the built-in harness's
  /// `McpToolBridge`, and a tool that names no workspace is refused. Callers
  /// without a scope (RPC transport, the server owner's token) pass none and
  /// arguments flow through verbatim.
  ///
  /// [abandoned] completes when the caller stops waiting for a `tools/call`
  /// result (it cancelled the request or hung up); the tool sees it through
  /// [McpTool.runUntilAbandoned].
  Future<Map<String, dynamic>> handleScopedRequest(
    JsonRpcRequest request, {
    McpCallScope? scope,
    Future<void>? abandoned,
  }) async {
    switch (request.method) {
      case 'initialize':
        return _handleInitialize(request, scope);
      case 'notifications/initialized':
        return {}; // No response for notifications
      case 'tools/list':
        return _handleToolsList(request, scope);
      case 'tools/call':
        return _handleToolsCall(request, scope, abandoned);
      case 'ping':
        return {'jsonrpc': '2.0', 'id': request.id, 'result': {}};
      default:
        return _errorResponse(
          -32601,
          'Method not found: ${request.method}',
          request.id,
        );
    }
  }

  /// Answers with [scope]'s caller's instructions
  /// ([McpRunToolSurface.instructions]).
  Future<Map<String, dynamic>> _handleInitialize(
    JsonRpcRequest request,
    McpCallScope? scope,
  ) async {
    final clientName =
        (request.params['clientInfo'] as Map<String, dynamic>?)?['name']
            as String? ??
        'unknown';

    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {
        'protocolVersion': _protocolVersion,
        'serverInfo': {
          'name': 'control-center',
          'version': BuildInfo.buildVersion,
        },
        'capabilities': {
          'tools': {'listChanged': true},
        },
        'instructions': await _surface.instructions(scope, _viewOf(scope)),
        '_meta': {'clientName': clientName},
      },
    };
  }

  Future<Map<String, dynamic>> _handleToolsList(
    JsonRpcRequest request,
    McpCallScope? scope,
  ) async {
    // External servers only for an attested run, and only its own: its
    // workspace's configured servers, plus the owner's personal ones when its
    // grant says the owner is accountable for it. The owner's token and paired
    // devices see the shared tools alone (`McpCallScope.toolView`).
    final definitions = await _surface.listed(scope, _viewOf(scope));
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {
        'tools': [for (final d in definitions) d.toJson()],
      },
    };
  }

  /// Whether a guard check of [resolution] would ask a person: a `prompt`
  /// decision whose driving rule is not advisory (an advisory rule allows).
  static bool _wouldAsk(ActionResolution resolution) =>
      resolution.decision == ActionDecision.prompt &&
      resolution.driving.rule?.enforcement != EnforcementLevel.advisory;

  /// [resolution] as the denial a script's spent approval budget applied,
  /// with the budget's [refusal] as its reason: what the audit trail records
  /// for a script's call refused without asking anyone, so the trail says
  /// why nobody was asked. The rule that would have asked stays named.
  static ActionResolution _budgetDenial(
    ActionResolution resolution,
    String refusal,
  ) => ActionResolution(
    decision: ActionDecision.deny,
    driving: PolicyResolution(
      decision: ActionDecision.deny,
      source: resolution.driving.source,
      reason: refusal,
      rule: resolution.driving.rule,
      actionClass: resolution.driving.actionClass,
    ),
    prompting: resolution.prompting,
  );

  /// Through the registry's own change hook, which reaches every client; any
  /// run whose surface did not change lists the same bytes again.
  @override
  void scriptRunsChanged() => registry.onToolsChanged?.call();

  @override
  bool offersToolSearch(McpCallScope scope) =>
      registry.lookup(McpRunToolSurface.searchToolName, view: _viewOf(scope)) !=
      null;

  @override
  Future<List<ScriptToolDescriptor>> scriptToolsFor(McpCallScope scope) async {
    final view = _viewOf(scope);
    final mode = await _surface.runMode(scope);
    return [
      for (final tool in _surface.scriptCallable(scope, view, mode).values)
        _surface.descriptorOf(tool, scope, view),
    ];
  }

  /// Caps what one tool call can hand back.
  ///
  /// Nothing bounded a FIRST-PARTY tool's result: `tool_bridge.dart` caps bridged EXTERNAL
  /// tools at 256 KB precisely because their output is not ours, but a tool in this package
  /// could return a 100 MB string — a `list_articles` with a large `limit`, a code-graph
  /// query over a monorepo — and it went to the model verbatim, through the context window
  /// and the phone's WebSocket alike.
  static CallResult _boundResult(String toolName, CallResult result) {
    var budget = _maxResultChars;
    var truncated = false;
    final kept = <CallResultContent>[];
    var images = 0;
    for (final piece in result.content) {
      final data = piece.data;
      if (toolName == 'render_media' && piece.isImage) {
        images++;
        if (images <= 4 && piece.data!.length <= _maxRenderMediaImageChars) {
          kept.add(piece);
        } else {
          truncated = true;
        }
        continue;
      }
      if (data != null) {
        if (data.length > budget) {
          truncated = true;
          continue;
        }
        budget -= data.length;
        kept.add(piece);
        continue;
      }
      if (piece.text.length <= budget) {
        budget -= piece.text.length;
        kept.add(piece);
        continue;
      }
      truncated = true;
      if (budget > 0) {
        kept.add(
          CallResultContent(
            type: piece.type,
            text: piece.text.substring(0, budget),
          ),
        );
        budget = 0;
      }
    }
    if (!truncated) {
      return result;
    }
    if (toolName == 'render_media') {
      return CallResult.error(
        'Rendered images exceed the 5 MiB per-image delivery limit. '
        'Try a smaller max_dimension.',
      );
    }
    CcMcpLog.w(
      'MCP',
      '← $toolName result exceeded $_maxResultChars chars and was truncated',
    );
    kept.add(
      CallResultContent(
        type: 'text',
        text:
            '\n\n[truncated: $toolName returned more than '
            '$_maxResultChars characters. Narrow the request — a smaller '
            '`limit`, a more specific query — and call again.]',
      ),
    );
    return CallResult(content: kept, isError: result.isError);
  }

  /// The external layers [scope]'s caller may see; none without a scope.
  /// What a call of an unknown [toolName] tells [scope]'s caller: the
  /// nearest names, and only the discovery tools the caller has.
  String _unknownTool(String toolName, McpCallScope? scope, McpToolView view) {
    final scripts = _surface.hasRepl(scope, view);
    return unknownToolMessage(
      toolName,
      _surface.nameable(view, scripts: scripts),
      scripts: scripts,
    );
  }

  static McpToolView _viewOf(McpCallScope? scope) =>
      scope?.toolView ?? McpToolView.shared;

  /// Whether [tool]'s input schema takes a `workspace_id`: the argument the
  /// dispatcher forces for an agent run.
  static bool declaresWorkspace(McpTool tool) {
    final props = tool.inputSchema['properties'];
    return props is Map && props.containsKey('workspace_id');
  }

  Future<Map<String, dynamic>> _handleToolsCall(
    JsonRpcRequest request,
    McpCallScope? scope,
    Future<void>? abandoned,
  ) async {
    final toolName = request.params['name'] as String?;
    if (toolName == null || toolName.isEmpty) {
      return _errorResponse(-32602, 'Missing tool name', request.id);
    }

    final view = _viewOf(scope);
    final tool = registry.resolve(toolName, view: view);
    if (tool == null) {
      return _errorResponse(
        -32602,
        _unknownTool(toolName, scope, view),
        request.id,
      );
    }
    final redirect = await _scriptOnlyRedirect(tool, scope, view);
    if (redirect != null) {
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(redirect).toJson(),
      };
    }

    final rawArgs = request.params['arguments'];
    final meta = request.params['_meta'];
    final toolUseId = meta is Map ? meta[toolUseIdMetaKey] : null;
    final gated = await _gate(
      toolName: toolName,
      tool: tool,
      view: view,
      scope: scope,
      arguments: rawArgs is Map
          ? Map<String, dynamic>.from(rawArgs)
          : <String, dynamic>{},
      abandoned: abandoned,
      context: McpCallContext(
        scope: scope,
        toolUseId: toolUseId is String && toolUseId.isNotEmpty
            ? toolUseId
            : null,
      ),
    );
    final CallResult result;
    switch (gated) {
      case _GateRefused(:final message):
        result = CallResult.error(message);
      case _GateRan(result: final ran):
        result = _boundResult(
          toolName,
          // The catalogue search knows nothing of the caller's scripts: for
          // a run with them, say which hits it calls from a script.
          tool.name == McpRunToolSurface.searchToolName &&
                  _surface.hasRepl(scope, view)
              ? await _surface.searchForScripts(ran, scope!, view)
              : ran,
        );
      case _GateThrew():
        result = CallResult.error('Internal error executing $toolName');
      case _GateWithdrawn():
        // Only a script's call is ever withdrawn.
        result = CallResult.error('$toolName was cancelled.');
    }
    return {'jsonrpc': '2.0', 'id': request.id, 'result': result.toJson()};
  }

  /// The `_meta` key under which Claude Code sends the id of the tool use a
  /// `tools/call` serves: the id its transcript knows the call by.
  static const String toolUseIdMetaKey = 'claudecode/toolUseId';

  /// The refusal for a direct call to a tool the listing rule moved behind
  /// `repl` ([McpRunToolSurface.listed]), or null when the call may go ahead.
  ///
  /// A tool the run could not call from a script either (the mode guard
  /// refuses it) is left to the gate, which says why.
  Future<String?> _scriptOnlyRedirect(
    McpTool tool,
    McpCallScope? scope,
    McpToolView view,
  ) async {
    if (!_surface.hasRepl(scope, view) ||
        tool.name == ReplToolDescription.toolName) {
      return null;
    }
    final mode = await _surface.runMode(scope!);
    if (McpRunToolSurface.directNames(mode).contains(tool.name) ||
        !_surface.scriptCallable(scope, view, mode).containsKey(tool.name)) {
      return null;
    }
    return '"${tool.name}" is callable only from a script in this run. Call '
        'it from `repl` as `await tools["${tool.name}"](args)`.';
  }

  /// Runs one call through the whole gate chain and then the tool: the one
  /// gate both a `tools/call` and a code mode script's nested call pass.
  ///
  /// In order: workspace confinement of an attested run, the run grant a tool
  /// may require, the identity the tool needs from the run, the run's scope
  /// forced into [arguments], the conversation-mode guard, the read-only
  /// workspace check, the command policy, the action guard, the
  /// capability-tier approval, and the tool. Result bounding is the caller's:
  /// a model reads a truncated copy, a script gets the tool's own result.
  ///
  /// [nested] is set for a script's call: approval cards carry its origin, are
  /// withdrawn when it is abandoned, and every wait on a person is reported to
  /// its clock. Nothing else differs, so a script is exactly as powerful as
  /// the model calling the same tools one by one.
  Future<_Gated> _gate({
    required String toolName,
    required McpTool tool,
    required McpToolView view,
    required McpCallScope? scope,
    required Map<String, dynamic> arguments,
    required McpCallContext context,
    Future<void>? abandoned,
    _NestedGate? nested,
  }) async {
    // A script's call whose script stopped waiting: the call has already
    // settled, so the gate stops at the next of these checks and the tool
    // never runs. A direct call is never withdrawn here.
    bool gone() => nested?.isWithdrawn() ?? false;
    // An agent run acts only in its grant's workspace. A tool that names no
    // workspace reads or changes something wider (every workspace, the server
    // owner's own data), so a run may not call it at all; every other tool
    // has its `workspace_id` forced from the grant below. An external server's
    // tool is confined by its layer instead: the run could only resolve it
    // because the server is its workspace's, or its accountable owner's.
    if (scope != null &&
        scope.attested &&
        !declaresWorkspace(tool) &&
        !registry.isExternal(tool.name, view: view)) {
      return _GateRefused(
        '${tool.name} is not available to an agent run: it is not confined '
        'to one workspace.',
      );
    }
    if (tool.requiresRunGrant && scope?.attested != true) {
      return _GateRefused(
        '${tool.name} can only be called by a Control Center agent run.',
      );
    }
    // A read-only run (its grant says so, never an argument) calls only what
    // changes nothing; a script's nested call passes here too.
    if ((scope?.readOnly ?? false) &&
        !ReadOnlyRunProfile.admits(tool.name, tool.actionClasses)) {
      return _GateRefused(ReadOnlyRunProfile.refusal(tool.name));
    }
    final missingScope = (scope ?? const McpCallScope()).firstMissing(
      tool.requiredScopeKeys,
    );
    if (missingScope != null) {
      return _GateRefused('${tool.name} requires a session $missingScope.');
    }

    if (scope != null) {
      arguments = scope.apply(
        arguments,
        tool.inputSchema,
        force: tool.forcedScopeKeys,
      );
    }

    // A script may call the tool but not with every argument (one that
    // assigns, starts or messages another agent run): refused before any
    // check that could ask a person, so the call raises no card.
    if (nested != null) {
      if (tool.scriptArgumentRefusal(arguments) case final refusal?) {
        CcMcpLog.w('MCP', '✗ $toolName refused for a script: $refusal');
        return _GateRefused(refusal);
      }
    }

    // Resolve the caller's conversation mode once (server-authoritative) so it
    // can gate the mode allow-list here AND feed the ActionClass guard below
    // without a second DB round-trip. `null` = no conversation to scope to
    // (unrestricted, same as chat).
    //
    // The workspace comes from the transport scope first (dispatch-written, not
    // model-supplied) and only then from the arguments: it selects the database
    // the space/run is looked up in, so without one there is no conversation
    // to resolve a mode from and the gate is skipped. That is not an escape
    // hatch — every workspace-scoped tool requires `workspace_id` itself and
    // rejects the call before touching any data.
    final workspaceArg = arguments['workspace_id'];
    final guardWorkspaceId = switch (scope?.workspaceId) {
      final String s when s.isNotEmpty => s,
      _ => workspaceArg is String ? workspaceArg : '',
    };
    Mode? conversationMode;
    if (modeGuard != null && guardWorkspaceId.isNotEmpty) {
      final spaceId = arguments['space_id'];
      final agentId = arguments['agent_id'];
      conversationMode = await modeGuard!.resolveMode(
        workspaceId: guardWorkspaceId,
        spaceId: spaceId is String ? spaceId : null,
        agentId: agentId is String ? agentId : null,
      );
      if (conversationMode != null &&
          !modeGuard!.isAllowed(toolName, conversationMode)) {
        CcMcpLog.w('MCP', '✗ $toolName blocked by conversation-mode guard');
        return _GateRefused(
          modeGuard!.refusalMessage(toolName, conversationMode),
        );
      }
      if (gone()) {
        return const _GateWithdrawn(Duration.zero);
      }
    }

    if (tool.isMutating &&
        guardWorkspaceId.isNotEmpty &&
        (isWorkspaceReadOnly?.call(guardWorkspaceId) ?? false)) {
      CcMcpLog.w('MCP', '✗ $toolName refused: workspace is read-only');
      return const _GateRefused(
        '$workspaceReadOnlyKind: this workspace is read-only, its database '
        'failed an integrity check; reads still work',
      );
    }

    // Command policy gate (Phase 2.4): for tools whose arguments contain a
    // shell command, evaluate it against the command policy before proceeding.
    if (commandPolicy != null) {
      final cmd = _extractCommand(arguments);
      if (cmd != null && cmd.isNotEmpty) {
        final decision = commandPolicy!.evaluate(cmd);
        if (decision == CommandDecision.deny) {
          CcMcpLog.w('MCP', '✗ $toolName command denied by policy: $cmd');
          return _GateRefused('Command denied by sandbox policy: $cmd');
        }
        // prompt → falls through to the existing requiresApproval gate below
        // when the tool is approval-gated; otherwise logs + proceeds.
        if (decision == CommandDecision.prompt) {
          CcMcpLog.i('MCP', '⚠ $toolName command requires approval: $cmd');
        }
      }
    }

    // Time a script's call spent waiting on a person, and what the gate
    // decided: a person (or their standing approval) allowing it is
    // `approved`, policy alone is `allowed`.
    var waited = Duration.zero;
    var gateDecision = NestedCallGateDecision.allowed;

    // Unified-guardrail effect net (PRD 24). The [ActionGuardService] is the
    // AUTHORITATIVE gate for a tool's DECLARED effect classes: it resolves the
    // workspace's action policy and, for a `prompt` decision, surfaces exactly
    // one confirmation via the ConfirmationPort (fail-closed when no approver
    // is connected) — so the dispatcher never re-prompts for these classes.
    //
    // Composition with the capability-tier gate below: the two nets are
    // independent and both apply. To avoid a DOUBLE confirmation for a tool
    // that is both approval-gated AND declares prompting classes, this guard
    // owns the declared classes (it is the one that prompts), while the tier
    // gate handles the residual per-args capability tier. Pure-read tools
    // (empty `actionClasses`) skip this gate entirely.
    var guardPrompted = false;
    GuardVerdict? guardVerdict;
    final guardRequest = const ActionRequestExtractor().extract(
      arguments,
      classes: tool.actionClasses,
      tool: tool.name,
    );
    final spaceArg = arguments['space_id'];
    final agentArg = arguments['agent_id'];
    final scopeSpaceId = scope?.spaceId;
    final guardSpaceId = scopeSpaceId != null && scopeSpaceId.isNotEmpty
        ? scopeSpaceId
        : (spaceArg is String && spaceArg.isNotEmpty ? spaceArg : null);
    final guardAgentId =
        scope?.agentId ?? (agentArg is String ? agentArg : null);
    // What the call runs, audited whole under the tool's name and digested,
    // on rows that name the caller's run record (`runLogId`) when it is a
    // run. A script's call whose summary the audit could not hold whole is
    // refused, and audited, before policy, a card or its budget.
    final executed = tool.executedContent(arguments);
    final summary = ActionGuardService.toolActionSummary(tool.name, executed);
    if (nested != null) {
      final refusal = actionGuard == null || guardWorkspaceId.isEmpty
          ? ActionGuardService.scriptActionRefusal(summary)
          : actionGuard!.refuseScriptAction(
              workspaceId: guardWorkspaceId,
              classes: tool.actionClasses,
              actionSummary: summary,
              command: executed,
              spaceId: guardSpaceId,
              runId: scope?.runLogId,
              agentId: guardAgentId,
            );
      if (refusal != null) {
        return _GateRefused(refusal);
      }
    }
    if (actionGuard != null && tool.actionClasses.isNotEmpty) {
      // A script's ask is counted with the budget's check, in one step, before
      // the card (so asks that arrive together cannot all pass), or refused
      // without asking once the script may not ask; given back when no card
      // went up. An unforeseen card takes the same step in `beforeCard`.
      var reserved = false;
      String? reserve() {
        final refusal = nested!.approvals.refusal;
        if (refusal == null) {
          nested.approvals.asking();
          reserved = true;
        }
        return refusal;
      }

      if (nested != null) {
        final resolution = await actionGuard!.resolve(
          workspaceId: guardWorkspaceId,
          classes: tool.actionClasses,
          spaceId: guardSpaceId,
          agentId: guardAgentId,
          mode: conversationMode ?? Mode.chat,
          request: guardRequest,
        );
        if (_wouldAsk(resolution)) {
          if (reserve() case final refusal?) {
            actionGuard!.recordOutcome(
              workspaceId: guardWorkspaceId,
              resolution: _budgetDenial(resolution, refusal),
              applied: ActionDecision.deny,
              classes: tool.actionClasses,
              agentId: guardAgentId,
              spaceId: guardSpaceId,
              runId: scope?.runLogId,
              actionSummary: summary,
              command: executed,
            );
            return _GateRefused('Denied by action policy: $refusal');
          }
        }
      }
      // The SPACE, not the conversation: `ActionScopeType.space` policy rules
      // key off a space id, and a conversation id is always its own uuid (the
      // "the main conversation's id IS the space id" convention is dead), so
      // handing the conversation id here made every space-scoped guardrail
      // inert for MCP calls. The transport-derived scope wins over the
      // model-supplied argument — a policy the agent could re-scope by editing
      // an argument is not a policy.
      //
      // The guard asks a person inside `check` and says exactly when, so a
      // script's clock stops only while a person is asked, and that time is
      // the call's wait. Its card names the script.
      final asking = Stopwatch();
      var asked = false;
      final GuardVerdict verdict;
      try {
        verdict = await actionGuard!.check(
          workspaceId: guardWorkspaceId,
          classes: tool.actionClasses,
          spaceId: guardSpaceId,
          runId: scope?.runLogId,
          conversationId: scope?.conversationId,
          agentId: guardAgentId,
          mode: conversationMode ?? Mode.chat,
          actionSummary: tool.name,
          executed: executed,
          // Argument-level authorization: the paths, refs and hosts this call
          // actually names, so a rule can be about "push to feature/*" rather
          // than only about "push". The arguments were always here — they
          // were simply never handed to the resolver.
          request: guardRequest,
          withdrawn: nested?.withdrawn,
          origin: nested?.origin,
          onPersonWait: nested == null
              ? null
              : (waiting) {
                  if (waiting) {
                    asked = true;
                    asking.start();
                    nested.clock.begin();
                  } else {
                    nested.clock.end();
                    asking.stop();
                  }
                },
          beforeCard: nested == null ? null : () => reserved ? null : reserve(),
        );
      } finally {
        if (reserved && !asked) {
          nested?.approvals.release();
        }
      }
      waited += asking.elapsed;
      guardVerdict = verdict;
      if (gone()) {
        return _GateWithdrawn(waited);
      }
      if (asked) {
        nested?.approvals.answered(
          approved: verdict.allowed,
          unanswered: verdict.unanswered,
        );
      }
      if (!verdict.allowed) {
        CcMcpLog.w(
          'MCP',
          '✗ $toolName denied by action policy: ${verdict.reason}',
        );
        return _GateRefused(
          'Denied by action policy: ${verdict.reason}',
          waited: waited,
        );
      }
      // The guard already asked the operator and they approved — record it so
      // the tier gate below does not surface a redundant SECOND confirmation.
      // A person's live standing approval of this tool for these arguments
      // spares it too; a plain allow rule does not.
      guardPrompted =
          verdict.prompted || verdict.standingApprovalCovers(tool: tool.name);
      if (guardPrompted) {
        gateDecision = NestedCallGateDecision.approved;
      }
    }

    // Capability-tier approval gate (PRD 01 phase 1.5). Each tool resolves a
    // per-args tier; the active ApprovalMode decides allow / prompt / deny.
    final approval = tool.toolApproval(arguments);
    final decision = resolveApproval(approval, approvalMode);
    if (decision == ApprovalDecision.deny) {
      CcMcpLog.w('MCP', '✗ $toolName denied by approval policy');
      return _GateRefused(
        'Denied by approval policy (${approval.tier.wire}): $toolName',
        waited: waited,
      );
    }
    if (decision == ApprovalDecision.prompt && !guardPrompted) {
      final payload = tool.buildConfirmationRequest(arguments);
      // A null payload means the tool opts out of confirmation for THESE
      // specific args (e.g. an internal-only space) — proceed silently.
      //
      // A tool that declares no effect class (an external server's tool) was
      // not put to the guard above. Policy is read for it here only to find a
      // person's standing approval of this tool, filed under
      // [ActionGuardService.undeclaredEffect]; a deny there does not refuse
      // the call and a plain allow does not spare the ask.
      var askClasses = tool.actionClasses;
      var resolution = guardVerdict?.resolution;
      var spared = false;
      final guard = actionGuard;
      if (payload != null &&
          askClasses.isEmpty &&
          guard != null &&
          guardWorkspaceId.isNotEmpty) {
        askClasses = ActionGuardService.undeclaredEffect;
        resolution = await guard.resolve(
          workspaceId: guardWorkspaceId,
          classes: askClasses,
          spaceId: guardSpaceId,
          agentId: guardAgentId,
          mode: conversationMode ?? Mode.chat,
          request: guardRequest,
        );
        spared = resolution.standingApprovalCovers(tool: tool.name);
        if (gone()) {
          return _GateWithdrawn(waited);
        }
        if (spared) {
          gateDecision = NestedCallGateDecision.approved;
          guard.recordOutcome(
            workspaceId: guardWorkspaceId,
            resolution: resolution,
            applied: ActionDecision.allow,
            classes: askClasses,
            agentId: guardAgentId,
            spaceId: guardSpaceId,
            runId: scope?.runLogId,
            actionSummary: summary,
            command: executed,
          );
        }
      }
      if (payload != null && !spared) {
        // Fail closed when there is no approver (a headless cc-server has no GUI
        // confirmation port): an approval-gated tool must NEVER run unconfirmed.
        // The local desktop always wires a port and the remote allow-list
        // excludes destructive tools — this guards the headless server path.
        if (confirmationPort == null) {
          CcMcpLog.w(
            'MCP',
            '✗ $toolName requires approval but no approver is connected — denying',
          );
          return _GateRefused(
            'Requires approval but no approver is connected: $toolName',
            waited: waited,
          );
        }
        // A script that may not ask a person any more: refused, not asked.
        if (nested?.approvals.refusal case final refusal?) {
          if ((guard, resolution) case (
            final g?,
            final r?,
          ) when guardWorkspaceId.isNotEmpty) {
            g.recordOutcome(
              workspaceId: guardWorkspaceId,
              resolution: _budgetDenial(r, refusal),
              applied: ActionDecision.deny,
              classes: askClasses,
              agentId: guardAgentId,
              spaceId: guardSpaceId,
              runId: scope?.runLogId,
              actionSummary: summary,
              command: executed,
            );
          }
          return _GateRefused('User denied: $refusal', waited: waited);
        }
        final reason = approval.reason;
        final detail =
            reason != null &&
                reason.trim().isNotEmpty &&
                !reason.startsWith('Policy:')
            ? '${payload.detail}\n\n$reason'
            : payload.detail;
        // The tool asks on its own after policy let the call through. The
        // space and agent are the ones the guard resolved under, so an
        // "Approve for 8 hours" lands where the next call looks for it.
        var unanswered = false;
        final card = ActionGuardService.approvalRequest(
          resolution: resolution,
          classes: askClasses,
          askedByPolicy: false,
          request: guardRequest,
          spaceId: guardSpaceId,
          conversationId: scope?.conversationId,
          workspaceId: guardWorkspaceId.isEmpty ? null : guardWorkspaceId,
          agentId: guardAgentId,
          actionSummary: tool.name,
          title: payload.title,
          detail: detail,
          severity: payload.isDestructive
              ? ConfirmationSeverity.destructive
              : ConfirmationSeverity.warning,
          kind: ConfirmationKind.command,
          withdrawn: nested?.withdrawn,
          origin: nested?.origin,
          runId: scope?.runLogId,
          onUnanswered: () => unanswered = true,
        );
        final asking = Stopwatch()..start();
        nested?.approvals.asking();
        nested?.clock.begin();
        final bool approved;
        try {
          approved = await confirmationPort!.requestApproval(card);
        } finally {
          nested?.clock.end();
        }
        waited += asking.elapsed;
        if (gone()) {
          // Withdrawn, or answered after the script stopped waiting: no
          // person's answer, and the tool never runs.
          return _GateWithdrawn(waited);
        }
        nested?.approvals.answered(approved: approved, unanswered: unanswered);
        if (!approved && unanswered) {
          // Nobody declined it: the card came down unanswered.
          CcMcpLog.w('MCP', '✗ $toolName: $kUnansweredCardReason');
          return _GateRefused(
            'Not run, $kUnansweredCardReason: $toolName',
            waited: waited,
          );
        }
        if (!approved) {
          CcMcpLog.w('MCP', '✗ $toolName denied by user');
          return _GateRefused('User denied: $toolName', waited: waited);
        }
        gateDecision = NestedCallGateDecision.approved;
      }
    }

    // The last check, synchronous with the tool's start: past it the call's
    // outcome is the tool's.
    if (nested != null) {
      if (nested.isWithdrawn()) {
        return _GateWithdrawn(waited);
      }
      nested.onToolStart(gateDecision);
    }
    try {
      CcMcpLog.i('MCP', '→ $toolName ${_formatArgs(arguments)}');
      final sw = Stopwatch()..start();
      // A tool that is a person's time (a question form) holds a script's
      // clock for as long as it runs.
      final personal = nested != null && tool.waitsOnPerson;
      if (personal) {
        nested.clock.begin();
      }
      final CallResult result;
      try {
        result = tool is McpScopedTool
            ? await tool.callScoped(arguments, context, abandoned: abandoned)
            : await tool.call(arguments, abandoned: abandoned);
      } finally {
        if (personal) {
          nested.clock.end();
        }
      }
      sw.stop();
      if (personal) {
        waited += sw.elapsed;
      }
      final summary = result.isError
          ? 'ERROR ${result.content.firstOrNull?.text ?? ''}'
          : 'OK';
      CcMcpLog.d('MCP', '← $toolName ${sw.elapsedMilliseconds}ms $summary');
      return _GateRan(result, gateDecision, waited);
    } catch (e, st) {
      // An *uncaught* tool exception (not a tool-authored validation error) can
      // embed absolute paths, SQL and auth/network detail. Log it locally, but
      // return a generic message — this result is serialized verbatim to remote
      // callers (the phone) as well as local agents. Tool-authored
      // `CallResult.error(...)` validation messages are unaffected; they return
      // normally above and never reach this catch.
      CcMcpLog.e('MCP', '✗ $toolName threw: $e', e, st);
      return _GateThrew(gateDecision, waited);
    }
  }

  /// Runs one call a code mode script made, through the same gate as
  /// `tools/call` ([_gate]), for the run [scope] proves.
  ///
  /// The tool is looked up among what the run's scripts may call
  /// ([scriptToolsFor]); anything else is `unknown_tool`. A call that is
  /// still running when [NestedCallRequest.cancel] fires is `cancelled`, and
  /// one that outlives [NestedCallRequest.deadline] is `timed_out`; either
  /// way the tool is told its caller stopped waiting and an open approval
  /// card is withdrawn. Time spent waiting on a person stops the deadline and
  /// is reported through [NestedCallRequest.onPersonWait]. Never throws.
  @override
  Future<NestedCallOutcome> callNested(
    McpCallScope scope,
    NestedCallRequest request, {
    required ScriptApprovalBudget approvals,
  }) async {
    final started = Stopwatch()..start();
    _emitNested(
      scope,
      ToolCallEvent(
        toolName: request.name,
        toolCallId: request.toolCallId,
        inputs: request.arguments,
        parentToolCallId: request.origin.parentToolCallId,
        // The row's place in the script; nothing below reads it.
        callSite: request.site,
      ),
    );
    NestedCallOutcome outcome;
    try {
      outcome = await _runNested(scope, request, started, approvals);
    } catch (e, st) {
      CcMcpLog.e('MCP', '✗ nested ${request.name} failed: $e', e, st);
      outcome = NestedCallOutcome(
        status: NestedCallStatus.failed,
        errorMessage: 'Internal error executing ${request.name}',
        durationMs: started.elapsedMilliseconds,
      );
    }
    _emitNested(
      scope,
      ToolResultEvent(
        toolCallId: request.toolCallId,
        toolName: request.name,
        outputs: _transcriptText(outcome),
        isError: outcome.status != NestedCallStatus.completed,
        parentToolCallId: request.origin.parentToolCallId,
        // A client tells a refusal, a cancellation or a timeout from a
        // failure by this, never by the text.
        outcome: outcome.status == NestedCallStatus.completed
            ? null
            : outcome.status.wire,
      ),
    );
    return outcome;
  }

  Future<NestedCallOutcome> _runNested(
    McpCallScope scope,
    NestedCallRequest request,
    Stopwatch started,
    ScriptApprovalBudget approvals,
  ) async {
    NestedCallOutcome early(NestedCallStatus status, String message) =>
        NestedCallOutcome(
          status: status,
          errorMessage: message,
          durationMs: started.elapsedMilliseconds,
        );
    if (!scope.attested) {
      return early(
        NestedCallStatus.denied,
        'Tools can be called from a script only in a Control Center agent '
        'run.',
      );
    }
    if (request.cancel.isCancelled) {
      return early(
        NestedCallStatus.cancelled,
        'The script stopped before ${request.name} ran.',
      );
    }
    final view = _viewOf(scope);
    final mode = await _surface.runMode(scope);
    final tool = _surface.scriptCallable(scope, view, mode)[request.name];
    if (tool == null) {
      return early(
        NestedCallStatus.unknownTool,
        registry.lookup(request.name, view: view)?.scriptCallable == false
            ? '"${request.name}" cannot be called from a script. The model '
                  'calls it directly.'
            : 'Unknown tool: "${request.name}" is not callable from a script '
                  'in this run. `ALL_TOOLS` and `searchTools(query)` list what '
                  'is.',
      );
    }

    final settled = Completer<NestedCallOutcome>();
    final abandoned = Completer<void>();
    var toolStarted = false;
    late final NestedCallClock clock;
    void finish(NestedCallOutcome outcome) {
      if (settled.isCompleted) {
        return;
      }
      clock.settle();
      // The tool and any open card hear first that nobody waits any more.
      if (!abandoned.isCompleted) {
        abandoned.complete();
      }
      settled.complete(outcome);
    }

    // The script stopped waiting (it was cancelled, or the deadline passed).
    // While the gate decides, that settles the call and the gate stops at
    // its next check, so the tool never runs. Once the tool has started it
    // only hears it, and the outcome is the tool's: the script and the
    // record never say a tool did not run when it did.
    void withdraw(NestedCallOutcome outcome) {
      // Nobody waits for the call any more: its clock stops, closing an open
      // wait on a person.
      clock.settle();
      if (!abandoned.isCompleted) {
        abandoned.complete();
      }
      if (!toolStarted) {
        finish(outcome);
      }
    }

    clock = NestedCallClock(
      deadline: request.deadline,
      onPersonWait: request.onPersonWait,
      onExpired: () => withdraw(
        NestedCallOutcome(
          status: NestedCallStatus.timedOut,
          errorMessage:
              '${request.name} did not finish within '
              '${request.deadline.inMilliseconds} ms.',
          durationMs: started.elapsedMilliseconds,
          approvalWaitMs: clock.personWait.inMilliseconds,
        ),
      ),
    );
    unawaited(
      request.cancel.whenCancelled.then(
        (_) => withdraw(
          NestedCallOutcome(
            status: NestedCallStatus.cancelled,
            errorMessage: 'The script stopped before ${request.name} finished.',
            durationMs: started.elapsedMilliseconds,
            approvalWaitMs: clock.personWait.inMilliseconds,
          ),
        ),
      ),
    );
    unawaited(
      _gate(
            toolName: request.name,
            tool: tool,
            view: view,
            scope: scope,
            arguments: Map<String, dynamic>.from(request.arguments),
            abandoned: abandoned.future,
            context: McpCallContext(scope: scope, origin: request.origin),
            nested: _NestedGate(
              clock: clock,
              origin: request.origin,
              withdrawn: abandoned.future,
              isWithdrawn: () => abandoned.isCompleted,
              onToolStart: (decision) {
                toolStarted = true;
                // The record keeps the decision of a call that outlives its
                // script, and says its tool was still running.
                request.onToolStarted?.call(decision);
              },
              approvals: approvals,
            ),
          )
          .then(
            (gated) => finish(
              _nestedOutcome(request.name, gated, started.elapsedMilliseconds),
            ),
          )
          .catchError((Object e, StackTrace st) {
            CcMcpLog.e('MCP', '✗ nested ${request.name} failed: $e', e, st);
            finish(
              NestedCallOutcome(
                status: NestedCallStatus.failed,
                errorMessage: 'Internal error executing ${request.name}',
                durationMs: started.elapsedMilliseconds,
              ),
            );
          }),
    );
    return settled.future;
  }

  /// Maps what the gate did to what the script's promise sees.
  static NestedCallOutcome _nestedOutcome(
    String toolName,
    _Gated gated,
    int durationMs,
  ) {
    switch (gated) {
      case _GateWithdrawn(:final waited):
        return NestedCallOutcome(
          status: NestedCallStatus.cancelled,
          errorMessage: 'The script stopped before $toolName ran.',
          durationMs: durationMs,
          approvalWaitMs: waited.inMilliseconds,
        );
      case _GateRefused(:final message, :final waited):
        return NestedCallOutcome(
          status: NestedCallStatus.denied,
          errorMessage: message,
          gateDecision: NestedCallGateDecision.denied,
          durationMs: durationMs,
          approvalWaitMs: waited.inMilliseconds,
        );
      case _GateThrew(:final decision, :final waited):
        return NestedCallOutcome(
          status: NestedCallStatus.failed,
          errorMessage: 'Internal error executing $toolName',
          gateDecision: decision,
          durationMs: durationMs,
          approvalWaitMs: waited.inMilliseconds,
        );
      case _GateRan(:final result, :final decision, :final waited):
        if (result.isError) {
          final message = nestedErrorMessage(toolName, result);
          return NestedCallOutcome(
            status: NestedCallStatus.failed,
            errorMessage: message,
            gateDecision: decision,
            durationMs: durationMs,
            approvalWaitMs: waited.inMilliseconds,
            resultBytes: utf8.encode(message).length,
          );
        }
        final value = nestedResultValue(result);
        final int bytes;
        try {
          bytes = utf8.encode(jsonEncode(value)).length;
        } on JsonUnsupportedObjectError {
          return NestedCallOutcome(
            status: NestedCallStatus.failed,
            errorMessage: '$toolName returned a value that is not JSON.',
            gateDecision: decision,
            durationMs: durationMs,
            approvalWaitMs: waited.inMilliseconds,
          );
        }
        if (bytes > CodeModeLimits.maxNestedResultBytes) {
          return NestedCallOutcome(
            status: NestedCallStatus.failed,
            errorMessage:
                'The result of $toolName is $bytes bytes, more than the '
                '${CodeModeLimits.maxNestedResultBytes} a script can receive. '
                'Narrow the request (a smaller `limit`, a more specific '
                'query) and call again.',
            gateDecision: decision,
            durationMs: durationMs,
            approvalWaitMs: waited.inMilliseconds,
            resultBytes: bytes,
          );
        }
        return NestedCallOutcome(
          status: NestedCallStatus.completed,
          value: value,
          gateDecision: decision,
          durationMs: durationMs,
          approvalWaitMs: waited.inMilliseconds,
          resultBytes: bytes,
        );
    }
  }

  /// The most of a nested result's text (undecoded) the live row shows.
  static const int _maxTranscriptChars = 16 * 1024;

  static String _transcriptText(NestedCallOutcome outcome) {
    final text = outcome.status != NestedCallStatus.completed
        ? outcome.errorMessage ?? outcome.status.wire
        : switch (outcome.value) {
            final String s => s,
            final ScriptJsonText json => json.text,
            final value => jsonEncode(value),
          };
    return text.length <= _maxTranscriptChars
        ? text
        : '${text.substring(0, _maxTranscriptChars)}\n'
              '[${text.length - _maxTranscriptChars} more characters]';
  }

  void _emitNested(McpCallScope scope, AgentProcessEvent event) {
    final sink = nestedEvents;
    final runId = scope.runId;
    if (sink == null || runId == null || runId.isEmpty) {
      return;
    }
    try {
      sink(runId, event);
    } catch (e, st) {
      // The transcript is for reading along; a sink that fails must not fail
      // the call it describes.
      CcMcpLog.e('MCP', '✗ nested event for run $runId not delivered', e, st);
    }
  }

  Map<String, dynamic> _errorResponse(int code, String message, dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    };
  }

  /// The call's arguments for the log line. Values under a sensitive key
  /// (the shared [SensitiveArguments] rule: message bodies, secrets,
  /// tokens) are never logged verbatim, so a `send_space_message` body or a
  /// credential-bearing argument never lands in logs or crash reports.
  String _formatArgs(Map<String, dynamic> args) {
    final parts = args.entries.map((e) {
      if (SensitiveArguments.isSensitiveKey(e.key)) {
        return '${e.key}=${SensitiveArguments.marker}';
      }
      final v = e.value;
      if (v is String && v.length > 80) {
        return '${e.key}="${v.substring(0, 40)}…${v.substring(v.length - 20)}"';
      }
      return '${e.key}=$v';
    });
    return '{${parts.join(', ')}}';
  }

  /// Extracts a shell command string from common MCP tool argument keys.
  /// Returns null when no command-like argument is found.
  static String? _extractCommand(Map<String, dynamic> args) {
    for (final key in const ['command', 'cmd', 'shell_command', 'script']) {
      final value = args[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
}

/// What [McpToolDispatcher._gate] did with a call.
sealed class _Gated {
  const _Gated();
}

/// The gate refused the call; the tool never ran.
final class _GateRefused extends _Gated {
  const _GateRefused(this.message, {this.waited = Duration.zero});

  final String message;

  /// Time a script's call spent waiting on a person before the refusal.
  final Duration waited;
}

/// The tool ran and returned [result].
final class _GateRan extends _Gated {
  const _GateRan(this.result, this.decision, this.waited);

  final CallResult result;
  final NestedCallGateDecision decision;
  final Duration waited;
}

/// The tool threw; its message is not passed on.
final class _GateThrew extends _Gated {
  const _GateThrew(this.decision, this.waited);

  final NestedCallGateDecision decision;
  final Duration waited;
}

/// What the gate needs to know about a code mode script's call.
final class _NestedGate {
  const _NestedGate({
    required this.clock,
    required this.origin,
    required this.withdrawn,
    required this.isWithdrawn,
    required this.onToolStart,
    required this.approvals,
  });

  /// Held while a person is being waited on.
  final NestedCallClock clock;

  /// Put on every approval card the call raises.
  final ScriptCallOrigin origin;

  /// Completes when the script stops waiting for the call: withdraws its
  /// approval card.
  final Future<void> withdrawn;

  /// Whether [withdrawn] has completed: the gate stops at its next check.
  final bool Function() isWithdrawn;

  /// Called synchronously just before the tool runs, with the decision the
  /// call passed: from then on the call's outcome is the tool's.
  final void Function(NestedCallGateDecision decision) onToolStart;

  /// What the call's script may still ask of a person.
  final ScriptApprovalBudget approvals;
}

/// The script stopped waiting while the gate was still deciding; the tool
/// never ran. The call has already settled as cancelled or timed out.
final class _GateWithdrawn extends _Gated {
  const _GateWithdrawn(this.waited);

  final Duration waited;
}
