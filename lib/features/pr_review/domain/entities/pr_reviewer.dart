import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';

/// An enriched reviewer row for the PR detail rail.
///
/// Unlike the raw `requestedReviewers` on `PullRequest` (users only, from
/// REST), this models a reviewer as either an individual [PrUserReviewer] or a
/// [PrTeamReviewer], carries whether it is a CODEOWNERS-required reviewer
/// ([isCodeOwner] — shield + non-removable), its review [state], and — for a
/// team satisfied by a member — who reviewed on its behalf.
sealed class PrReviewer {
  /// Creates a [PrReviewer].
  const PrReviewer({required this.isCodeOwner, required this.state});

  /// Whether this reviewer/team is required by CODEOWNERS. Drives the shield
  /// badge and the non-removable rule.
  final bool isCodeOwner;

  /// Review verdict for this row.
  final PrReviewSubmissionState state;

  /// Stable identity used for add/remove diffing and dedupe:
  /// `user:<login>` or `team:<slug>` (lowercased).
  String get identity;
}

/// An individual user reviewer.
class PrUserReviewer extends PrReviewer {
  /// Creates a [PrUserReviewer].
  const PrUserReviewer({
    required this.user,
    required super.isCodeOwner,
    required super.state,
  });

  /// The reviewer.
  final PrUser user;

  @override
  String get identity => 'user:${user.login.toLowerCase()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrUserReviewer &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          isCodeOwner == other.isCodeOwner &&
          state == other.state;

  @override
  int get hashCode => Object.hash(user, isCodeOwner, state);
}

/// A team reviewer. When a member has reviewed on the team's behalf, the
/// team's required-review row is merged with that member via [reviewedBy].
class PrTeamReviewer extends PrReviewer {
  /// Creates a [PrTeamReviewer].
  const PrTeamReviewer({
    required this.name,
    required this.slug,
    required super.isCodeOwner,
    required super.state,
    this.reviewedBy,
  });

  /// Display name (e.g. "Frontend platform").
  final String name;

  /// Team slug (the identity for review requests + on-behalf matching).
  final String slug;

  /// The member who reviewed on the team's behalf, if any. When non-null the
  /// row renders the team plus this member and [state] reflects their review.
  final PrUser? reviewedBy;

  @override
  String get identity => 'team:${slug.toLowerCase()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrTeamReviewer &&
          runtimeType == other.runtimeType &&
          slug == other.slug &&
          name == other.name &&
          isCodeOwner == other.isCodeOwner &&
          state == other.state &&
          reviewedBy == other.reviewedBy;

  @override
  int get hashCode => Object.hash(slug, name, isCodeOwner, state, reviewedBy);
}

/// Whether a [PrReviewerCandidate] is an individual user or a team.
enum ReviewerKind {
  /// An individual user.
  user,

  /// A team.
  team,
}

/// A selectable candidate for the reviewer/assignee pickers — either a user
/// (keyed by login) or a team (keyed by slug).
class PrReviewerCandidate {
  /// Creates a [PrReviewerCandidate].
  const PrReviewerCandidate({
    required this.kind,
    required this.key,
    required this.label,
    this.avatarUrl,
  });

  /// Builds a user candidate from a [PrUser].
  factory PrReviewerCandidate.user(PrUser u) => PrReviewerCandidate(
    kind: ReviewerKind.user,
    key: u.login,
    label: u.login,
    avatarUrl: u.avatarUrl,
  );

  /// Whether this candidate is a user or a team.
  final ReviewerKind kind;

  /// The user login (users) or team slug (teams).
  final String key;

  /// Display label.
  final String label;

  /// Avatar URL (users only; null for teams).
  final String? avatarUrl;

  /// The picker selection key: `user:<login>` / `team:<slug>` (lowercased).
  String get selectionKey =>
      '${kind == ReviewerKind.user ? 'user' : 'team'}:${key.toLowerCase()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrReviewerCandidate &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          key.toLowerCase() == other.key.toLowerCase();

  @override
  int get hashCode => Object.hash(kind, key.toLowerCase());
}
