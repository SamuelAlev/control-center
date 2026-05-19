import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// List repos tool.
///
/// For agent callers the dispatcher injects the call scope and `local_path`
/// then points at the SPACE's isolated working copy — the CoW worktree under
/// the space's shared `repos/` dir — never the original registered checkout.
/// Originals are deliberately not exposed to agents: all changes happen in a
/// worktree and a repo without a working copy reports `local_path: null`
/// instead of falling back to the original path.
///
/// The worktree is resolved by `space_id`, not `conversation_id`.
/// `isolated_repos` is keyed by `space_id` and every conversation in a space
/// shares one copy, so looking it up by conversation matched nothing: this tool
/// reported `local_path: null` for every repo of a space that HAD a checkout.
/// A PR-review lead agent read that as "no working copy is attached to this
/// review" and consolidated the specialists without ever opening the diff.
///
/// `conversation_id` is still accepted, and still means "this is an agent
/// caller, never expose the original checkout" — that guarantee must not
/// depend on which id the caller happened to be scoped by.
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
      'callers local_path is the space-scoped isolated working copy '
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
      'space_id': {
        'type': 'string',
        'description':
            'Space whose isolated working copies to report. Injected '
            'automatically for agent callers; local_path then points at the '
            "space's CoW worktree, never the original checkout.",
      },
      'conversation_id': {
        'type': 'string',
        'description':
            'Conversation the call is scoped to. Injected automatically for '
            'agent callers; it marks the caller as an agent (originals stay '
            'hidden) but the working copy itself is resolved by space_id.',
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
    final rawSpaceId = arguments['space_id'];
    if (rawWorkspaceId is! String || rawWorkspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final workspaceId = rawWorkspaceId;
    final conversationId =
        rawConversationId is String && rawConversationId.isNotEmpty
        ? rawConversationId
        : null;
    final spaceId = rawSpaceId is String && rawSpaceId.isNotEmpty
        ? rawSpaceId
        : null;
    // Either scope id marks an agent caller. Keeping the original checkout
    // hidden is a rule about WHO is asking, so it must not hinge on which of
    // the two ids the call scope happened to carry.
    final isScopedCaller = conversationId != null || spaceId != null;
    final limit = McpTool.clampLimit(arguments, 50);

    final repos = await _repoRepository.getAll(workspaceId);
    final list = <Map<String, dynamic>>[];
    for (final r in repos.take(limit)) {
      final entry = <String, dynamic>{
        'id': r.id,
        // Repo.fullName falls back to the original checkout path for repos
        // without a GitHub remote — never leak that to a scoped caller.
        'full_name': !isScopedCaller || r.hasForgeRemote ? r.fullName : r.name,
      };
      if (!isScopedCaller) {
        entry['local_path'] = r.path;
      } else {
        final worktree = spaceId == null
            ? null
            : await _isolatedRepoRepository.forUnitRepo(
                workspaceId,
                spaceId,
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
    if (isScopedCaller) {
      payload['note'] =
          "local_path is this space's isolated working copy (also reachable "
          'as repos/<name>/ in your working directory). Make all changes '
          'there — the original checkout is never exposed and must never be '
          'modified. A null local_path means the repo has no working copy in '
          'this space.';
    }
    return CallResult.success(jsonEncode(payload));
  }
}
