import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';

/// Kind of a conversation-timeline event on a pull request.
///
/// Only the event kinds the Overview activity feed renders are modelled;
/// reviews, comments and commits ride their own dedicated streams.
enum PrTimelineEventKind {
  /// A review was requested from a user or team.
  reviewRequested,

  /// A pending review request was withdrawn.
  reviewRequestRemoved,
}

/// A single conversation-timeline event on a pull request (e.g. "requested
/// review from X"), as returned by the forge's issue-timeline feed.
class PrTimelineEvent {
  /// PrTimelineEvent.
  const PrTimelineEvent({
    required this.kind,
    required this.actor,
    required this.reviewerName,
    this.reviewerIsTeam = false,
    this.reviewerAvatarUrl = '',
    this.createdAt,
  });

  /// What happened.
  final PrTimelineEventKind kind;

  /// Who performed the action (null when the forge omitted it).
  final PrUser? actor;

  /// The requested reviewer: a user login, or a team name when
  /// [reviewerIsTeam].
  final String reviewerName;

  /// Whether [reviewerName] refers to a team rather than a user.
  final bool reviewerIsTeam;

  /// Avatar URL for the requested reviewer (user photo or team logo). Empty
  /// when the forge omitted it. Lets the activity feed reserve a disc
  /// without a second fetch.
  final String reviewerAvatarUrl;

  /// When the event happened (null when unknown).
  final DateTime? createdAt;

  /// Equality comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrTimelineEvent &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          actor == other.actor &&
          reviewerName == other.reviewerName &&
          reviewerIsTeam == other.reviewerIsTeam &&
          reviewerAvatarUrl == other.reviewerAvatarUrl &&
          createdAt == other.createdAt;

  /// Hash code.
  @override
  int get hashCode => Object.hash(
    kind,
    actor,
    reviewerName,
    reviewerIsTeam,
    reviewerAvatarUrl,
    createdAt,
  );
}
