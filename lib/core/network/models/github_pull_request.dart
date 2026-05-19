import 'package:control_center/core/network/models/date_parser.dart';
import 'package:control_center/core/network/models/github_reaction.dart';
import 'package:control_center/core/network/models/github_user.dart';

/// Typed representation of a GitHub pull request.
class GitHubPullRequest {
  /// Creates a [GitHubPullRequest].
  const GitHubPullRequest({
    required this.number,
    required this.title,
    required this.body,
    required this.state,
    required this.isDraft,
    required this.userLogin,
    required this.htmlUrl,
    required this.nodeId,
    this.author,
    this.createdAt,
    this.updatedAt,
    this.mergedAt,
    this.headSha = '',
    this.baseRef = '',
    this.baseSha = '',
    this.headRef = '',
    this.requestedReviewers = const <GitHubUser>[],
    this.assignees = const <GitHubUser>[],
    this.reactions,
    this.bodyHtml,
    this.changedFiles = 0,
    this.commitsCount = 0,
    this.mergeableState = '',
  });

  /// Creates a [GitHubPullRequest] from a JSON map.
  factory GitHubPullRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final head = json['head'];
    final base = json['base'];
    // `/search/issues` returns PRs in issue shape: the merge timestamp lives
    // under a nested `pull_request` object, not at the top level. Fall back to
    // it so merged hits (which carry `state: closed`) still surface a
    // `mergedAt` and render as merged rather than plain closed.
    final pullRequest = json['pull_request'];
    final nestedMergedAt = pullRequest is Map<String, dynamic>
        ? pullRequest['merged_at']
        : null;
    return GitHubPullRequest(
      number: (json['number'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      state: json['state'] as String? ?? '',
      isDraft: json['draft'] as bool? ?? false,
      userLogin:
          (user is Map<String, dynamic> ? user['login'] as String? : null) ??
          '',
      htmlUrl: json['html_url'] as String? ?? '',
      nodeId: json['node_id'] as String? ?? '',
      author: user is Map<String, dynamic> ? GitHubUser.fromJson(user) : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      mergedAt: parseDate(json['merged_at'] ?? nestedMergedAt),
      headSha:
          (head is Map<String, dynamic> ? head['sha'] as String? : null) ?? '',
      baseRef:
          (base is Map<String, dynamic> ? base['ref'] as String? : null) ?? '',
      baseSha:
          (base is Map<String, dynamic> ? base['sha'] as String? : null) ?? '',
      headRef:
          (head is Map<String, dynamic> ? head['ref'] as String? : null) ?? '',
      requestedReviewers: _parseUsers(json['requested_reviewers']),
      assignees: _parseUsers(json['assignees']),
      reactions: json['reactions'] is Map<String, dynamic>
          ? GitHubReactionSummary.fromJson(json['reactions'] as Map<String, dynamic>)
          : null,
      bodyHtml: json['body_html'] as String?,
      changedFiles: (json['changed_files'] as num?)?.toInt() ?? 0,
      commitsCount: (json['commits'] as num?)?.toInt() ?? 0,
      mergeableState: json['mergeable_state'] as String? ?? '',
    );
  }

  static List<GitHubUser> _parseUsers(Object? raw) {
    if (raw is! List) {
      return <GitHubUser>[];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(GitHubUser.fromJson)
        .toList(growable: false);
  }

  /// Serializes this PR back to a JSON shape that [GitHubPullRequest.fromJson]
  /// can re-read. Used by the SWR cache to round-trip the model.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'title': title,
    'body': body,
    'state': state,
    'draft': isDraft,
    'user':
        author?.toJson() ??
        <String, dynamic>{'login': userLogin, 'avatar_url': ''},
    'html_url': htmlUrl,
    'node_id': nodeId,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'merged_at': mergedAt?.toIso8601String(),
    'head': <String, dynamic>{'sha': headSha, 'ref': headRef},
    'base': <String, dynamic>{'ref': baseRef, 'sha': baseSha},
    'requested_reviewers': requestedReviewers
        .map((u) => u.toJson())
        .toList(growable: false),
    'assignees': assignees.map((u) => u.toJson()).toList(growable: false),
    if (reactions != null) 'reactions': reactions!.toJson(),
    if (bodyHtml != null) 'body_html': bodyHtml,
    if (changedFiles > 0) 'changed_files': changedFiles,
    if (commitsCount > 0) 'commits': commitsCount,
    if (mergeableState.isNotEmpty) 'mergeable_state': mergeableState,
  };
  /// PR number.

  final int number;

  /// PR title.
  final String title;

  /// PR body/description (raw markdown).
  final String body;

  /// PR body rendered to HTML by GitHub. Returned by the `full+json` media
  /// type. Used to recover self-signed `private-user-images.*` JWT URLs for
  /// private user-attachments, which the raw `body` references as
  /// `github.com/user-attachments/assets/<uuid>` (web-only, requires session
  /// cookies). Null when the body was fetched without the `full+json` header.
  final String? bodyHtml;

  /// PR state (open, closed).
  final String state;

  /// Whether this is a draft PR.
  final bool isDraft;

  /// Login of the PR author.
  final String userLogin;

  /// HTML URL of the PR.
  final String htmlUrl;

  /// GraphQL node ID, used for mutations like markFileAsViewed.
  final String nodeId;

  /// Full author profile (login + avatar).
  final GitHubUser? author;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Merge timestamp (null if not merged).
  final DateTime? mergedAt;

  /// SHA of the head commit, used for fetching check runs.
  final String headSha;

  /// SHA of the base branch tip. Captured so cache freshness can detect the
  /// base branch advancing (which changes the three-dot diff GitHub renders)
  /// even when the head SHA is unchanged.
  final String baseSha;

  /// Base branch ref (e.g. `main`).
  final String baseRef;

  /// Head branch ref (e.g. `feature/auth`).
  final String headRef;

  /// Reviewers that have been requested but have not yet reviewed.
  final List<GitHubUser> requestedReviewers;

  /// Users assigned to the PR.
  final List<GitHubUser> assignees;

  /// Reaction summary counts.
  final GitHubReactionSummary? reactions;

  /// Number of files changed in this PR. 0 if not fetched (e.g. list endpoint).
  final int changedFiles;

  /// Number of commits in this PR. 0 if not fetched.
  final int commitsCount;

  /// GitHub's `mergeable_state` from the REST API. Empty when not fetched.
  /// Values: `clean`, `dirty`, `unknown`, `blocked`, `behind`, `unstable`,
  /// `has_hooks`.
  final String mergeableState;
}
