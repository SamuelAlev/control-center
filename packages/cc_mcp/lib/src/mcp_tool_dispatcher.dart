import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_resource_prompt_ports.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';
import 'package:cc_mcp/src/mcp_protocol.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Ceiling on the total characters one tool result may carry back.
///
/// 1 MiB is far above any legitimate answer (the largest real ones are a code
/// search or a message page, both in the low hundreds of KB) and far below the
/// point where it threatens the context window or the relay. Bridged external
/// tools are capped tighter (256 KB, `tool_bridge.dart`) because their output
/// is not ours to trust at all.
const int _maxResultChars = 1024 * 1024;

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
    this.resourceProvider,
    this.promptProvider,
  });

  /// Optional provider exposing MCP resources (`resources/list` + `read`).
  /// When null, the server omits the `resources` capability.
  final McpResourceProvider? resourceProvider;

  /// Optional provider exposing MCP prompts (`prompts/list` + `get`).
  /// When null, the server omits the `prompts` capability.
  final McpPromptProvider? promptProvider;

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

  static const _protocolVersion = mcpProtocolVersion;

  /// Dispatches a JSON-RPC [request] to the appropriate handler and returns the result.
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) =>
      handleScopedRequest(request);

  /// Like [handleRequest], but with a transport-derived identity [scope].
  ///
  /// The loopback MCP HTTP server extracts the scope from the `X-CC-*` headers
  /// dispatch writes into each agent's `.mcp.json`, so `tools/call` arguments
  /// are workspace-forced / identity-filled exactly like the built-in
  /// harness's `McpToolBridge`. Callers without a scope (RPC transport, MCP
  /// Inspector) pass none and arguments flow through verbatim.
  Future<Map<String, dynamic>> handleScopedRequest(
    JsonRpcRequest request, {
    McpCallScope? scope,
  }) async {
    switch (request.method) {
      case 'initialize':
        return _handleInitialize(request);
      case 'notifications/initialized':
        return {}; // No response for notifications
      case 'tools/list':
        return _handleToolsList(request);
      case 'tools/call':
        return _handleToolsCall(request, scope);
      case 'resources/list':
        return _handleResourcesList(request);
      case 'resources/read':
        return _handleResourcesRead(request);
      case 'prompts/list':
        return _handlePromptsList(request);
      case 'prompts/get':
        return _handlePromptsGet(request);
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
          if (resourceProvider != null)
            'resources': {'listChanged': false, 'subscribe': false},
          if (promptProvider != null) 'prompts': {'listChanged': false},
        },
        'instructions':
            'Control Center MCP server. Use tools to manage workspaces, agents, messages and more.',
        '_meta': {'clientName': clientName},
      },
    };
  }

  Map<String, dynamic> _handleToolsList(JsonRpcRequest request) {
    final definitions = registry
        .listDefinitions()
        .map((d) => d.toJson())
        .toList();
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {'tools': definitions},
    };
  }

  Future<Map<String, dynamic>> _handleResourcesList(
    JsonRpcRequest request,
  ) async {
    final provider = resourceProvider;
    if (provider == null) {
      return _errorResponse(-32601, 'Resources not supported', request.id);
    }
    final resources = await provider.listResources();
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {'resources': resources.map((r) => r.toJson()).toList()},
    };
  }

  Future<Map<String, dynamic>> _handleResourcesRead(
    JsonRpcRequest request,
  ) async {
    final provider = resourceProvider;
    if (provider == null) {
      return _errorResponse(-32601, 'Resources not supported', request.id);
    }
    final uri = request.params['uri'];
    if (uri is! String || uri.isEmpty) {
      return _errorResponse(-32602, 'Missing resource uri', request.id);
    }
    final contents = await provider.readResource(uri);
    if (contents == null) {
      return _errorResponse(-32602, 'Unknown resource: $uri', request.id);
    }
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {
        'contents': [contents.toJson()],
      },
    };
  }

  Future<Map<String, dynamic>> _handlePromptsList(
    JsonRpcRequest request,
  ) async {
    final provider = promptProvider;
    if (provider == null) {
      return _errorResponse(-32601, 'Prompts not supported', request.id);
    }
    final prompts = await provider.listPrompts();
    return {
      'jsonrpc': '2.0',
      'id': request.id,
      'result': {'prompts': prompts.map((p) => p.toJson()).toList()},
    };
  }

  Future<Map<String, dynamic>> _handlePromptsGet(JsonRpcRequest request) async {
    final provider = promptProvider;
    if (provider == null) {
      return _errorResponse(-32601, 'Prompts not supported', request.id);
    }
    final name = request.params['name'];
    if (name is! String || name.isEmpty) {
      return _errorResponse(-32602, 'Missing prompt name', request.id);
    }
    final rawArgs = request.params['arguments'];
    final arguments = rawArgs is Map
        ? rawArgs.map((k, v) => MapEntry(k.toString(), '$v'))
        : <String, String>{};
    final result = await provider.getPrompt(name, arguments);
    if (result == null) {
      return _errorResponse(-32602, 'Unknown prompt: $name', request.id);
    }
    return {'jsonrpc': '2.0', 'id': request.id, 'result': result.toJson()};
  }

  /// Caps what one tool call can hand back.
  ///
  /// Nothing bounded a FIRST-PARTY tool's result: `tool_bridge.dart` caps
  /// bridged EXTERNAL tools at 256 KB precisely because their output is not
  /// ours, but a tool in this package could return a 100 MB string — a
  /// `list_articles` with a large `limit`, a code-graph query over a monorepo
  /// — and it went to the model verbatim, through the context window and the
  /// phone's WebSocket alike.
  ///
  /// Truncated with a visible marker rather than refused, and that is the
  /// opposite of the choice made for `git`'s stdout on purpose: the consumer
  /// here is a MODEL that can narrow its query when told the result was cut,
  /// not a parser that would silently misread a short answer.
  ///
  /// Image `data` is DROPPED whole rather than truncated — half a base64
  /// payload is not a smaller image, it is a corrupt one.
  static CallResult _boundResult(String toolName, CallResult result) {
    var budget = _maxResultChars;
    var truncated = false;
    final kept = <CallResultContent>[];
    for (final piece in result.content) {
      final data = piece.data;
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

  Future<Map<String, dynamic>> _handleToolsCall(
    JsonRpcRequest request,
    McpCallScope? scope,
  ) async {
    final toolName = request.params['name'] as String?;
    if (toolName == null || toolName.isEmpty) {
      return _errorResponse(-32602, 'Missing tool name', request.id);
    }

    final tool = registry.resolve(toolName);
    if (tool == null) {
      return _errorResponse(-32602, _unknownToolMessage(toolName), request.id);
    }

    final rawArgs = request.params['arguments'];
    var arguments = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};
    if (scope != null) {
      arguments = scope.apply(arguments, tool.inputSchema);
    }

    // Resolve the caller's conversation mode once (server-authoritative) so it
    // can gate the mode allow-list here AND feed the ActionClass guard below
    // without a second DB round-trip. `null` = no conversation to scope to
    // (unrestricted, same as chat).
    //
    // The workspace comes from the transport scope first (dispatch-written, not
    // model-supplied) and only then from the arguments: it selects the database
    // the channel/run is looked up in, so without one there is no conversation
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
      final channelId = arguments['channel_id'];
      final agentId = arguments['agent_id'];
      conversationMode = await modeGuard!.resolveMode(
        workspaceId: guardWorkspaceId,
        channelId: channelId is String ? channelId : null,
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
    if (actionGuard != null && tool.actionClasses.isNotEmpty) {
      final channelArg = arguments['channel_id'];
      final agentArg = arguments['agent_id'];
      final verdict = await actionGuard!.check(
        workspaceId: guardWorkspaceId,
        classes: tool.actionClasses,
        channelId:
            scope?.conversationId ?? (channelArg is String ? channelArg : null),
        agentId: scope?.agentId ?? (agentArg is String ? agentArg : null),
        mode: conversationMode ?? Mode.chat,
        actionSummary: tool.name,
      );
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
      guardPrompted = verdict.prompted;
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
      // specific args (e.g. an internal-only channel) — proceed silently.
      if (payload != null) {
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
        final channelId = arguments['channel_id'];
        final wsId = arguments['workspace_id'];
        final detail = approval.reason != null
            ? '${payload.detail}\n\n${approval.reason}'
            : payload.detail;
        final approved = await confirmationPort!.requestApproval(
          ConfirmationRequest(
            conversationId: channelId is String ? channelId : '',
            workspaceId: wsId is String && wsId.isNotEmpty ? wsId : null,
            title: payload.title,
            detail: detail,
            severity: payload.isDestructive
                ? ConfirmationSeverity.destructive
                : ConfirmationSeverity.warning,
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
      final result = await tool.call(arguments);
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
  String _unknownToolMessage(String requested) {
    final names = registry.listDefinitions().map((d) => d.name).toList();
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
  /// secrets, tokens. Logged as `‹redacted›` so a `send_channel_message` body or
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
