import 'dart:convert';

import 'package:control_center/core/domain/repositories/workspace_repository.dart';
import 'package:control_center/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_generation.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';

/// List pull requests tool.
class ListPullRequestsTool extends McpTool {
  /// Creates a new [List pull requests tool].
  ListPullRequestsTool({
    required PrLifecycleRepository prRepo,
    required WorkspaceRepository workspaceRepo,
  }) : _prRepo = prRepo,
       _workspaceRepo = workspaceRepo;

  final PrLifecycleRepository _prRepo;
  final WorkspaceRepository _workspaceRepo;

  @override
  String get name => 'list_pull_requests';

  @override
  String get description =>
      'Lists pull requests, optionally filtered by workspace and status.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Optional workspace ID to filter by.',
      },
      'status': {
        'type': 'string',
        'description': 'Filter by PR status.',
        'enum': ['draft', 'published', 'created'],
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of PRs to return (default 50).',
        'default': 50,
      },
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    final rawStatus = arguments['status'];
    final rawLimit = arguments['limit'];
    final workspaceId = rawWorkspaceId is String ? rawWorkspaceId : null;
    final status = rawStatus is String ? rawStatus : null;
    final limit = rawLimit is int ? rawLimit : 50;

    List<PrGeneration> prs;

    if (workspaceId != null) {
      final stream = _prRepo.watchByWorkspace(workspaceId);
      prs = (await stream.first).where((pr) {
        if (status != null) {
          return pr.status.name == status;
        }
        return true;
      }).toList();
    } else {
      final workspaces = await _workspaceRepo.watchAll().first;
      prs = <PrGeneration>[];
      for (final w in workspaces) {
        final wPrs = await _prRepo.watchByWorkspace(w.id).first;
        prs.addAll(
          wPrs.where((pr) {
            if (status != null) {
              return pr.status.name == status;
            }
            return true;
          }),
        );
      }
    }

    final list = prs
        .take(limit)
        .map(
          (pr) => {
            'id': pr.id,
            'workspace_id': pr.workspaceId,
            'title': pr.title,
            'status': pr.status.name,
            'created_at': pr.createdAt.toIso8601String(),
          },
        )
        .toList();

    return CallResult.success(
      jsonEncode({'pull_requests': list, 'count': list.length}),
    );
  }
}

