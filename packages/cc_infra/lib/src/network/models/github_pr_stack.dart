import 'package:cc_infra/src/network/models/date_parser.dart';

/// One pull request's membership in a [GitHubPrStack], as returned by the
/// stacks REST API (minimal shape: no title, author, or diff stats).
class GitHubPrStackEntry {
  /// Creates a [GitHubPrStackEntry].
  const GitHubPrStackEntry({
    required this.number,
    required this.state,
    required this.draft,
    required this.headRef,
    required this.headSha,
    this.mergedAt,
  });

  /// Parses one entry of the stack's `pull_requests` array.
  factory GitHubPrStackEntry.fromJson(Map<String, dynamic> json) {
    final head = (json['head'] as Map?)?.cast<String, dynamic>();
    return GitHubPrStackEntry(
      number: (json['number'] as num?)?.toInt() ?? 0,
      state: json['state'] as String? ?? 'closed',
      draft: json['draft'] as bool? ?? false,
      headRef: head?['ref'] as String? ?? '',
      headSha: head?['sha'] as String? ?? '',
      mergedAt: parseDate(json['merged_at']),
    );
  }

  /// PR number within the repository.
  final int number;

  /// `open` or `closed` (a merged PR reports `closed` plus [mergedAt]).
  final String state;

  /// Whether the PR is a draft.
  final bool draft;

  /// Head branch ref name.
  final String headRef;

  /// SHA of the head commit.
  final String headSha;

  /// Merge timestamp, when merged.
  final DateTime? mergedAt;
}

/// A GitHub pull request stack: an ordered chain of PRs where each PR's base
/// ref is the previous PR's head ref. [pullRequests] runs bottom to top.
class GitHubPrStack {
  /// Creates a [GitHubPrStack].
  const GitHubPrStack({
    required this.id,
    required this.number,
    required this.externalId,
    required this.url,
    required this.baseRef,
    required this.open,
    required this.pullRequests,
    this.createdAt,
  });

  /// Parses a stack object from the stacks endpoints.
  factory GitHubPrStack.fromJson(Map<String, dynamic> json) {
    final base = (json['base'] as Map?)?.cast<String, dynamic>();
    return GitHubPrStack(
      id: (json['id'] as num?)?.toInt() ?? 0,
      number: (json['number'] as num?)?.toInt() ?? 0,
      externalId: json['external_id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      baseRef: base?['ref'] as String? ?? '',
      open: json['open'] as bool? ?? true,
      createdAt: parseDate(json['created_at']),
      pullRequests: ((json['pull_requests'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => GitHubPrStackEntry.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  /// GitHub's stack identifier.
  final int id;

  /// Stack number within the repository.
  final int number;

  /// Global node ID.
  final String externalId;

  /// API URL of the stack.
  final String url;

  /// The ref the bottom PR of the stack targets.
  final String baseRef;

  /// Whether the stack is open.
  final bool open;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// The stacked pull requests, bottom to top.
  final List<GitHubPrStackEntry> pullRequests;
}
