import 'package:cc_infra/src/network/github_content_client.dart';
import 'package:cc_infra/src/network/github_graphql_client.dart';
import 'package:cc_infra/src/network/github_pr_client.dart';
import 'package:dio/dio.dart';

/// Facade for GitHub API operations, composing focused sub-clients.
///
/// - [pr] — Pull request operations (list, get, diff, files, commits,
///   reviews, comments, check runs, search, create)
/// - [graphql] — GraphQL API mutations (mark/unmark file as viewed)
/// - [content] — Content and user operations (file content, blobs, file
///   uploads, user profile)
class GitHubApiClient {
  /// Creates a [GitHubApiClient] backed by [Dio].
  GitHubApiClient(Dio dio)
    : pr = GitHubPrClient(dio),
      graphql = GitHubGraphQLClient(dio),
      content = GitHubContentClient(dio);

  /// Pull request operations.
  final GitHubPrClient pr;

  /// GraphQL API mutations.
  final GitHubGraphQLClient graphql;

  /// Content and user operations.
  final GitHubContentClient content;
}
