import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// List spaces tool.
class ListSpacesTool extends McpTool {
  /// Creates a new [List spaces tool].
  ListSpacesTool({required MessagingRepository repository})
    : _repository = repository;

  final MessagingRepository _repository;

  @override
  String get name => 'list_spaces';

  @override
  String get description => 'Lists spaces in a workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace ID to list spaces for.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of spaces to return (default 50).',
        'default': 50,
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final workspaceId = rawWorkspaceId;
    final limit = McpTool.clampLimit(arguments, 50);

    // Workspace-scoped at the query level — never fetch every workspace's
    // spaces and filter in memory.
    final filtered = await _repository
        .watchSpacesByWorkspace(workspaceId)
        .first;

    // Archived spaces are hidden from agents too: the operator shelved them,
    // so they are not rooms to list (or nudge work into). The rows still
    // exist — restore is a human action from the archive dialog.
    final list = filtered
        .where((c) => !c.isArchived)
        .take(limit)
        .map(
          (c) => {
            'id': c.id,
            'name': c.name,
            'workspace_id': c.workspaceId,
            'created_at': c.createdAt.toIso8601String(),
          },
        )
        .toList();

    return CallResult.success(
      jsonEncode({'spaces': list, 'count': list.length}),
    );
  }
}
