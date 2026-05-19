import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/services/mode_tool_guard.dart';

/// The authoritative "what can I actually call right now" tool.
///
/// `tools/list` and `search_tool_bm25` return the whole catalogue — but a tool
/// being *catalogued* does not mean it is *callable in this conversation*: the
/// conversation-mode guard restricts mutating tools in plan / review /
/// orchestrate mode. Agents used to discover that only by calling a tool and
/// getting rejected. This tool answers the question up front: it partitions the
/// catalogue into what you can call now and what is restricted (with the reason
/// for each), for the caller's actual conversation mode.
///
/// `read`-tier — inspection only, never prompts.
class ListMyToolsTool extends McpTool {
  /// Creates a [ListMyToolsTool] over [catalog], classified by [modeGuard].
  ListMyToolsTool({required ToolCatalog catalog, ModeToolGuard? modeGuard})
    : _catalog = catalog,
      _modeGuard = modeGuard;

  final ToolCatalog _catalog;
  final ModeToolGuard? _modeGuard;

  /// The canonical name agents call.
  static const String toolName = 'list_my_tools';

  @override
  String get name => toolName;

  @override
  String get description =>
      'List the tools you can actually call right now, in THIS conversation. '
      'Unlike tools/list (the full catalogue) or search_tool_bm25, this '
      'reflects your conversation mode: some tools are restricted in '
      'plan/review/orchestrate mode. Returns your available tools (name + what '
      'each does) and, separately, the restricted ones with the reason. Call a '
      'tool by the `name` shown here.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      // Both are injected automatically from the session scope for a
      // dispatched agent; they only determine which conversation's mode to
      // read, so they are safe to omit.
      'workspace_id': {
        'type': 'string',
        'description':
            'Your workspace id (auto-injected). Determines which '
            "conversation's mode gates the catalogue.",
      },
      'agent_id': {
        'type': 'string',
        'description': 'Your agent id (auto-injected).',
      },
      'channel_id': {
        'type': 'string',
        'description': 'The conversation id (auto-injected).',
      },
    },
    'required': const <String>[],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final definitions = _catalog.allToolDefinitions();
    final agentId = arguments['agent_id'];
    final channelId = arguments['channel_id'];
    final workspaceId = arguments['workspace_id'];
    final guard = _modeGuard;
    // The channel whose mode gates the catalogue lives in one workspace's
    // database, so without a workspace there is no mode to resolve. Listing then
    // reports every tool as callable, which is honest: this tool only *describes*
    // the catalogue and each tool it names enforces its own workspace and gate
    // when actually invoked.
    final Mode? mode = (workspaceId is String && workspaceId.isNotEmpty)
        ? await guard?.resolveMode(
            workspaceId: workspaceId,
            agentId: agentId is String ? agentId : null,
            channelId: channelId is String ? channelId : null,
          )
        : null;

    final available = <Map<String, dynamic>>[];
    final restricted = <Map<String, dynamic>>[];
    for (final def in definitions) {
      // No guard / no conversation to scope to → everything is callable.
      if (guard == null || mode == null || guard.isAllowed(def.name, mode)) {
        available.add({
          'name': def.name,
          'description': _summary(def.description),
        });
      } else {
        restricted.add({
          'name': def.name,
          'reason': guard.refusalMessage(def.name, mode),
        });
      }
    }
    available.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    restricted.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );

    return CallResult.success(
      jsonEncode({
        'conversation_mode': mode?.name ?? 'chat',
        'total_tools': definitions.length,
        'available_count': available.length,
        'restricted_count': restricted.length,
        'available': available,
        'restricted': restricted,
        'note': restricted.isEmpty
            ? 'Every catalogued tool is callable in this conversation.'
            : 'The "restricted" tools are catalogued but blocked in '
                  '${mode?.name ?? 'this'} mode — see each reason.',
      }),
    );
  }

  /// One compact line of a tool's description (bounded so a full listing stays
  /// readable).
  static String _summary(String description) {
    final trimmed = description.trim();
    if (trimmed.length <= 160) {
      return trimmed;
    }
    return '${trimmed.substring(0, 157)}…';
  }
}
