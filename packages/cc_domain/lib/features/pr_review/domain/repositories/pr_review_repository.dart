import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// Pr review repository.
abstract class PrReviewRepository {
  /// Watch pull request.
  Stream<PullRequest?> watchPullRequest(int prNumber);

  /// Watch diff.
  Stream<String> watchDiff(int prNumber);

  /// Stream of changed files for a PR.
  Stream<List<PrFile>> watchFiles(int prNumber);

  /// Watch file content.
  Stream<String> watchFileContent(String path, String ref);

  /// Stream of commits for a PR.
  Stream<List<PrCommit>> watchCommits(int prNumber);

  /// Stream of files changed in a single commit.
  Stream<List<PrFile>> watchCommitFiles(String sha);

  /// Stream of review submissions for a PR.
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber);

  /// Stream of inline review comments for a PR.
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber);

  /// Stream of top-level issue comments for a PR.
  Stream<List<IssueComment>> watchIssueComments(int prNumber);

  /// Stream of CI check runs for a PR.
  Stream<List<CheckRun>> watchCheckRuns(int prNumber);

  /// Invalidate pull request.
  Future<void> invalidatePullRequest(int prNumber);

  /// Drops the cached diff and file list for a PR so the next read is forced
  /// to hit the network. Used by the user-initiated "refresh diff" action,
  /// which must be authoritative rather than honouring the SWR freshness gate.
  Future<void> invalidateDiff(int prNumber);

  /// Mark file as viewed.
  Future<void> markFileAsViewed({
    required int prNumber,
    required String nodeId,
    required String path,
    required bool viewed,
  });

  /// Post a new inline review comment on GitHub.
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  });

  /// Reply to review comment.
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  });

  /// Upsert draft.
  Future<void> upsertDraft(int prNumber, String text);

  /// Get draft.
  Future<String?> getDraft(int prNumber);

  /// Clear draft.
  Future<void> clearDraft(int prNumber);

  /// Upload content.
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  );

  /// Toggle a reaction on a review comment.
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  });

  /// Toggle a reaction on an issue comment.
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  });

  /// Toggle a reaction on the pull request itself.
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  });

  /// Submit a PR review (approve, request changes, or comment).
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
  });

  /// Merge a pull request.
  ///
  /// [mergeMethod] must be one of: "squash", "merge", "rebase".
  /// Returns a map with `merged`, `message`, and `sha` from GitHub.
  Future<Map<String, dynamic>> mergePullRequest({
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
  });

  /// Close a pull request (set state to "closed").
  Future<void> closePullRequest({required int prNumber});

  /// Update a pull request's [title] and/or [body]. Only the provided fields
  /// are sent.
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  });

  /// Add the given user [logins] as assignees on the PR.
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
  });

  /// Remove the given user [logins] from the PR's assignees.
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
  });

  /// Request reviews from the given user [userLogins] and team [teamSlugs].
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
  });

  /// Cancel review requests for the given user [userLogins] and team
  /// [teamSlugs].
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins,
    List<String> teamSlugs,
  });

  /// Stream of enriched reviewers (users + teams, with code-owner flags and
  /// the team↔member review merge) for a PR.
  Stream<List<PrReviewer>> watchReviewers(int prNumber);

  /// Lists users who can be assigned to / requested as reviewers on this repo.
  Future<List<PrUser>> listAssignableUsers();

  /// Lists candidates that can be requested as reviewers — users and teams.
  Future<List<PrReviewerCandidate>> listRequestableReviewers();
}

/// No-op implementation returned when auth is missing or the host is not
/// supported.
class EmptyPrReviewRepository implements PrReviewRepository {
  /// Creates a no-op [EmptyPrReviewRepository].
  const EmptyPrReviewRepository();

  @override
  Stream<PullRequest?> watchPullRequest(int prNumber) => Stream.value(null);

  @override
  Stream<String> watchDiff(int prNumber) => Stream.value('');

  @override
  Stream<List<PrFile>> watchFiles(int prNumber) =>
      Stream.value(const <PrFile>[]);

  @override
  Stream<String> watchFileContent(String path, String ref) => Stream.value('');

  @override
  Stream<List<PrCommit>> watchCommits(int prNumber) =>
      Stream.value(const <PrCommit>[]);

  @override
  Stream<List<PrFile>> watchCommitFiles(String sha) =>
      Stream.value(const <PrFile>[]);

  @override
  Stream<List<PrReviewSubmission>> watchReviews(int prNumber) =>
      Stream.value(const <PrReviewSubmission>[]);

  @override
  Stream<List<PrCodeReviewComment>> watchReviewComments(int prNumber) =>
      Stream.value(const <PrCodeReviewComment>[]);

  @override
  Stream<List<IssueComment>> watchIssueComments(int prNumber) =>
      Stream.value(const <IssueComment>[]);

  @override
  Stream<List<CheckRun>> watchCheckRuns(int prNumber) =>
      Stream.value(const <CheckRun>[]);

  @override
  Future<void> invalidatePullRequest(int prNumber) async {}

  @override
  Future<void> invalidateDiff(int prNumber) async {}

  @override
  Future<void> markFileAsViewed({
    required int prNumber,
    required String nodeId,
    required String path,
    required bool viewed,
  }) async {}

  @override
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) async {
    return {'id': 0};
  }

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {}

  @override
  Future<void> upsertDraft(int prNumber, String text) async {}

  @override
  Future<String?> getDraft(int prNumber) async => null;

  @override
  Future<void> clearDraft(int prNumber) async {}

  @override
  Future<String> uploadContent(
    String path,
    String base64Content,
    String message,
  ) async {
    return '';
  }

  @override
  Future<void> toggleReviewCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {}

  @override
  Future<void> toggleIssueCommentReaction({
    required int commentId,
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {}

  @override
  Future<void> togglePullRequestReaction({
    required int prNumber,
    required String content,
    required bool add,
    String? currentUserLogin,
  }) async {}

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
  }) async {}

  @override
  Future<Map<String, dynamic>> mergePullRequest({
    required int prNumber,
    required String mergeMethod,
    String? commitTitle,
    String? commitMessage,
  }) async {
    return {};
  }

  @override
  Future<void> closePullRequest({required int prNumber}) async {}

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  }) async {}

  @override
  Future<void> addAssignees({
    required int prNumber,
    required List<String> logins,
  }) async {}

  @override
  Future<void> removeAssignees({
    required int prNumber,
    required List<String> logins,
  }) async {}

  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {}

  @override
  Future<void> removeRequestedReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {}

  @override
  Stream<List<PrReviewer>> watchReviewers(int prNumber) =>
      Stream.value(const <PrReviewer>[]);

  @override
  Future<List<PrUser>> listAssignableUsers() async => const <PrUser>[];

  @override
  Future<List<PrReviewerCandidate>> listRequestableReviewers() async =>
      const <PrReviewerCandidate>[];
}
