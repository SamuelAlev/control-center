import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_storage_state.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_request_extractor.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';
import 'package:cc_mcp/src/mcp_protocol.dart';
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
class McpToolDispatcher implements RpcDispatcher {
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
        return _handleInitialize(request);
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

  Map<String, dynamic> _handleInitialize(JsonRpcRequest request) {
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
        'instructions':
            'Control Center MCP server. Use tools to manage workspaces, agents, messages and more.',
        '_meta': {'clientName': clientName},
      },
    };
  }

  Map<String, dynamic> _handleToolsList(
    JsonRpcRequest request,
    McpCallScope? scope,
  ) {
    // External servers only for an attested run, and only its own: its
    // workspace's configured servers, plus the owner's personal ones when its
    // grant says the owner is accountable for it. The owner's token and paired
    // devices see the shared tools alone (`McpCallScope.toolView`).
    final definitions = registry
        .listDefinitions(view: _viewOf(scope))
        .map((d) => d.toJson())
        .toList();
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {'tools': definitions},
    };
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
        _unknownToolMessage(toolName, view),
        request.id,
      );
    }
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
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(
          '${tool.name} is not available to an agent run: it is not confined '
          'to one workspace.',
        ).toJson(),
      };
    }
    if (tool.requiresRunGrant && scope?.attested != true) {
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(
          '${tool.name} can only be called by a Control Center agent run.',
        ).toJson(),
      };
    }
    final missingScope = (scope ?? const McpCallScope()).firstMissing(
      tool.requiredScopeKeys,
    );
    if (missingScope != null) {
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(
          '${tool.name} requires a session $missingScope.',
        ).toJson(),
      };
    }

    final rawArgs = request.params['arguments'];
    var arguments = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};
    if (scope != null) {
      arguments = scope.apply(
        arguments,
        tool.inputSchema,
        force: tool.forcedScopeKeys,
      );
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
        return {
          'jsonrpc': '2.0',
          'id': request.id,
          'result': CallResult.error(
            modeGuard!.refusalMessage(toolName, conversationMode),
          ).toJson(),
        };
      }
    }

    if (tool.isMutating &&
        guardWorkspaceId.isNotEmpty &&
        (isWorkspaceReadOnly?.call(guardWorkspaceId) ?? false)) {
      CcMcpLog.w('MCP', '✗ $toolName refused: workspace is read-only');
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(
          '$workspaceReadOnlyKind: this workspace is read-only, its database '
          'failed an integrity check; reads still work',
        ).toJson(),
      };
    }

    // Command policy gate (Phase 2.4): for tools whose arguments contain a
    // shell command, evaluate it against the command policy before proceeding.
    if (commandPolicy != null) {
      final cmd = _extractCommand(arguments);
      if (cmd != null && cmd.isNotEmpty) {
        final decision = commandPolicy!.evaluate(cmd);
        if (decision == CommandDecision.deny) {
          CcMcpLog.w('MCP', '✗ $toolName command denied by policy: $cmd');
          return {
            'jsonrpc': '2.0',
            'id': request.id,
            'result': CallResult.error(
              'Command denied by sandbox policy: $cmd',
            ).toJson(),
          };
        }
        // prompt → falls through to the existing requiresApproval gate below
        // when the tool is approval-gated; otherwise logs + proceeds.
        if (decision == CommandDecision.prompt) {
          CcMcpLog.i('MCP', '⚠ $toolName command requires approval: $cmd');
        }
      }
    }

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
    if (actionGuard != null && tool.actionClasses.isNotEmpty) {
      // The SPACE, not the conversation: `ActionScopeType.space` policy rules
      // key off a space id, and a conversation id is always its own uuid (the
      // "the main conversation's id IS the space id" convention is dead), so
      // handing the conversation id here made every space-scoped guardrail
      // inert for MCP calls. The transport-derived scope wins over the
      // model-supplied argument — a policy the agent could re-scope by editing
      // an argument is not a policy.
      final verdict = await actionGuard!.check(
        workspaceId: guardWorkspaceId,
        classes: tool.actionClasses,
        spaceId: guardSpaceId,
        conversationId: scope?.conversationId,
        agentId: guardAgentId,
        mode: conversationMode ?? Mode.chat,
        actionSummary: tool.name,
        // Argument-level authorization: the paths, refs and hosts this call
        // actually names, so a rule can be about "push to feature/*" rather
        // than only about "push". The arguments were always here — they were
        // simply never handed to the resolver.
        request: guardRequest,
      );
      guardVerdict = verdict;
      if (!verdict.allowed) {
        CcMcpLog.w(
          'MCP',
          '✗ $toolName denied by action policy: ${verdict.reason}',
        );
        return {
          'jsonrpc': '2.0',
          'id': request.id,
          'result': CallResult.error(
            'Denied by action policy: ${verdict.reason}',
          ).toJson(),
        };
      }
      // The guard already asked the operator and they approved — record it so
      // the tier gate below does not surface a redundant SECOND confirmation.
      // A person's live standing approval of this tool for these arguments
      // spares it too; a plain allow rule does not.
      guardPrompted =
          verdict.prompted || verdict.standingApprovalCovers(tool: tool.name);
    }

    // Capability-tier approval gate (PRD 01 phase 1.5). Each tool resolves a
    // per-args tier; the active ApprovalMode decides allow / prompt / deny.
    final approval = tool.toolApproval(arguments);
    final decision = resolveApproval(approval, approvalMode);
    if (decision == ApprovalDecision.deny) {
      CcMcpLog.w('MCP', '✗ $toolName denied by approval policy');
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(
          'Denied by approval policy (${approval.tier.wire}): $toolName',
        ).toJson(),
      };
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
        if (spared) {
          guard.recordOutcome(
            workspaceId: guardWorkspaceId,
            resolution: resolution,
            applied: ActionDecision.allow,
            classes: askClasses,
            agentId: guardAgentId,
            spaceId: guardSpaceId,
            actionSummary: tool.name,
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
          return {
            'jsonrpc': '2.0',
            'id': request.id,
            'result': CallResult.error(
              'Requires approval but no approver is connected: $toolName',
            ).toJson(),
          };
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
        final approved = await confirmationPort!.requestApproval(
          ActionGuardService.approvalRequest(
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
          ),
        );
        if (!approved) {
          CcMcpLog.w('MCP', '✗ $toolName denied by user');
          return {
            'jsonrpc': '2.0',
            'id': request.id,
            'result': CallResult.error('User denied: $toolName').toJson(),
          };
        }
      }
    }

    try {
      CcMcpLog.i('MCP', '→ $toolName ${_formatArgs(arguments)}');
      final sw = Stopwatch()..start();
      final result = await tool.call(arguments, abandoned: abandoned);
      sw.stop();
      final summary = result.isError
          ? 'ERROR ${result.content.firstOrNull?.text ?? ''}'
          : 'OK';
      CcMcpLog.d('MCP', '← $toolName ${sw.elapsedMilliseconds}ms $summary');
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': _boundResult(toolName, result).toJson(),
      };
    } catch (e, st) {
      // An *uncaught* tool exception (not a tool-authored validation error) can
      // embed absolute paths, SQL and auth/network detail. Log it locally, but
      // return a generic message — this result is serialized verbatim to remote
      // callers (the phone) as well as local agents. Tool-authored
      // `CallResult.error(...)` validation messages are unaffected; they return
      // normally above and never reach this catch.
      CcMcpLog.e('MCP', '✗ $toolName threw: $e', e, st);
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(
          'Internal error executing $toolName',
        ).toJson(),
      };
    }
  }

  /// Builds a rich "unknown tool" message: names the nearest catalogued tools,
  /// points at the discovery tools and explains the bare-name/prefix
  /// convention — so a wrong name is a one-shot correction, not a dead end.
  String _unknownToolMessage(String requested, McpToolView view) {
    final names = registry
        .listDefinitions(view: view)
        .map((d) => d.name)
        .toList();
    final wanted = _nameTokens(requested);
    final lowered = requested.toLowerCase();
    final scored = <MapEntry<String, int>>[];
    for (final name in names) {
      var score = _nameTokens(name).where(wanted.contains).length;
      final ln = name.toLowerCase();
      if (ln.contains(lowered) || lowered.contains(ln)) {
        score += 2;
      }
      if (score > 0) {
        scored.add(MapEntry(name, score));
      }
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    final suggestions = scored.take(5).map((e) => e.key).toList();

    final buf = StringBuffer('Unknown tool: "$requested".');
    if (suggestions.isNotEmpty) {
      buf.write(' Did you mean: ${suggestions.join(', ')}?');
    }
    buf.write(
      ' Call `search_tool_bm25` to find a tool by intent, or `list_my_tools` '
      'to see every tool you can call right now. Address tools by their bare '
      'name (e.g. `todo_write`); your client may display them under a server '
      'prefix such as `mcp__control-center__` — the server resolves either '
      'form.',
    );
    return buf.toString();
  }

  /// Name-noise tokens dropped before nearest-name matching (the server
  /// namespace an over-eager client may bake into the name).
  static const _nameNoiseTokens = {'mcp', 'control', 'center', 'cc'};

  static List<String> _nameTokens(String name) {
    final cleaned = name.replaceAll(RegExp('[^A-Za-z0-9]+'), ' ').toLowerCase();
    return cleaned
        .split(' ')
        .where((t) => t.isNotEmpty && !_nameNoiseTokens.contains(t))
        .toList();
  }

  Map<String, dynamic> _errorResponse(int code, String message, dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'error': {'code': code, 'message': message},
    };
  }

  /// Argument keys whose values must never be logged verbatim — message bodies,
  /// secrets, tokens. Logged as `‹redacted›` so a `send_space_message` body or
  /// a credential-bearing arg never lands in logs/Sentry.
  static const _sensitiveArgKeys = {
    'content',
    'body',
    'message',
    'text',
    'token',
    'secret',
    'psk',
    'password',
    'authorization',
    'api_key',
    'apikey',
    'credential',
  };

  static bool _isSensitiveArg(String key) {
    final k = key.toLowerCase();
    return _sensitiveArgKeys.any(k.contains);
  }

  String _formatArgs(Map<String, dynamic> args) {
    final parts = args.entries.map((e) {
      if (_isSensitiveArg(e.key)) {
        return '${e.key}=‹redacted›';
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
