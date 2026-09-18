import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/src/network/models/date_parser.dart';
import 'package:cc_infra/src/network/models/github_label.dart';
import 'package:cc_infra/src/network/models/github_team.dart';

/// A single entry of the issue-timeline feed
/// (`/repos/{owner}/{repo}/issues/{n}/timeline`) for the event kinds the PR
/// activity feed consumes: `review_requested` / `review_request_removed` /
/// `labeled` / `unlabeled`.
///
/// For review-request events GitHub sets `review_requester` (who asked) and
/// exactly one of `requested_reviewer` (a user) or `requested_team`. For
/// label events it sets `actor` and `label`.
class GitHubTimelineEvent {
  /// Creates a [GitHubTimelineEvent].
  const GitHubTimelineEvent({
    required this.event,
    this.actor,
    this.requestedReviewer,
    this.requestedTeamName = '',
    this.requestedTeamAvatarUrl = '',
    this.label,
    this.createdAt,
  });

  /// Creates a [GitHubTimelineEvent] from JSON.
  factory GitHubTimelineEvent.fromJson(Map<String, dynamic> json) {
    // `review_requester` is the semantically-correct actor for review-request
    // events; plain `actor` covers the round-trip through the cache and any
    // event kind that lacks the dedicated field.
    final requester = json['review_requester'] ?? json['actor'];
    final reviewer = json['requested_reviewer'];
    final team = json['requested_team'];
    final label = json['label'];
    return GitHubTimelineEvent(
      event: json['event'] as String? ?? '',
      actor: requester is Map<String, dynamic>
          ? GitHubUser.fromJson(requester)
          : null,
      requestedReviewer: reviewer is Map<String, dynamic>
          ? GitHubUser.fromJson(reviewer)
          : null,
      requestedTeamName: team is Map<String, dynamic>
          ? team['name'] as String? ?? team['slug'] as String? ?? ''
          : '',
      requestedTeamAvatarUrl: team is Map<String, dynamic>
          ? githubTeamAvatarUrlFromJson(team)
          : '',
      label: label is Map<String, dynamic> ? GitHubLabel.fromJson(label) : null,
      createdAt: parseDate(json['created_at']),
    );
  }

  /// Serializes this event back to the GitHub JSON shape (cache round-trip).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'event': event,
    'actor': actor?.toJson(),
    'requested_reviewer': requestedReviewer?.toJson(),
    if (requestedTeamName.isNotEmpty)
      'requested_team': <String, dynamic>{
        'name': requestedTeamName,
        if (requestedTeamAvatarUrl.isNotEmpty)
          'avatar_url': requestedTeamAvatarUrl,
      },
    if (label != null) 'label': label!.toJson(),
    'created_at': createdAt?.toIso8601String(),
  };

  /// The wire event name (`review_requested`, `labeled`, …).
  final String event;

  /// Who performed the action.
  final GitHubUser? actor;

  /// The requested user reviewer (null for team requests).
  final GitHubUser? requestedReviewer;

  /// The requested team's name (empty for user requests).
  final String requestedTeamName;

  /// Team logo URL when [requestedTeamName] is set. Empty when omitted.
  final String requestedTeamAvatarUrl;

  /// The label that was added or removed. Null for review-request events.
  final GitHubLabel? label;

  /// When the event happened.
  final DateTime? createdAt;
}
