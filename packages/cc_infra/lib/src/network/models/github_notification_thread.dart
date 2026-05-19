import 'package:cc_infra/src/network/models/date_parser.dart';

/// One thread from `GET /notifications` — the authenticated user's inbox item
/// (a review request, a mention, an assignment, CI activity, …).
class GitHubNotificationThread {
  /// Creates a [GitHubNotificationThread].
  const GitHubNotificationThread({
    required this.id,
    required this.reason,
    required this.repoFullName,
    required this.subjectTitle,
    required this.subjectType,
    required this.subjectUrl,
    this.updatedAt,
  });

  /// Decodes the REST wire shape.
  factory GitHubNotificationThread.fromJson(Map<String, dynamic> json) {
    final subject = json['subject'] as Map<String, dynamic>? ?? const {};
    final repository = json['repository'] as Map<String, dynamic>? ?? const {};
    return GitHubNotificationThread(
      id: json['id'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      repoFullName: repository['full_name'] as String? ?? '',
      subjectTitle: subject['title'] as String? ?? '',
      subjectType: subject['type'] as String? ?? '',
      subjectUrl: subject['url'] as String? ?? '',
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// Thread id.
  final String id;

  /// Why the user was notified (`review_requested`, `mention`, `assign`,
  /// `state_change`, `comment`, `ci_activity`, …).
  final String reason;

  /// The repository in `owner/name` form.
  final String repoFullName;

  /// The subject's title (for a PR: the PR title).
  final String subjectTitle;

  /// The subject's type (`PullRequest`, `Issue`, `Release`, …).
  final String subjectType;

  /// The subject's API URL — for a PR:
  /// `https://api.github.com/repos/{owner}/{repo}/pulls/{number}`.
  final String subjectUrl;

  /// When the thread last updated.
  final DateTime? updatedAt;

  /// The PR number parsed from [subjectUrl], or null when the subject is not
  /// a pull request (or the URL is malformed).
  int? get pullRequestNumber {
    if (subjectType != 'PullRequest') {
      return null;
    }
    final lastSlash = subjectUrl.lastIndexOf('/');
    if (lastSlash < 0) {
      return null;
    }
    return int.tryParse(subjectUrl.substring(lastSlash + 1));
  }
}

/// A page of notification threads plus the polling metadata GitHub returns:
/// the `Last-Modified` stamp to present as `If-Modified-Since` next time and
/// the server-mandated minimum poll interval.
class GitHubNotificationsPage {
  /// Creates a [GitHubNotificationsPage].
  const GitHubNotificationsPage({
    required this.threads,
    required this.notModified,
    this.lastModified,
    this.pollIntervalSeconds,
  });

  /// The threads (empty on 304).
  final List<GitHubNotificationThread> threads;

  /// True when GitHub answered 304 Not Modified (rate-limit-free).
  final bool notModified;

  /// The response's `Last-Modified` header, echoed back as
  /// `If-Modified-Since` on the next poll.
  final String? lastModified;

  /// GitHub's `X-Poll-Interval` (seconds) — the minimum cadence it asks
  /// pollers to respect.
  final int? pollIntervalSeconds;
}
