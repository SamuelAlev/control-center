import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// List repos tool.
class ListReposTool extends McpTool {
  /// Creates a new [List repos tool].
  ListReposTool({
    required RepoRepository repoRepository,
    required WorkspaceRepository workspaceRepository,
  }) : _repoRepository = repoRepository,
       _workspaceRepository = workspaceRepository;

  final RepoRepository _repoRepository;
  final WorkspaceRepository _workspaceRepository;

  @override
  String get name => 'list_repos';

  @override
  String get description =>
      'Lists repositories, optionally filtered by workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Optional workspace ID to filter repos by.',
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of repos to return (default 50).',
        'default': 50,
      },
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    final rawLimit = arguments['limit'];
    final workspaceId = rawWorkspaceId is String ? rawWorkspaceId : null;
    final limit = rawLimit is int ? rawLimit : 50;

    List<Map<String, dynamic>> list;

    if (workspaceId != null) {
      final repos = await _workspaceRepository.watchReposForWorkspace(workspaceId).first;
      list = repos
          .take(limit)
          .map(
            (r) => {
              'id': r.id,
              'full_name': r.fullName,
              'local_path': r.path,
              'linked_to_workspace': true,
            },
          )
          .toList();
    } else {
      final repos = await _repoRepository.watchAll().first;
      list = repos
          .take(limit)
          .map(
            (r) => {
              'id': r.id,
              'full_name': r.fullName,
              'local_path': r.path,
            },
          )
          .toList();
    }

    return CallResult.success(
      jsonEncode({'repos': list, 'count': list.length}),
    );
  }
}
