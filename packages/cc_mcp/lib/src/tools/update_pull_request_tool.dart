import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show AppException;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart';
import 'package:cc_harness/tools.dart';

/// Changes the title and/or description of the calling agent run's own pull
/// request, on the server.
///
/// A run's GitHub token only reads, so `gh pr edit` fails there. The
/// server edits it as whoever opens the run's pull requests: the person who
/// requested the run (their own one-repository token), or the Control Center
/// bot when nobody did. Only an open pull request whose head branch is the
/// run's own (one it pushed, or its space's branch) can be edited. Only an
/// agent run can call it: the run's workspace and conversation come from its
/// own grant, never from the model.
class UpdatePullRequestTool extends McpTool {
  /// Creates an [UpdatePullRequestTool].
  UpdatePullRequestTool({required this._pullRequests});

  final AgentPullRequestPort _pullRequests;

  /// [kAgentUpdatePullRequestTool], spelled out for the ActionClass ratchet.
  @override
  String get name => 'update_pull_request';

  @override
  Set<ActionClass> get actionClasses => const {ActionClass.prPublish};

  @override
  String get description =>
      'Changes the title and/or description of this run\'s own open pull '
      'request (one whose head branch this run pushed, or its space branch). '
      'Use this instead of `gh pr edit`: this run\'s GitHub token is '
      'read-only. The description replaces the whole current one, so read '
      'it first and send it back complete. It is edited as the person who '
      'asked for this run. Answers the pull request URL.';

  /// The run's own workspace and conversation, whatever the model sent.
  @override
  Set<String> get forcedScopeKeys => const {'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {
    'workspace_id',
    'conversation_id',
  };

  /// Headers can name any conversation; only a run's own secret names its
  /// own, and the pull requests it may edit are read from that run.
  @override
  bool get requiresRunGrant => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'Workspace of this run (filled in automatically).',
      },
      'conversation_id': {
        'type': 'string',
        'description': 'This run\'s conversation (filled in automatically).',
      },
      'repo': {
        'type': 'string',
        'description':
            'owner/name of the repository. Omit for the repository of this '
            'run\'s worktree.',
      },
      'number': {
        'type': 'integer',
        'description':
            'The pull request number. Its head branch must be this run\'s.',
      },
      'title': {
        'type': 'string',
        'description':
            'New title (at most ${AgentPullRequestEdit.maxTitleLength} '
            'characters). Omit to keep it.',
      },
      'body': {
        'type': 'string',
        'description':
            'New description (markdown), replacing the current one. Omit to '
            'keep it.',
      },
    },
    'required': ['workspace_id', 'conversation_id', 'number'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    String? text(String key) {
      final value = arguments[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    for (final key in const ['workspace_id', 'conversation_id']) {
      if (text(key) == null) {
        return CallResult.error('Missing or invalid argument: $key');
      }
    }
    final rawNumber = arguments['number'];
    final number = rawNumber is int
        ? rawNumber
        : rawNumber is String
        ? int.tryParse(rawNumber.trim())
        : null;
    if (number == null || number <= 0) {
      return CallResult.error('Missing or invalid argument: number');
    }
    final title = arguments['title'];
    final body = arguments['body'];
    if (title != null && title is! String) {
      return CallResult.error('Invalid argument: title');
    }
    if (body != null && body is! String) {
      return CallResult.error('Invalid argument: body');
    }
    if (title == null && body == null) {
      return CallResult.error('Give a new title, a new body, or both.');
    }
    try {
      final result = await _pullRequests.update(
        AgentPullRequestEdit(
          workspaceId: text('workspace_id')!,
          conversationId: text('conversation_id')!,
          repo: text('repo'),
          number: number,
          title: title as String?,
          body: body as String?,
        ),
      );
      return CallResult.success(jsonEncode(result.toWire()));
    } on AppException catch (e) {
      return CallResult.error(
        'Could not update the pull request: ${e.message}',
      );
    }
  }
}
