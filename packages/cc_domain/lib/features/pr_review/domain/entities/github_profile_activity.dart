import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';

/// PR outcome counts and pr-stats-inspired delivery metrics for one profile.
///
/// Counts come from GitHub search `issueCount` values and remain exact even when
/// [analyzedPullRequests] is capped by GitHub's 1,000-result search window. The
/// percentile and coverage fields are computed only from the returned sample.
class GitHubProfileMetrics {
  /// Creates profile metrics.
  GitHubProfileMetrics({
    required this.open,
    required this.draft,
    required this.merged,
    required this.closed,
    required this.analyzedPullRequests,
    required this.resultsTruncated,
    this.medianLinesChanged,
    this.p90LinesChanged,
    this.medianHoursToMerge,
    this.p90HoursToMerge,
    this.medianHoursToFirstReview,
    this.reviewCoveragePercent,
  }) {
    for (final entry in <String, int>{
      'open': open,
      'draft': draft,
      'merged': merged,
      'closed': closed,
      'analyzedPullRequests': analyzedPullRequests,
    }.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'must not be negative',
        );
      }
    }
    if (reviewCoveragePercent != null &&
        (reviewCoveragePercent! < 0 || reviewCoveragePercent! > 100)) {
      throw ArgumentError.value(
        reviewCoveragePercent,
        'reviewCoveragePercent',
        'must be between 0 and 100',
      );
    }
  }

  /// Creates metrics from the RPC wire shape.
  factory GitHubProfileMetrics.fromWire(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    return GitHubProfileMetrics(
      open: (json['open'] as num?)?.toInt() ?? 0,
      draft: (json['draft'] as num?)?.toInt() ?? 0,
      merged: (json['merged'] as num?)?.toInt() ?? 0,
      closed: (json['closed'] as num?)?.toInt() ?? 0,
      analyzedPullRequests:
          (json['analyzed_pull_requests'] as num?)?.toInt() ?? 0,
      resultsTruncated: json['results_truncated'] as bool? ?? false,
      medianLinesChanged: number('median_lines_changed'),
      p90LinesChanged: number('p90_lines_changed'),
      medianHoursToMerge: number('median_hours_to_merge'),
      p90HoursToMerge: number('p90_hours_to_merge'),
      medianHoursToFirstReview: number('median_hours_to_first_review'),
      reviewCoveragePercent: number('review_coverage_percent'),
    );
  }

  /// Flat map used by the `github.profileActivity` RPC operation.
  Map<String, dynamic> toWire() => <String, dynamic>{
    'open': open,
    'draft': draft,
    'merged': merged,
    'closed': closed,
    'analyzed_pull_requests': analyzedPullRequests,
    'results_truncated': resultsTruncated,
    'median_lines_changed': ?medianLinesChanged,
    'p90_lines_changed': ?p90LinesChanged,
    'median_hours_to_merge': ?medianHoursToMerge,
    'p90_hours_to_merge': ?p90HoursToMerge,
    'median_hours_to_first_review': ?medianHoursToFirstReview,
    'review_coverage_percent': ?reviewCoveragePercent,
  };

  /// Open, non-draft PRs.
  final int open;

  /// Open draft PRs.
  final int draft;

  /// Merged PRs.
  final int merged;

  /// Closed, unmerged PRs.
  final int closed;

  /// PRs whose detailed fields were available for percentile computation.
  final int analyzedPullRequests;

  /// Whether GitHub's search result cap truncated the detailed sample.
  final bool resultsTruncated;

  /// Median additions plus deletions per analyzed PR.
  final double? medianLinesChanged;

  /// 90th percentile additions plus deletions per analyzed PR.
  final double? p90LinesChanged;

  /// Median elapsed hours from creation to merge.
  final double? medianHoursToMerge;

  /// 90th percentile elapsed hours from creation to merge.
  final double? p90HoursToMerge;

  /// Median elapsed hours from creation to the first external review.
  final double? medianHoursToFirstReview;

  /// Share of analyzed merged PRs that received an external review.
  final double? reviewCoveragePercent;

  /// All authored PRs represented by the exact outcome counts.
  int get total => open + draft + merged + closed;

  /// Share of concluded PRs that merged, or null when none concluded.
  double? get mergeRatePercent {
    final concluded = merged + closed;
    return concluded == 0 ? null : merged * 100 / concluded;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitHubProfileMetrics &&
          other.open == open &&
          other.draft == draft &&
          other.merged == merged &&
          other.closed == closed &&
          other.analyzedPullRequests == analyzedPullRequests &&
          other.resultsTruncated == resultsTruncated &&
          other.medianLinesChanged == medianLinesChanged &&
          other.p90LinesChanged == p90LinesChanged &&
          other.medianHoursToMerge == medianHoursToMerge &&
          other.p90HoursToMerge == p90HoursToMerge &&
          other.medianHoursToFirstReview == medianHoursToFirstReview &&
          other.reviewCoveragePercent == reviewCoveragePercent;

  @override
  int get hashCode => Object.hash(
    open,
    draft,
    merged,
    closed,
    analyzedPullRequests,
    resultsTruncated,
    medianLinesChanged,
    p90LinesChanged,
    medianHoursToMerge,
    p90HoursToMerge,
    medianHoursToFirstReview,
    reviewCoveragePercent,
  );
}

/// Detailed PRs for one linked workspace repository.
class GitHubProfileRepoPullRequests {
  /// Creates a per-repository profile group.
  GitHubProfileRepoPullRequests({required this.repoId, required this.prs}) {
    if (repoId.trim().isEmpty) {
      throw ArgumentError.value(repoId, 'repoId', 'must not be empty');
    }
  }

  /// Linked workspace repository id.
  final String repoId;

  /// Authored PRs in all GitHub states, newest activity first.
  final List<PullRequest> prs;
}

/// Profile analytics and the detailed PR sample they summarize.
class GitHubProfileActivity {
  /// Creates profile activity.
  const GitHubProfileActivity({required this.metrics, required this.repos});

  /// Empty activity for an unavailable GitHub connection.
  static final GitHubProfileActivity empty = GitHubProfileActivity(
    metrics: GitHubProfileMetrics(
      open: 0,
      draft: 0,
      merged: 0,
      closed: 0,
      analyzedPullRequests: 0,
      resultsTruncated: false,
    ),
    repos: const [],
  );

  /// Outcome and delivery metrics.
  final GitHubProfileMetrics metrics;

  /// Detailed PRs grouped by linked workspace repository.
  final List<GitHubProfileRepoPullRequests> repos;
}
