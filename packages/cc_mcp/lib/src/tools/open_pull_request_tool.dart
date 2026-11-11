import 'dart:convert';

import 'package:cc_domain/cc_domain.dart' show AppException;
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_port.dart';
import 'package:cc_harness/tools.dart';

/// Opens a pull request for the calling agent run, on the server.
///
/// A run's GitHub token cannot open pull requests, so `gh pr create`
/// fails there. The server opens it as the person who requested the run
/// (their own one-repository token, so GitHub's "an author cannot approve
/// their own pull request" rule applies), or as the Control Center bot when
/// nobody did. Only an agent run can call it: the run's workspace and
/// conversation come from its own grant, never from the model.
class OpenPullRequestTool extends McpTool {
  /// Creates an [OpenPullRequestTool].
  OpenPullRequestTool({required this._pullRequests});

  final AgentPullRequestPort _pullRequests;

  /// [kAgentOpenPullRequestTool], spelled out for the ActionClass ratchet.
  @override
  String get name => 'open_pull_request';

  @override
  Set<ActionClass> get actionClasses => const {ActionClass.prCreate};

  @override
  String get description =>
      'Opens a pull request from a branch this run pushed (or its space '
      'branch) into a base branch. Push the branch with git push first. '
      'Use this instead of `gh pr create`, which cannot open pull requests '
      'from the sandbox. The pull request is opened as the person who asked '
      'for this run, so another reviewer has to approve it. Answers the '
      'number and URL.';

  /// The run's own workspace and conversation, whatever the model sent.
  @override
  Set<String> get forcedScopeKeys => const {'conversation_id'};

  @override
  Set<String> get requiredScopeKeys => const {
    'workspace_id',
    'conversation_id',
  };

  /// Headers can name any conversation; only a run's own secret names its
  /// own, and the requester is read from that run.
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
      'head': {
        'type': 'string',
        'description':
            'Branch with the changes. Must be a branch this run pushed or '
            'the space\'s own branch.',
      },
      'base': {
        'type': 'string',
        'description': 'Branch to merge into, such as main.',
      },
      'title': {'type': 'string', 'description': 'Pull request title.'},
      'body': {
        'type': 'string',
        'description': 'Pull request description (markdown).',
      },
      'draft': {
        'type': 'boolean',
        'description': 'Open as a draft. Defaults to false.',
      },
    },
    'required': ['workspace_id', 'conversation_id', 'head', 'base', 'title'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    String? text(String key) {
      final value = arguments[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    for (final key in const [
      'workspace_id',
      'conversation_id',
      'head',
      'base',
      'title',
    ]) {
      if (text(key) == null) {
        return CallResult.error('Missing or invalid argument: $key');
      }
    }
    final body = arguments['body'];
    try {
      final result = await _pullRequests.open(
        AgentPullRequestDraft(
          workspaceId: text('workspace_id')!,
          conversationId: text('conversation_id')!,
          repo: text('repo'),
          head: text('head')!,
          base: text('base')!,
          title: text('title')!,
          body: body is String ? body : '',
          draft: arguments['draft'] == true,
        ),
      );
      return CallResult.success(jsonEncode(result.toWire()));
    } on AppException catch (e) {
      return CallResult.error(
        'Could not open the pull request: ${e.message}',
      );
    }
  }
}
