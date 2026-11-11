import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/ports/agent_pull_request_comment_port.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_domain/features/pr_review/domain/services/mention_matcher.dart'
    show neutralizeMentions;
import 'package:cc_infra/cc_infra.dart' show mapHttpException;
import 'package:cc_server_core/src/pr_review/agent_run_pull_request_scope.dart';
import 'package:rhttp/rhttp.dart' show RhttpException;

/// The automation client a comment for an agent run is posted with: the
/// workspace's bot, bounded by [actingUserId] (the run's requester) when
/// there is one. Never a person's own token.
typedef AgentPrCommentClientFor =
    ForgePrClient Function(
      Repo repo, {
      required String workspaceId,
      String? actingUserId,
    });

/// What the bot's comment says it posted for [actingUserId] (the
/// `**Control Center** (for @login):` prefix), or null for none.
typedef AgentPrCommentAttribution =
    Future<String Function(String body)?> Function(
      Repo repo, {
      required String workspaceId,
      String? actingUserId,
    });

/// Comments on agent runs' own pull requests ([AgentPullRequestCommentPort]).
///
/// The run's token only reads; this is how an agent talks on its pull
/// request. Who: the Control Center bot, bounded by the person who requested
/// the run (the workspace's accountable person when nobody did), with the
/// attribution prefix when it acts for someone. What: a top-level comment on
/// the run's own pull request, as [AgentRunPullRequestScope] holds it.
/// Mentions in the comment are made inert, so an agent cannot page anyone
/// through the bot. Nothing else: no review, label or close.
class AgentPullRequestCommentService implements AgentPullRequestCommentPort {
  /// Creates the service.
  AgentPullRequestCommentService({
    required this._scope,
    required this._clientFor,
    this._attribution,
  });

  /// The longest comment posted: GitHub's own limit for an issue comment.
  static const int maxBodyLength = 65536;

  static const String _doing = 'comment on its pull request';

  final AgentRunPullRequestScope _scope;
  final AgentPrCommentClientFor _clientFor;
  final AgentPrCommentAttribution? _attribution;

  @override
  Future<AgentPullRequestCommentResult> comment(
    AgentPullRequestComment comment,
  ) async {
    final workspaceId = comment.workspaceId;
    final body = neutralizeMentions(comment.body.trim());
    if (body.isEmpty) {
      throw const ValidationException('The comment is empty.');
    }
    if (body.length > maxBodyLength) {
      throw const ValidationException(
        'The comment is longer than GitHub accepts ($maxBodyLength '
        'characters).',
      );
    }
    final runs = await _scope.runsOf(
      workspaceId,
      comment.conversationId,
      doing: _doing,
    );
    final repo = await _scope.repoFor(
      workspaceId,
      comment.repo,
      runs,
      doing: _doing,
    );
    final requester = runs.requester;
    final client = _clientFor(
      repo,
      workspaceId: workspaceId,
      actingUserId: requester,
    );
    try {
      final pr = await _scope.ownPullRequest(
        client,
        workspaceId: workspaceId,
        runs: runs.runs,
        repo: repo,
        number: comment.number,
      );
      final attribute = await _attribution?.call(
        repo,
        workspaceId: workspaceId,
        actingUserId: requester,
      );
      await client.postIssueComment(
        prNumber: comment.number,
        body: attribute == null ? body : attribute(body),
      );
      return AgentPullRequestCommentResult(
        repoFullName: repo.fullName,
        number: comment.number,
        url: pr.htmlUrl,
      );
    } on RhttpException catch (e) {
      throw mapHttpException(e);
    }
  }
}
