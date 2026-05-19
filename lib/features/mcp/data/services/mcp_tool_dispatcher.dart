import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/domain/ports/confirmation_port.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/mcp/domain/services/conversation_mode_tool_guard.dart';
import 'package:control_center/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:control_center/features/mcp/domain/value_objects/jsonrpc_message.dart';

/// Mcp tool dispatcher.
class McpToolDispatcher {
  /// Creates a new [Mcp tool dispatcher].
  McpToolDispatcher({
    required this.registry,
    this.modeGuard,
    this.confirmationPort,
  });

  /// Registry of available MCP tools used to handle incoming requests.
  final McpToolRegistry registry;

  /// Optional guard that filters mutating tools out by conversation mode
  /// (review / plan). When null the dispatcher applies no per-mode gating.
  final ConversationModeToolGuard? modeGuard;

  /// Optional port for surfacing destructive-action confirmations.
  /// When null, [McpTool.requiresApproval] is ignored.
  final ConfirmationPort? confirmationPort;

  static const _protocolVersion = mcpProtocolVersion;

  /// Dispatches a JSON-RPC [request] to the appropriate handler and returns the result.
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
          'tools': {'listChanged': false},
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
        AppLog.w('MCP', '✗ $toolName blocked by conversation-mode guard');
        return {
          'jsonrpc': '2.0',
          'id': request.id,
          'result': CallResult.error(rejection).toJson(),
        };
      }
    }

    if (tool.requiresApproval && confirmationPort != null) {
      final payload = tool.buildConfirmationRequest(arguments);
      if (payload != null) {
        final channelId = arguments['channel_id'];
        final approved = await confirmationPort!.requestApproval(
          ConfirmationRequest(
            conversationId: channelId is String ? channelId : '',
            title: payload.title,
            detail: payload.detail,
            severity: payload.isDestructive
                ? ConfirmationSeverity.destructive
                : ConfirmationSeverity.warning,
          ),
        );
        if (!approved) {
          AppLog.w('MCP', '✗ $toolName denied by user');
          return {
            'jsonrpc': '2.0',
            'id': request.id,
            'result':
                CallResult.error('User denied: $toolName').toJson(),
          };
        }
      }
    }

    try {
      AppLog.i('MCP', '→ $toolName ${_formatArgs(arguments)}');
      final sw = Stopwatch()..start();
      final result = await tool.call(arguments);
      sw.stop();
      final summary = result.isError
          ? 'ERROR ${result.content.firstOrNull?.text ?? ''}'
          : 'OK';
      AppLog.d('MCP', '← $toolName ${sw.elapsedMilliseconds}ms $summary');
      return {'jsonrpc': '2.0', 'id': request.id, 'result': result.toJson()};
    } catch (e, st) {
      AppLog.e('MCP', '✗ $toolName threw: $e', e, st);
      return {
        'jsonrpc': '2.0',
        'id': request.id,
        'result': CallResult.error(e.toString()).toJson(),
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

  String _formatArgs(Map<String, dynamic> args) {
    final parts = args.entries.map((e) {
      final v = e.value;
      if (v is String && v.length > 80) {
        return '${e.key}="${v.substring(0, 40)}…${v.substring(v.length - 20)}"';
      }
      return '${e.key}=$v';
    });
    return '{${parts.join(', ')}}';
  }
}

