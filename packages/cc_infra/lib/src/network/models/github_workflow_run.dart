import 'package:cc_infra/src/network/models/date_parser.dart';

/// A single GitHub Actions workflow run for a commit. Returned by the
/// `/repos/{owner}/{repo}/actions/runs` endpoint and used to look up the
/// parent workflow name for an individual check run via its
/// [checkSuiteId].
class GitHubWorkflowRun {
  /// Creates a [GitHubWorkflowRun].
  const GitHubWorkflowRun({
    required this.id,
    required this.name,
    required this.checkSuiteId,
    required this.headSha,
    required this.htmlUrl,
    required this.path,
    required this.status,
    this.conclusion,
    this.runStartedAt,
    this.updatedAt,
  });

  /// Creates a [GitHubWorkflowRun] from JSON.
  factory GitHubWorkflowRun.fromJson(Map<String, dynamic> json) {
    return GitHubWorkflowRun(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      checkSuiteId: (json['check_suite_id'] as num?)?.toInt() ?? 0,
      headSha: (json['head_sha'] as String?) ?? '',
      htmlUrl: (json['html_url'] as String?) ?? '',
      path: (json['path'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      conclusion: json['conclusion'] as String?,
      runStartedAt: parseDate(json['run_started_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  /// Serializes back to JSON (used by the response cache).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'check_suite_id': checkSuiteId,
    'head_sha': headSha,
    'html_url': htmlUrl,
    'path': path,
    'status': status,
    'conclusion': conclusion,
    'run_started_at': runStartedAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  /// Workflow run id.
  final int id;

  /// Workflow display name (the `name:` from the YAML, e.g.
  /// `Tests (Pull Request)`).
  final String name;

  /// Check suite that aggregates the runs for this workflow on this commit.
  /// Used to join workflow runs to individual check runs.
  final int checkSuiteId;

  /// Head SHA the workflow ran against.
  final String headSha;

  /// Link to the run on GitHub.
  final String htmlUrl;

  /// Workflow file path, e.g. `.github/workflows/tests-pr.yaml`. Used as a
  /// fallback display label when [name] is empty.
  final String path;

  /// Raw status string (`queued`, `in_progress`, `completed`).
  final String status;

  /// Raw conclusion string when completed (`success`, `failure`, etc.).
  final String? conclusion;

  /// When the run was first scheduled.
  final DateTime? runStartedAt;

  /// When the run was last updated.
  final DateTime? updatedAt;
}
