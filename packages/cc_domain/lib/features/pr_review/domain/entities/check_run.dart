/// Check run status.
enum CheckRunStatus {
  /// Queued.
  queued,

  /// In progress.
  inProgress,

  /// Completed.
  completed,
}

/// CheckRunStatusExtension helpers.
extension CheckRunStatusExtension on CheckRunStatus {
  /// Name.
  String get name {
    switch (this) {
      case CheckRunStatus.queued:
        return 'queued';
      case CheckRunStatus.inProgress:
        return 'in_progress';
      case CheckRunStatus.completed:
        return 'completed';
    }
  }

  /// From string.
  static CheckRunStatus fromString(String value) {
    switch (value) {
      case 'queued':
        return CheckRunStatus.queued;
      case 'in_progress':
        return CheckRunStatus.inProgress;
      case 'completed':
        return CheckRunStatus.completed;
      default:
        return CheckRunStatus.queued;
    }
  }
}

/// Check run conclusion.
enum CheckRunConclusion {
  /// success.
  success,

  /// failure.
  failure,

  /// neutral.
  neutral,

  /// cancelled.
  cancelled,

  /// skipped.
  skipped,

  /// timedOut.
  timedOut,

  /// actionRequired.
  actionRequired,

  /// stale.
  stale,
}

/// CheckRunConclusionExtension helpers.
extension CheckRunConclusionExtension on CheckRunConclusion {
  /// Name.
  String get name {
    switch (this) {
      case CheckRunConclusion.success:
        return 'success';
      case CheckRunConclusion.failure:
        return 'failure';
      case CheckRunConclusion.neutral:
        return 'neutral';
      case CheckRunConclusion.cancelled:
        return 'cancelled';
      case CheckRunConclusion.skipped:
        return 'skipped';
      case CheckRunConclusion.timedOut:
        return 'timed_out';
      case CheckRunConclusion.actionRequired:
        return 'action_required';
      case CheckRunConclusion.stale:
        return 'stale';
    }
  }

  /// From string.
  static CheckRunConclusion fromString(String value) {
    switch (value) {
      case 'success':
        return CheckRunConclusion.success;
      case 'failure':
        return CheckRunConclusion.failure;
      case 'neutral':
        return CheckRunConclusion.neutral;
      case 'cancelled':
        return CheckRunConclusion.cancelled;
      case 'skipped':
        return CheckRunConclusion.skipped;
      case 'timed_out':
        return CheckRunConclusion.timedOut;
      case 'action_required':
        return CheckRunConclusion.actionRequired;
      case 'stale':
        return CheckRunConclusion.stale;
      default:
        return CheckRunConclusion.neutral;
    }
  }
}

/// Check run.
class CheckRun {
  /// Creates a new [CheckRun].
  CheckRun({
    required this.name,
    required this.status,
    required this.conclusion,
    this.htmlUrl = '',
    this.completedAt,
    this.output = '',
    this.workflowName,
    this.checkSuiteId,
  }) : assert(name.isNotEmpty, 'CheckRun name must not be empty');

  /// Returns a copy with the given overrides applied.
  CheckRun copyWith({String? workflowName, int? checkSuiteId}) {
    return CheckRun(
      name: name,
      status: status,
      conclusion: conclusion,
      htmlUrl: htmlUrl,
      completedAt: completedAt,
      output: output,
      workflowName: workflowName ?? this.workflowName,
      checkSuiteId: checkSuiteId ?? this.checkSuiteId,
    );
  }

  /// Name.
  final String name;

  /// Status.
  final CheckRunStatus status;

  /// Conclusion.
  final CheckRunConclusion? conclusion;

  /// HTML URL.
  final String htmlUrl;

  /// Completed at timestamp.
  final DateTime? completedAt;

  /// output.
  final String output;

  /// Display name of the parent workflow when known (resolved via the
  /// `actions/runs` API by joining on [checkSuiteId]). Null for checks that
  /// didn't come from GitHub Actions or that we couldn't resolve.
  final String? workflowName;

  /// ID of the check suite this run belongs to. For GitHub Actions checks,
  /// the matching workflow run shares the same `check_suite_id`.
  final int? checkSuiteId;

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
      other is CheckRun &&
          runtimeType == other.runtimeType &&
          name == other.name;

  /// Hash code.
  @override
  int get hashCode => name.hashCode;
}
