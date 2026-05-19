import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_mcp_client/src/background_process/background_process_manager.dart';

/// MCP tool exposing the [BackgroundProcessManager] to agents
/// (`start | list | status | logs | stop | restart`).
///
/// `start`/`restart` are `exec`-tier (they spawn arbitrary processes) and are
/// refused while the sandbox is enabled; the read-only actions are `read`-tier.
class BackgroundProcessTool extends McpTool {
  /// Creates a [BackgroundProcessTool] over [manager].
  BackgroundProcessTool({required BackgroundProcessManager manager})
    : _manager = manager;

  final BackgroundProcessManager _manager;

  @override
  String get name => 'background_process';

  @override
  String get description =>
      'Manage long-running background processes (dev servers, watchers, log '
      'tails). Actions: start (spawn a command, optional readiness probe), '
      'list, status, logs, stop, restart. Processes are auto-stopped when the '
      'session ends. start/restart are blocked while the sandbox is enabled.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'action': {
        'type': 'string',
        'enum': ['start', 'list', 'status', 'logs', 'stop', 'restart'],
        'description': 'The operation to perform.',
      },
      'command': {
        'type': 'string',
        'description': 'Shell command to run (required for start).',
      },
      'id': {
        'type': 'string',
        'description':
            'Process id (required for status/logs/stop/restart).',
      },
      'cwd': {
        'type': 'string',
        'description': 'Working directory (start; defaults to the run dir).',
      },
      'description': {
        'type': 'string',
        'description': 'Short label shown in the process list.',
      },
      'tail_lines': {
        'type': 'integer',
        'description': 'For logs: return only the last N lines.',
      },
      'ready': {
        'type': 'object',
        'description':
            'Optional readiness probe: {pattern?: regex on output, '
            'port?: TCP port, timeout_ms?: number}.',
        'properties': {
          'pattern': {'type': 'string'},
          'port': {'type': 'integer'},
          'timeout_ms': {'type': 'integer'},
        },
      },
    },
    'required': ['action'],
  };

  @override
  bool get requiresApproval => true;

  @override
  ToolApproval toolApproval(Map<String, dynamic> arguments) {
    final action = arguments['action'];
    if (action == 'start' || action == 'restart') {
      return const ToolApproval(
        CapabilityTier.exec,
        reason: 'Spawns a background process.',
      );
    }
    return ToolApproval.read;
  }

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    final action = arguments['action'];
    if (action != 'start' && action != 'restart') {
      return null; // read-only actions never prompt
    }
    return ApprovalPayload(
      title: 'Start background process',
      detail: 'Command: ${arguments['command'] ?? arguments['id'] ?? ''}',
      isDestructive: false,
    );
  }

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final action = arguments['action'];
    if (action is! String) {
      return CallResult.error('Missing or invalid argument: action');
    }
    try {
      switch (action) {
        case 'start':
          final command = arguments['command'];
          if (command is! String || command.trim().isEmpty) {
            return CallResult.error('start requires a non-empty "command"');
          }
          final info = await _manager.start(
            command: command,
            cwd: arguments['cwd'] as String?,
            description: arguments['description'] as String?,
            ready: ReadyProbe.fromJson(arguments['ready']),
          );
          return CallResult.success(jsonEncode(info.toJson()));
        case 'list':
          final list = _manager.list().map((p) => p.toJson()).toList();
          return CallResult.success(
            jsonEncode({'processes': list, 'count': list.length}),
          );
        case 'status':
          final id = arguments['id'];
          if (id is! String) {
            return CallResult.error('status requires "id"');
          }
          final info = _manager.status(id);
          return info == null
              ? CallResult.error('unknown process: $id')
              : CallResult.success(jsonEncode(info.toJson()));
        case 'logs':
          final id = arguments['id'];
          if (id is! String) {
            return CallResult.error('logs requires "id"');
          }
          final logs = _manager.logs(
            id,
            tailLines: (arguments['tail_lines'] as num?)?.toInt(),
          );
          return logs == null
              ? CallResult.error('unknown process: $id')
              : CallResult.success(logs);
        case 'stop':
          final id = arguments['id'];
          if (id is! String) {
            return CallResult.error('stop requires "id"');
          }
          final info = await _manager.stop(id);
          return info == null
              ? CallResult.error('unknown process: $id')
              : CallResult.success(jsonEncode(info.toJson()));
        case 'restart':
          final id = arguments['id'];
          if (id is! String) {
            return CallResult.error('restart requires "id"');
          }
          final info = await _manager.restart(
            id,
            ready: ReadyProbe.fromJson(arguments['ready']),
          );
          return info == null
              ? CallResult.error('unknown process: $id')
              : CallResult.success(jsonEncode(info.toJson()));
        default:
          return CallResult.error('unknown action: $action');
      }
    } on BackgroundProcessException catch (e) {
      return CallResult.error(e.message);
    }
  }
}
