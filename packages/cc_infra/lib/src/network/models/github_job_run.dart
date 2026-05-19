import 'package:cc_infra/src/network/models/date_parser.dart';

/// One step of a GitHub Actions job. Returned inside the `steps` array of
/// the `/repos/{owner}/{repo}/actions/jobs/{job_id}` endpoint — including for
/// in-progress jobs, which is what powers live step progress.
class GitHubJobStep {
  /// Creates a [GitHubJobStep].
  const GitHubJobStep({
    required this.number,
    required this.name,
    required this.status,
    this.conclusion,
    this.startedAt,
    this.completedAt,
  });

  /// Creates a [GitHubJobStep] from JSON.
  factory GitHubJobStep.fromJson(Map<String, dynamic> json) {
    return GitHubJobStep(
      number: (json['number'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conclusion: json['conclusion'] as String?,
      startedAt: parseDate(json['started_at']),
      completedAt: parseDate(json['completed_at']),
    );
  }

  /// Serializes back to JSON (used by tests).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'name': name,
    'status': status,
    'conclusion': conclusion,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  /// 1-based step index within the job.
  final int number;

  /// Step display name (`Set up job`, `Run tests`, `Complete job`, …).
  final String name;

  /// Raw status string (`queued`, `in_progress`, `completed`).
  final String status;

  /// Raw conclusion string when completed (`success`, `failure`, …).
  final String? conclusion;

  /// When the step started.
  final DateTime? startedAt;

  /// When the step completed.
  final DateTime? completedAt;
}

/// A single GitHub Actions job of a workflow run. Returned by the
/// `/repos/{owner}/{repo}/actions/runs/{run_id}/jobs` and
/// `/repos/{owner}/{repo}/actions/jobs/{job_id}` endpoints.
class GitHubJobRun {
  /// Creates a [GitHubJobRun].
  const GitHubJobRun({
    required this.id,
    required this.runId,
    required this.name,
    required this.status,
    this.conclusion,
    this.htmlUrl = '',
    this.checkRunUrl = '',
    this.startedAt,
    this.completedAt,
    this.steps = const [],
  });

  /// Creates a [GitHubJobRun] from JSON.
  factory GitHubJobRun.fromJson(Map<String, dynamic> json) {
    return GitHubJobRun(
      id: (json['id'] as num?)?.toInt() ?? 0,
      runId: (json['run_id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      conclusion: json['conclusion'] as String?,
      htmlUrl: json['html_url'] as String? ?? '',
      checkRunUrl: json['check_run_url'] as String? ?? '',
      startedAt: parseDate(json['started_at']),
      completedAt: parseDate(json['completed_at']),
      steps: ((json['steps'] as List?) ?? const [])
          .whereType<Map>()
          .map((s) => GitHubJobStep.fromJson(s.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  /// Serializes back to JSON (used by tests).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'run_id': runId,
    'name': name,
    'status': status,
    'conclusion': conclusion,
    'html_url': htmlUrl,
    'check_run_url': checkRunUrl,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  /// Job id.
  final int id;

  /// Parent workflow run id.
  final int runId;

  /// Job display name (matches the check run name).
  final String name;

  /// Raw status string (`queued`, `in_progress`, `completed`).
  final String status;

  /// Raw conclusion string when completed.
  final String? conclusion;

  /// Link to the job on GitHub.
  final String htmlUrl;

  /// API URL of the check run backing this job — its trailing id is the
  /// check-run id used to join jobs onto check runs.
  final String checkRunUrl;

  /// When the job started.
  final DateTime? startedAt;

  /// When the job completed.
  final DateTime? completedAt;

  /// Step progress (populated for in-progress and completed jobs).
  final List<GitHubJobStep> steps;
}
