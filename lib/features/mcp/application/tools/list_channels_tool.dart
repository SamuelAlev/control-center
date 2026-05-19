import 'dart:convert';

import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';

/// List channels tool.
class ListChannelsTool extends McpTool {
  /// Creates a new [List channels tool].
  ListChannelsTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'list_channels';

  @override
  String get description =>
      'Lists messaging channels in a workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace ID to list channels for.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of channels to return (default 50).',
        'default': 50,
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    final rawLimit = arguments['limit'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final workspaceId = rawWorkspaceId;
    final limit = rawLimit is int ? rawLimit : 50;

    // Workspace-scoped at the query level — never fetch every workspace's
    // channels and filter in memory.
    final filtered =
        await _repository.watchChannelsByWorkspace(workspaceId).first;

    final list = filtered
        .take(limit)
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'is_dm': c.isDm,
            'workspace_id': c.workspaceId,
            'created_at': c.createdAt.toIso8601String(),
          },
        )
        .toList();

    return CallResult.success(
      jsonEncode({'channels': list, 'count': list.length}),
    );
  }
}
