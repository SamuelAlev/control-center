import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';

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
  });

  /// State.
  final PrReviewSubmissionState state;

  /// Author of the submission.
  final PrUser? author;

  /// Body.
  final String body;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrReviewSubmission &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          author == other.author &&
          body == other.body;

  /// Hash code.
  @override
  int get hashCode => Object.hash(state, author, body);
}
