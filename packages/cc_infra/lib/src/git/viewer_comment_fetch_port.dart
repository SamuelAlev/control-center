import 'package:cc_infra/src/network/github_graphql_client.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:cc_infra/src/network/models/github_issue_comment.dart';
import 'package:cc_infra/src/network/models/github_review_comment.dart';

/// Reads one pull request's comments on behalf of the signed-in operator.
///
/// A narrow port rather than the whole [GitHubPrClient] so the viewer-activity
/// poller can be driven from a fake in tests without a Dio, and so the three
/// calls the mention lane is allowed to make are visible in one place — this
/// runs on the operator's PERSONAL rate limit, so widening it is a decision,
/// not an accident.
abstract interface class ViewerCommentFetchPort {
  /// Conversation-timeline comments (no file, no line).
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int number,
  );

  /// Inline review comments, which carry `path`/`line`/`inReplyToId`.
  Future<List<GitHubReviewComment>> listReviewComments(
    String owner,
    String repo,
    int number,
  );

  /// Review threads with their resolved state, joined back to REST comment ids
  /// through [GitHubReviewThread.commentIds].
  Future<List<GitHubReviewThread>> listReviewThreads(
    String owner,
    String repo,
    int number,
  );
}

/// The production [ViewerCommentFetchPort], reading through the operator's own
/// credential (the same client the rest of the viewer-activity poller uses).
class GitHubViewerCommentFetchAdapter implements ViewerCommentFetchPort {
  /// Creates a [GitHubViewerCommentFetchAdapter].
  const GitHubViewerCommentFetchAdapter({
    required GitHubPrClient prClient,
    required GitHubGraphQLClient graphqlClient,
  }) : _pr = prClient,
       _graphql = graphqlClient;

  final GitHubPrClient _pr;
  final GitHubGraphQLClient _graphql;

  @override
  Future<List<GitHubIssueComment>> listIssueComments(
    String owner,
    String repo,
    int number,
  ) => _pr.listIssueComments(owner, repo, number);

  @override
  Future<List<GitHubReviewComment>> listReviewComments(
    String owner,
    String repo,
    int number,
  ) => _pr.listPullRequestReviewComments(owner, repo, number);

  @override
  Future<List<GitHubReviewThread>> listReviewThreads(
    String owner,
    String repo,
    int number,
  ) => _graphql.listReviewThreads(owner: owner, repo: repo, number: number);
}
