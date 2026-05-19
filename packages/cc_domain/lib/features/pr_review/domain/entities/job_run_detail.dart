import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';

/// One step of a GitHub Actions job.
class JobRunStep {
  /// Creates a [JobRunStep].
  JobRunStep({
    required this.number,
    required this.name,
    required this.status,
    this.conclusion,
    this.startedAt,
    this.completedAt,
  });

  /// 1-based step index within the job.
  final int number;

  /// Step display name (`Set up job`, `Run tests`, `Complete job`, …).
  final String name;

  /// Step status.
  final CheckRunStatus status;

  /// Step conclusion when completed.
  final CheckRunConclusion? conclusion;

  /// When the step started.
  final DateTime? startedAt;

  /// When the step completed.
  final DateTime? completedAt;

  /// isComplete.
  bool get isComplete => status == CheckRunStatus.completed;

  /// isSuccess.
  bool get isSuccess => conclusion == CheckRunConclusion.success;

  /// isFailing.
  bool get isFailing =>
      conclusion == CheckRunConclusion.failure ||
      conclusion == CheckRunConclusion.timedOut ||
      conclusion == CheckRunConclusion.actionRequired;

  @override
  /// Equality comparison.
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobRunStep && number == other.number && name == other.name;

  /// Hash code.
  @override
  int get hashCode => Object.hash(number, name);
}

/// Live detail for one GitHub Actions job: step progress (available while
/// running) plus, once published, the tail-truncated logs. [logs] is null
/// until GitHub publishes them (the REST API 404s logs of in-progress jobs).
class JobRunDetail {
  /// Creates a [JobRunDetail].
  JobRunDetail({
    required this.jobId,
    required this.status,
    this.conclusion,
    this.htmlUrl = '',
    this.steps = const [],
    this.logs,
    this.logsTruncated = false,
  });

  /// Job id.
  final int jobId;

  /// Job status.
  final CheckRunStatus status;

  /// Job conclusion when completed.
  final CheckRunConclusion? conclusion;

  /// Link to the job on GitHub.
  final String htmlUrl;

  /// Step progress.
  final List<JobRunStep> steps;

  /// Plain-text job logs (tail-truncated), null until published.
  final String? logs;

  /// Whether [logs] was tail-truncated to the byte cap.
  final bool logsTruncated;

  /// isComplete.
  bool get isComplete => status == CheckRunStatus.completed;

  @override
  /// Equality comparison.
  bool operator ==(Object other) =>
      identical(this, other) || other is JobRunDetail && jobId == other.jobId;

  /// Hash code.
  @override
  int get hashCode => jobId.hashCode;
}
