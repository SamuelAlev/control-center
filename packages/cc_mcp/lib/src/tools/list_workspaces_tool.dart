import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Lists workspaces: every one for the server owner's own tooling, and only
/// its own for an agent run (the dispatcher forces `workspace_id` from the
/// run's grant).
class ListWorkspacesTool extends McpTool {
  /// Creates a new [List workspaces tool].
  ListWorkspacesTool({required this._repository});

  final WorkspaceRepository _repository;

  @override
  String get name => 'list_workspaces';

  @override
  String get description =>
      'Lists workspaces with their IDs and names. An agent sees only its own.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Only this workspace.'},
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final only = arguments['workspace_id'];
    final workspaces = [
      for (final w in await _repository.watchAll().first)
        if (only is! String || only.isEmpty || w.id == only) w,
    ];

    final list = workspaces
        .map(
          (w) => {
            'id': w.id,
            'name': w.name,
            'created_at': w.createdAt.toIso8601String(),
          },
        )
        .toList();

    return CallResult.success(
      jsonEncode({'workspaces': list, 'count': list.length}),
    );
  }
}
