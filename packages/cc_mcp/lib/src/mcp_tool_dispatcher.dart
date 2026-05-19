import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_resource_prompt_ports.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/conversation_mode_tool_guard.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/sandboxing/domain/command_policy/command_policy.dart';
import 'package:cc_mcp/src/log/cc_mcp_log.dart';
import 'package:cc_mcp/src/mcp_protocol.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Mcp tool dispatcher.
class McpToolDispatcher implements RpcDispatcher {
  /// Creates a new [Mcp tool dispatcher].
  McpToolDispatcher({
    required this.registry,
    this.modeGuard,
    this.confirmationPort,
    this.commandPolicy,
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
  final ConversationModeToolGuard? modeGuard;

  /// Optional command policy for shell-command-producing tools. When set,
  /// the dispatcher extracts the command string from common argument keys
  /// (`command`, `cmd`) and evaluates it: deny→error, prompt→approval,
  /// allow→proceed.
  final CommandPolicy? commandPolicy;

  /// Optional port for surfacing destructive-action confirmations.
  /// When null, [McpTool.requiresApproval] is ignored.
  final ConfirmationPort? confirmationPort;

  static const _protocolVersion = mcpProtocolVersion;

  /// Dispatches a JSON-RPC [request] to the appropriate handler and returns the result.
  @override
  Future<Map<String, dynamic>> handleRequest(JsonRpcRequest request) async {
    switch (request.method) {
      case 'initialize':
        return _handleInitialize(request);
      case 'notifications/initialized':
        return {}; // No response for notifications
      case 'tools/list':
        return _handleToolsList(request);
      case 'tools/call':
        return _handleToolsCall(request);
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
        'serverInfo': {'name': 'control-center', 'version': '0.1.0'},
        'capabilities': {
          'tools': {'listChanged': true},
          if (resourceProvider != null)
            'resources': {'listChanged': false, 'subscribe': false},
          if (promptProvider != null) 'prompts': {'listChanged': false},
        },
        'instructions':
            'Control Center MCP server. Use tools to manage workspaces, agents, messages, and more.',
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

  Future<Map<String, dynamic>> _handleToolsCall(JsonRpcRequest request) async {
    final toolName = request.params['name'] as String?;
    if (toolName == null || toolName.isEmpty) {
      return _errorResponse(-32602, 'Missing tool name', request.id);
    }

    final tool = registry.lookup(toolName);
    if (tool == null) {
      return _errorResponse(-32602, 'Unknown tool: $toolName', request.id);
    }

    final rawArgs = request.params['arguments'];
    final arguments = rawArgs is Map
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};

    if (modeGuard != null) {
      final channelId = arguments['channel_id'];
      final agentId = arguments['agent_id'];
      final rejection = await modeGuard!.rejectIfDisallowed(
        toolName,
        channelId: channelId is String ? channelId : null,
        agentId: agentId is String ? agentId : null,
      );
      if (rejection != null) {
        CcMcpLog.w('MCP', '✗ $toolName blocked by conversation-mode guard');
        return {
          'jsonrpc': '2.0',
          'id': request.id,
          'result': CallResult.error(rejection).toJson(),
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
    if (decision == ApprovalDecision.prompt) {
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
        final detail = approval.reason != null
            ? '${payload.detail}\n\n${approval.reason}'
            : payload.detail;
        final approved = await confirmationPort!.requestApproval(
          ConfirmationRequest(
            conversationId: channelId is String ? channelId : '',
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
      return {'jsonrpc': '2.0', 'id': request.id, 'result': result.toJson()};
    } catch (e, st) {
      // An *uncaught* tool exception (not a tool-authored validation error) can
      // embed absolute paths, SQL, and auth/network detail. Log it locally, but
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
