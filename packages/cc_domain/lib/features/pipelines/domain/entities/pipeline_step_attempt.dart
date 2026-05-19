import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';

/// One finished-or-interrupted firing of a pipeline step, archived when the
/// step's row is re-opened for another go (the Retry button, or a crash-resume
/// re-firing an interrupted step).
///
/// A step run keeps ONE live row — the process registry, the agent run logs
/// and the step's conversation all address it — so re-firing reuses the row and
/// would otherwise erase the previous outcome. The archive is what lets the
/// operator follow a failure across the retries of a single run instead of
/// each retry silently replacing the last.
///
/// The current firing is never in this list: it is the row itself.
/// `outputJson` is deliberately not archived — failures carry their reason in
/// [errorMessage]/[errorStackTrace], and archiving payloads would grow the row
/// without bound.
class PipelineStepAttempt {
  /// Creates a [PipelineStepAttempt].
  const PipelineStepAttempt({
    required this.status,
    required this.startedAt,
    this.finishedAt,
    this.errorMessage,
    this.errorStackTrace,
  });

  /// Decodes an archived attempt from its JSON map.
  factory PipelineStepAttempt.fromJson(Map<String, dynamic> json) {
    return PipelineStepAttempt(
      status: PipelineStepStatus.fromString(
        json['status'] as String? ?? 'pending',
      ),
      startedAt: json['started_at'] is String
          ? DateTime.parse(json['started_at'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
      finishedAt: json['finished_at'] is String
          ? DateTime.parse(json['finished_at'] as String)
          : null,
      errorMessage: json['error_message'] as String?,
      errorStackTrace: json['error_stack_trace'] as String?,
    );
  }

  /// The status the attempt was in when it was replaced: `failed`/`cancelled`
  /// for an operator retry, or a still-open status (`running`/`suspended`)
  /// when a crash-resume re-fired a step whose process had died — read that
  /// case as "interrupted".
  final PipelineStepStatus status;

  /// When the attempt began.
  final DateTime startedAt;

  /// When the attempt settled, or null when it never did (interrupted).
  final DateTime? finishedAt;

  /// The failure the attempt ended with, if any.
  final String? errorMessage;

  /// Stack trace captured at failure time, if any.
  final String? errorStackTrace;

  /// Whether the attempt never settled — it was still open when the process
  /// died or the row was re-opened underneath it.
  bool get wasInterrupted => finishedAt == null && !status.isTerminal;

  /// Serializes to a JSON map (the shape stored in the step run's
  /// `attempt_history` column and carried on the wire).
  Map<String, dynamic> toJson() => {
    'status': status.toStorageString(),
    'started_at': startedAt.toIso8601String(),
    if (finishedAt != null) 'finished_at': finishedAt!.toIso8601String(),
    if (errorMessage != null) 'error_message': errorMessage,
    if (errorStackTrace != null) 'error_stack_trace': errorStackTrace,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineStepAttempt &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          startedAt == other.startedAt &&
          finishedAt == other.finishedAt &&
          errorMessage == other.errorMessage &&
          errorStackTrace == other.errorStackTrace;

  @override
  int get hashCode =>
      Object.hash(status, startedAt, finishedAt, errorMessage, errorStackTrace);
}
