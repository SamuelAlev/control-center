import 'dart:convert';

import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// List workspaces tool.
class ListWorkspacesTool extends McpTool {
  /// Creates a new [List workspaces tool].
  ListWorkspacesTool({required WorkspaceRepository repository})
    : _repository = repository;

  final WorkspaceRepository _repository;

  @override
  String get name => 'list_workspaces';

  @override
  String get description =>
      'Lists all workspaces with their IDs and names.';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaces = await _repository.watchAll().first;

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
