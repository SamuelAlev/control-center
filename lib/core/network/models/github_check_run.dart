import 'package:control_center/core/network/models/date_parser.dart';

/// Status of a [GitHubCheckRun].
enum GitHubCheckStatus {
  /// Queued, not yet running.
  queued,

  /// In progress.
  inProgress,

  /// Completed (terminal state — see [GitHubCheckConclusion] for outcome).
  completed,

  /// Unknown state.
  unknown,
}

/// Conclusion of a completed [GitHubCheckRun].
enum GitHubCheckConclusion {
  /// Check passed.
  success,

  /// Check failed.
  failure,

  /// Check is neutral (informational).
  neutral,

  /// Check was cancelled.
  cancelled,

  /// Check timed out.
  timedOut,

  /// Check action required from user.
  actionRequired,

  /// Check was skipped.
  skipped,

  /// Check is stale.
  stale,

  /// No conclusion yet.
  none,
}

/// A single check run produced by GitHub Actions or an external CI.
class GitHubCheckRun {
  /// Creates a [GitHubCheckRun].
  const GitHubCheckRun({
    required this.id,
    required this.name,
    required this.status,
    required this.conclusion,
    required this.appName,
    required this.htmlUrl,
    this.startedAt,
    this.completedAt,
    this.output = '',
    this.outputTitle = '',
    this.checkSuiteId,
  });

  /// Creates a [GitHubCheckRun] from JSON.
  factory GitHubCheckRun.fromJson(Map<String, dynamic> json) {
    final app = json['app'] as Map<String, dynamic>?;
    final output = json['output'] as Map<String, dynamic>?;
    final checkSuite = json['check_suite'] as Map<String, dynamic>?;
    return GitHubCheckRun(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      status: _statusFromString(json['status'] as String?),
      conclusion: _conclusionFromString(json['conclusion'] as String?),
      appName: app?['name'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      startedAt: parseDate(json['started_at']),
      completedAt: parseDate(json['completed_at']),
      output: output?['summary'] as String? ?? output?['text'] as String? ?? '',
      outputTitle: output?['title'] as String? ?? '',
      checkSuiteId: (checkSuite?['id'] as num?)?.toInt(),
    );
  }

  /// Serializes this check run back to the GitHub JSON shape.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'status': _statusToString(status),
    'conclusion': _conclusionToString(conclusion),
    'app': <String, dynamic>{'name': appName},
    'html_url': htmlUrl,
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'output': <String, dynamic>{'summary': output, 'title': outputTitle},
    if (checkSuiteId != null)
      'check_suite': <String, dynamic>{'id': checkSuiteId},
  };

  /// Check run id.
  final int id;

  /// Check run name (e.g. `build-and-test`).
  final String name;

  /// Current status.
  final GitHubCheckStatus status;

  /// Conclusion (only meaningful when [status] is `completed`).
  final GitHubCheckConclusion conclusion;

  /// Name of the app that produced the check (e.g. `GitHub Actions`).
  final String appName;

  /// Link to the check details on GitHub.
  final String htmlUrl;

  /// When the run started.
  final DateTime? startedAt;

  /// When the run completed.
  final DateTime? completedAt;

  /// Output summary text.
  final String output;

  /// Output title.
  final String outputTitle;

  /// ID of the parent check suite. For GitHub Actions checks, this links the
  /// run to a workflow run via the workflow_runs API (`check_suite_id`).
  /// Null for legacy responses that didn't expose this field.
  final int? checkSuiteId;

  /// Whether the check has finished.
  bool get isComplete => status == GitHubCheckStatus.completed;

  /// Whether the check failed (regardless of cause).
  bool get isFailing =>
      conclusion == GitHubCheckConclusion.failure ||
      conclusion == GitHubCheckConclusion.timedOut ||
      conclusion == GitHubCheckConclusion.actionRequired;

  /// Whether the check passed.
  bool get isSuccess => conclusion == GitHubCheckConclusion.success;
}

GitHubCheckStatus _statusFromString(String? raw) {
  switch (raw) {
    case 'queued':
      return GitHubCheckStatus.queued;
    case 'in_progress':
      return GitHubCheckStatus.inProgress;
    case 'completed':
      return GitHubCheckStatus.completed;
    default:
      return GitHubCheckStatus.unknown;
  }
}

String? _statusToString(GitHubCheckStatus status) {
  switch (status) {
    case GitHubCheckStatus.queued:
      return 'queued';
    case GitHubCheckStatus.inProgress:
      return 'in_progress';
    case GitHubCheckStatus.completed:
      return 'completed';
    case GitHubCheckStatus.unknown:
      return null;
  }
}

GitHubCheckConclusion _conclusionFromString(String? raw) {
  switch (raw) {
    case 'success':
      return GitHubCheckConclusion.success;
    case 'failure':
      return GitHubCheckConclusion.failure;
    case 'neutral':
      return GitHubCheckConclusion.neutral;
    case 'cancelled':
      return GitHubCheckConclusion.cancelled;
    case 'timed_out':
      return GitHubCheckConclusion.timedOut;
    case 'action_required':
      return GitHubCheckConclusion.actionRequired;
    case 'skipped':
      return GitHubCheckConclusion.skipped;
    case 'stale':
      return GitHubCheckConclusion.stale;
    default:
      return GitHubCheckConclusion.none;
  }
}

String? _conclusionToString(GitHubCheckConclusion conclusion) {
  switch (conclusion) {
    case GitHubCheckConclusion.success:
      return 'success';
    case GitHubCheckConclusion.failure:
      return 'failure';
    case GitHubCheckConclusion.neutral:
      return 'neutral';
    case GitHubCheckConclusion.cancelled:
      return 'cancelled';
    case GitHubCheckConclusion.timedOut:
      return 'timed_out';
    case GitHubCheckConclusion.actionRequired:
      return 'action_required';
    case GitHubCheckConclusion.skipped:
      return 'skipped';
    case GitHubCheckConclusion.stale:
      return 'stale';
    case GitHubCheckConclusion.none:
      return null;
  }
}
