import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show AppException;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_comment_port.dart';
import 'package:cc_harness/tools.dart';

/// Comments on the calling agent run's own pull request, on the server.
///
/// A run's GitHub token only reads, so `gh pr comment` fails there.
/// The server posts the comment as the Control Center bot (bounded by the
/// person who requested the run), and only on a pull request whose head
/// branch is the run's own: one it pushed, or its space's branch. Only an
/// agent run can call it: the run's workspace and conversation come from its
/// own grant, never from the model.
class CommentOnPullRequestTool extends McpTool {
  /// Creates a [CommentOnPullRequestTool].
  CommentOnPullRequestTool({required this._comments});

  final AgentPullRequestCommentPort _comments;

  /// [kAgentCommentOnPullRequestTool], spelled out for the ActionClass
  /// ratchet.
  @override
  String get name => 'comment_on_pull_request';

  @override
  Set<ActionClass> get actionClasses => const {ActionClass.prPublish};

  @override
  String get description =>
      'Posts a comment on the conversation of this run\'s own pull request '
      '(one whose head branch this run pushed, or its space branch), as the '
      'Control Center bot. Use this instead of `gh pr comment`: the sandbox '
      'GitHub token is read-only. Answers the pull request URL.';

  /// The run's own workspace and conversation, whatever the model sent.
  @override
  Set<String> get forcedScopeKeys => const {'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {
    'workspace_id',
    'conversation_id',
  };

  /// Headers can name any conversation; only a run's own secret names its
  /// own, and the pull requests it may comment on are read from that run.
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
      'body': {'type': 'string', 'description': 'The comment (markdown).'},
    },
    'required': ['workspace_id', 'conversation_id', 'number', 'body'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    String? text(String key) {
      final value = arguments[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    for (final key in const ['workspace_id', 'conversation_id', 'body']) {
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
    try {
      final result = await _comments.comment(
        AgentPullRequestComment(
          workspaceId: text('workspace_id')!,
          conversationId: text('conversation_id')!,
          repo: text('repo'),
          number: number,
          body: arguments['body'] as String,
        ),
      );
      return CallResult.success(jsonEncode(result.toWire()));
    } on AppException catch (e) {
      return CallResult.error('Could not post the comment: ${e.message}');
    }
  }
}
