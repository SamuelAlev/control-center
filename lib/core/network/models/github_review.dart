import 'package:control_center/core/network/models/date_parser.dart';
import 'package:control_center/core/network/models/github_user.dart';

/// State of a [GitHubReview].
enum GitHubReviewState {
  /// Approved by the reviewer.
  approved,

  /// The reviewer requested changes.
  changesRequested,

  /// The reviewer left an unresolved comment without a verdict.
  commented,

  /// Review was dismissed.
  dismissed,

  /// Review is pending (still being drafted).
  pending,

  /// Unknown state.
  unknown,
}

/// A submitted review on a pull request.
class GitHubReview {
  /// Creates a [GitHubReview].
  const GitHubReview({
    required this.id,
    required this.state,
    required this.body,
    required this.submittedAt,
    this.user,
  });

  /// Creates a [GitHubReview] from JSON.
  factory GitHubReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return GitHubReview(
      id: (json['id'] as num?)?.toInt() ?? 0,
      state: _stateFromString(json['state'] as String?),
      body: json['body'] as String? ?? '',
      submittedAt: parseDate(json['submitted_at']),
      user: user is Map<String, dynamic> ? GitHubUser.fromJson(user) : null,
    );
  }

  /// Serializes this review back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'state': _stateToString(state),
    'body': body,
    'submitted_at': submittedAt?.toIso8601String(),
    'user': user?.toJson(),
  };

  /// Review id.
  final int id;

  /// Review state.
  final GitHubReviewState state;

  /// Review body text.
  final String body;

  /// When the review was submitted.
  final DateTime? submittedAt;

  /// The reviewer.
  final GitHubUser? user;
}

GitHubReviewState _stateFromString(String? raw) {
  switch (raw?.toUpperCase()) {
    case 'APPROVED':
      return GitHubReviewState.approved;
    case 'CHANGES_REQUESTED':
      return GitHubReviewState.changesRequested;
    case 'COMMENTED':
      return GitHubReviewState.commented;
    case 'DISMISSED':
      return GitHubReviewState.dismissed;
    case 'PENDING':
      return GitHubReviewState.pending;
    default:
      return GitHubReviewState.unknown;
  }
}

String? _stateToString(GitHubReviewState state) {
  switch (state) {
    case GitHubReviewState.approved:
      return 'APPROVED';
    case GitHubReviewState.changesRequested:
      return 'CHANGES_REQUESTED';
    case GitHubReviewState.commented:
      return 'COMMENTED';
    case GitHubReviewState.dismissed:
      return 'DISMISSED';
    case GitHubReviewState.pending:
      return 'PENDING';
    case GitHubReviewState.unknown:
      return null;
  }
}
