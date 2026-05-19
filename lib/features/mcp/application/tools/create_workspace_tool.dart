import 'dart:convert';

import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:uuid/uuid.dart';

/// Create workspace tool.
class CreateWorkspaceTool extends McpTool {
  /// Creates a new [Create workspace tool].
  CreateWorkspaceTool({required WorkspaceRepository repository})
    : _repository = repository;

  final WorkspaceRepository _repository;

  @override
  String get name => 'create_workspace';

  @override
  String get description =>
      'Creates a new workspace with the given name and optional repo links.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'Workspace display name.'},
      'repo_ids': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Optional list of repository IDs to link.',
      },
    },
    'required': ['name'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawName = arguments['name'];
    if (rawName is! String) {
      return CallResult.error('Missing or invalid argument: name (expected string)');
    }
    final rawRepoIds = arguments['repo_ids'];
    final name = rawName;
    final repoIds =
        (rawRepoIds is List)
            ? rawRepoIds.map((r) => r.toString()).toList()
            : <String>[];

    final now = DateTime.now();

    final workspace = Workspace(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _repository.upsert(workspace);

    if (repoIds.isNotEmpty) {
      await _repository.setReposForWorkspace(workspace.id, repoIds);
    }

    return CallResult.success(
      jsonEncode({
        'id': workspace.id,
        'name': workspace.name,
        'linked_repos': repoIds.length,
      }),
    );
  }
}
