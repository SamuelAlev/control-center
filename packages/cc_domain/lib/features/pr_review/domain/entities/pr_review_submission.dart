import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';

/// Pr review submission state.
enum PrReviewSubmissionState {
  /// Approved.
  approved,

  /// Changes requested.
  changesRequested,

  /// Commented.
  commented,

  /// Awaiting review (requested reviewer who has not yet submitted).
  pending,
}

/// Pr review submission.
class PrReviewSubmission {
  /// PrReviewSubmission.
  const PrReviewSubmission({
    required this.state,
    required this.author,
    required this.body,
    this.id = 0,
    this.submittedAt,
  });

  /// GitHub review id (0 when unknown, e.g. legacy cache rows).
  final int id;

  /// State.
  final PrReviewSubmissionState state;

  /// Author of the submission.
  final PrUser? author;

  /// Body.
  final String body;

  /// When the review was submitted (null when unknown).
  final DateTime? submittedAt;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrReviewSubmission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          state == other.state &&
          author == other.author &&
          body == other.body &&
          submittedAt == other.submittedAt;

  /// Hash code.
  @override
  int get hashCode => Object.hash(id, state, author, body, submittedAt);
}
