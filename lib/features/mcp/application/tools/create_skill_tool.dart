import 'dart:convert';

import 'package:control_center/core/domain/ports/workspace_filesystem_port.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';

class CreateSkillTool extends McpTool {
  CreateSkillTool({required WorkspaceFilesystemPort filesystem})
    : _filesystem = filesystem;

  final WorkspaceFilesystemPort _filesystem;

  @override
  String get name => 'create_skill';

  @override
  String get description =>
      'Creates a new skill in a workspace with the given markdown content.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID to create the skill in.',
      },
      'slug': {
        'type': 'string',
        'description':
            'Unique skill slug (e.g. "code-review", "testing"). '
            'Will be lowercased and hyphenated.',
      },
      'content': {
        'type': 'string',
        'description':
            'Full markdown content for the skill\'s SKILL.md file, '
            'including YAML frontmatter with name and description.',
      },
    },
    'required': ['workspace_id', 'slug', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id (expected string)');
    }
    final rawSlug = arguments['slug'];
    if (rawSlug is! String) {
      return CallResult.error('Missing or invalid argument: slug (expected string)');
    }
    final rawContent = arguments['content'];
    if (rawContent is! String) {
      return CallResult.error('Missing or invalid argument: content (expected string)');
    }
    final workspaceId = rawWorkspaceId;
    final slug = rawSlug;
    final content = rawContent;

    await _filesystem.ensureWorkspaceDirs(workspaceId);
    await _filesystem.writeSkillFile(workspaceId, slug, content);

    return CallResult.success(
      jsonEncode({'slug': slug, 'status': 'created'}),
    );
  }
}
