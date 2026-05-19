import 'dart:convert';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_harness/tools.dart';
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
  Set<ActionClass> get actionClasses => const {ActionClass.workspaceMutation};

  @override
  String get description =>
      'Creates a new empty workspace with the given name. Repos are added to a '
      'workspace afterwards from a local checkout path, not by id.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'name': {'type': 'string', 'description': 'Workspace display name.'},
    },
    'required': ['name'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawName = arguments['name'];
    if (rawName is! String) {
      return CallResult.error(
        'Missing or invalid argument: name (expected string)',
      );
    }
    final name = rawName;

    final now = DateTime.now();

    final workspace = Workspace(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await _repository.upsert(workspace);

    return CallResult.success(
      jsonEncode({'id': workspace.id, 'name': workspace.name}),
    );
  }
}
