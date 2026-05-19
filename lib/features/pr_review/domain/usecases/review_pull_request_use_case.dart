import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';

/// Review pull request use case.
class ReviewPullRequestUseCase {
  /// Creates a new [Review pull request use case].
  ReviewPullRequestUseCase({required PrReviewRepository repository})
    : _repository = repository;

  final PrReviewRepository _repository;

  /// postComment.
  Future<Map<String, dynamic>> postComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) {
    return _repository.postReviewComment(
      prNumber: prNumber,
      commitSha: commitSha,
      path: path,
      line: line,
      side: side,
      body: body,
      startLine: startLine,
      startSide: startSide,
    );
  }

  /// Reply to comment.
  Future<void> replyToComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) {
    return _repository.replyToReviewComment(
      prNumber: prNumber,
      parentCommentId: parentCommentId,
      body: body,
    );
  }

  /// Upsert draft.
  Future<void> upsertDraft(int prNumber, String text) {
    return _repository.upsertDraft(prNumber, text);
  }

  /// Get draft.
  Future<String?> getDraft(int prNumber) {
    return _repository.getDraft(prNumber);
  }

  /// Clear draft.
  Future<void> clearDraft(int prNumber) {
    return _repository.clearDraft(prNumber);
  }
}

