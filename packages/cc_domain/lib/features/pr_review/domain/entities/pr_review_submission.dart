import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/reaction_group.dart';

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
    this.reactions = const [],
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

  /// Reactions on the review summary (GitHub renders the summary as a
  /// comment card, and it can be reacted to like one).
  final List<ReactionGroup> reactions;

  /// Returns a copy with the enrichment-owned reactions replaced. GitHub's
  /// REST review payload carries no reaction data at all — the adapter joins
  /// per-user reactions in from GraphQL after the fact, and the viewer flag
  /// is stamped on top of that.
  PrReviewSubmission copyWith({List<ReactionGroup>? reactions}) =>
      PrReviewSubmission(
        id: id,
        state: state,
        author: author,
        body: body,
        submittedAt: submittedAt,
        reactions: reactions ?? this.reactions,
      );

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
          submittedAt == other.submittedAt &&
          _listEquals(reactions, other.reactions);

  /// Hash code.
  @override
  int get hashCode => Object.hash(
    id,
    state,
    author,
    body,
    submittedAt,
    Object.hashAll(reactions),
  );

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
