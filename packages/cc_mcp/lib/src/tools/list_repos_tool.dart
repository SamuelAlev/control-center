import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// List repos tool.
///
/// For agent callers the dispatcher injects `conversation_id` from the call
/// scope, and `local_path` then points at the conversation's ISOLATED working
/// copy — the CoW worktree under the conversation's shared `repos/` dir —
/// never the original registered checkout. Originals are deliberately not
/// exposed to agents: all changes happen in a worktree, and a repo without a
/// working copy in the conversation reports `local_path: null` instead of
/// falling back to the original path.
class ListReposTool extends McpTool {
  /// Creates a new [ListReposTool].
  ListReposTool({
    required RepoRepository repoRepository,
    required IsolatedRepoRepository isolatedRepoRepository,
  }) : _repoRepository = repoRepository,
       _isolatedRepoRepository = isolatedRepoRepository;

  final RepoRepository _repoRepository;
  final IsolatedRepoRepository _isolatedRepoRepository;

  @override
  String get name => 'list_repos';

  @override
  String get description =>
      "Lists a workspace's repositories. For agent "
      'callers local_path is the conversation-scoped isolated working copy '
      '(a copy-on-write worktree, also reachable as repos/<name>/ in the '
      'working directory) — the original checkout is never exposed and must '
      'never be modified.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace whose repos to list.',
      },
      'conversation_id': {
        'type': 'string',
        'description':
            'Conversation whose isolated working copies to report. Injected '
            'automatically for agent callers; local_path then points at the '
            "conversation's CoW worktree, never the original checkout.",
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of repos to return (default 50).',
        'default': 50,
      },
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    final rawConversationId = arguments['conversation_id'];
    final rawLimit = arguments['limit'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final workspaceId = rawWorkspaceId;
    final conversationId =
        rawConversationId is String && rawConversationId.isNotEmpty
        ? rawConversationId
        : null;
    final limit = rawLimit is int ? rawLimit : 50;

    final repos = await _repoRepository.getAll(workspaceId);
    final list = <Map<String, dynamic>>[];
    for (final r in repos.take(limit)) {
      final entry = <String, dynamic>{
        'id': r.id,
        // Repo.fullName falls back to the original checkout path for repos
        // without a GitHub remote — never leak that to a conversation
        // caller.
        'full_name': conversationId == null || r.hasGitHubRemote
            ? r.fullName
            : r.name,
      };
      if (conversationId == null) {
        entry['local_path'] = r.path;
      } else {
        final worktree = await _isolatedRepoRepository.forUnitRepo(
          workspaceId,
          conversationId,
          r.id,
        );
        entry['local_path'] = worktree?.path;
        entry['is_isolated_copy'] = worktree != null;
        if (worktree != null) {
          entry['branch'] = worktree.branch;
        }
      }
      list.add(entry);
    }

    final payload = <String, dynamic>{'repos': list, 'count': list.length};
    if (conversationId != null) {
      payload['note'] =
          "local_path is this conversation's isolated working copy (also "
          'reachable as repos/<name>/ in your working directory). Make all '
          'changes there — the original checkout is never exposed and must '
          'never be modified. A null local_path means the repo has no '
          'working copy in this conversation.';
    }
    return CallResult.success(jsonEncode(payload));
  }
}
