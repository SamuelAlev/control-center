import 'dart:convert';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

/// MCP tool that lists all skill slugs available in a workspace.
class ListSkillsTool extends McpTool {

  /// Creates a [ListSkillsTool].
  ListSkillsTool({required WorkspaceFilesystemPort filesystem})
    : _filesystem = filesystem;

  final WorkspaceFilesystemPort _filesystem;

  @override
  String get name => 'list_skills';

  @override
  String get description =>
      'Lists all skill slugs available in a workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID to list skills for.',
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id (expected string)');
    }
    final workspaceId = rawWorkspaceId;
    final slugs = await _filesystem.listSkillSlugs(workspaceId);

    return CallResult.success(
      jsonEncode({'skills': slugs, 'count': slugs.length}),
    );
  }
}
