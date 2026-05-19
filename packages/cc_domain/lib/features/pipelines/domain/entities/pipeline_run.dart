import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';

/// Sentinel distinguishing "argument omitted" from "explicitly null" in
/// [PipelineRun.copyWith] for the nullable [PipelineRun.lastResumedAt] — so a
/// terminal transition can clear it while a status-only copy leaves it intact.
const Object _kUnset = Object();

/// A single execution of a pipeline template.
///
/// Persisted across app restarts so the engine can resume in-flight runs.
class PipelineRun {
  /// Creates a [PipelineRun].
  PipelineRun({
    required this.id,
    required this.templateId,
    required this.workspaceId,
    required this.status,
    Map<String, dynamic>? state,
    this.triggerEventType,
    this.triggerPayload,
    this.dedupKey,
    required this.startedAt,
    this.attemptStartedAt,
    this.attemptCount = 1,
    this.finishedAt,
    this.activeMs = 0,
    this.lastResumedAt,
    this.errorMessage,
    this.errorStackTrace,
    this.parentPipelineRunId,
    this.parentStepId,
    this.templateVersion = 1,
    this.totalCostCents = 0,
    this.totalTokens = 0,
    this.dryRun = false,
  }) : _state = state ?? {};

  /// Unique run identifier (UUID v4).
  final String id;

  /// Which template this run is an instance of.
  final String templateId;

  /// Workspace this run belongs to.
  final String workspaceId;

  /// Current lifecycle status.
  final PipelineRunStatus status;

  /// Mutable state bag shared across steps.
  Map<String, dynamic> get state => Map.unmodifiable(_state);
  final Map<String, dynamic> _state;

  /// Fully-qualified type name of the domain event that triggered this run.
  final String? triggerEventType;

  /// Payload from the trigger event.
  final Map<String, dynamic>? triggerPayload;

  /// Idempotency key for event-triggered runs.
  final String? dedupKey;

  /// When this run FIRST started. Never rewritten: a retry or a crash-resume
  /// stamps [attemptStartedAt] instead, so the run keeps one stable origin.
  final DateTime startedAt;

  /// When the CURRENT attempt began, or null while the run is still on its
  /// first one. See [currentAttemptStartedAt] / [wasRestarted].
  final DateTime? attemptStartedAt;

  /// When this run reached a terminal state.
  final DateTime? finishedAt;

  /// When the attempt an operator is looking at began — [attemptStartedAt]
  /// once the run has been rerun, else [startedAt].
  ///
  /// This is what "started" means on a run's page: after a retry (or a
  /// crash-resume that re-fired its steps) the original instant answers a
  /// question nobody asked, while the run's own work started minutes ago.
  DateTime get currentAttemptStartedAt => attemptStartedAt ?? startedAt;

  /// Which attempt is current, 1-based. Incremented when a run is re-opened
  /// — a re-run, or a crash-resume that re-fires interrupted steps.
  ///
  /// A re-run keeps the run's id, its original [startedAt] and therefore its
  /// place in the list; this is what tells the operator WHICH try they are
  /// looking at, which [attemptStartedAt] alone cannot.
  final int attemptCount;

  /// Whether this run has been rerun at least once (by [attemptStartedAt]).
  bool get wasRestarted => attemptStartedAt != null;

  /// Accumulated **active** run time in milliseconds (PRD 25 §6). Excludes idle
  /// stop→restart gaps: the currently-running segment (`now - lastResumedAt`)
  /// is folded into this on each stop, so the displayed duration never includes
  /// the time a run sat stopped between a failure and a retry (or an app
  /// restart). See [activeDurationAt].
  final int activeMs;

  /// When the run last (re)started running, or null when not running. The live
  /// segment since this instant is added to [activeMs] by [activeDurationAt]
  /// and folded into [activeMs] at the next stop.
  final DateTime? lastResumedAt;

  /// Error message if [status] is [PipelineRunStatus.failed].
  final String? errorMessage;

  /// Stack trace captured at failure time.
  final String? errorStackTrace;

  /// Parent run id when started by a `flow.callPipeline` node (else null).
  final String? parentPipelineRunId;

  /// Parent run's calling step id (paired with [parentPipelineRunId]).
  final String? parentStepId;

  /// Template version this run was pinned to at start.
  final int templateVersion;

  /// Aggregated agent cost for this run, in cents.
  final int totalCostCents;

  /// Aggregated token usage for this run.
  final int totalTokens;

  /// Whether this run is a dry run (side effects skipped).
  final bool dryRun;

  /// Whether this run is in a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Active run time as of [now], excluding idle stop→restart gaps.
  ///
  /// Returns the accumulated [activeMs] plus, when the run is currently
  /// running, the elapsed time since it last resumed ([lastResumedAt]). The
  /// entity is pure and cannot read the wall clock itself, so the caller
  /// supplies [now].
  Duration activeDurationAt(DateTime now) {
    var ms = activeMs;
    if (status == PipelineRunStatus.running && lastResumedAt != null) {
      final live = now.difference(lastResumedAt!).inMilliseconds;
      if (live > 0) {
        ms += live;
      }
    }
    return Duration(milliseconds: ms);
  }

  /// Creates a copy with updated fields.
  ///
  /// [lastResumedAt], [finishedAt], [errorMessage] and [errorStackTrace] are
  /// nullable-aware: omit one to keep the current value, or pass `null`
  /// explicitly to CLEAR it.
  ///
  /// The outcome fields have to be clearable, because re-opening a run is
  /// exactly the transition that has to forget the last one. While they were
  /// plain `??` merges a retried run kept the failed attempt's `finishedAt` and
  /// `errorMessage`, so a run that was busy re-executing still reported when it
  /// had ended and why it had failed.
  PipelineRun copyWith({
    PipelineRunStatus? status,
    Map<String, dynamic>? state,
    DateTime? attemptStartedAt,
    int? attemptCount,
    Object? finishedAt = _kUnset,
    int? activeMs,
    Object? lastResumedAt = _kUnset,
    Object? errorMessage = _kUnset,
    Object? errorStackTrace = _kUnset,
    int? totalCostCents,
    int? totalTokens,
  }) {
    return PipelineRun(
      id: id,
      templateId: templateId,
      workspaceId: workspaceId,
      status: status ?? this.status,
      state: state ?? Map<String, dynamic>.from(_state),
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
      dedupKey: dedupKey,
      startedAt: startedAt,
      attemptStartedAt: attemptStartedAt ?? this.attemptStartedAt,
      attemptCount: attemptCount ?? this.attemptCount,
      finishedAt: identical(finishedAt, _kUnset)
          ? this.finishedAt
          : finishedAt as DateTime?,
      activeMs: activeMs ?? this.activeMs,
      lastResumedAt: identical(lastResumedAt, _kUnset)
          ? this.lastResumedAt
          : lastResumedAt as DateTime?,
      errorMessage: identical(errorMessage, _kUnset)
          ? this.errorMessage
          : errorMessage as String?,
      errorStackTrace: identical(errorStackTrace, _kUnset)
          ? this.errorStackTrace
          : errorStackTrace as String?,
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      templateVersion: templateVersion,
      totalCostCents: totalCostCents ?? this.totalCostCents,
      totalTokens: totalTokens ?? this.totalTokens,
      dryRun: dryRun,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineRun &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          templateId == other.templateId &&
          workspaceId == other.workspaceId &&
          status == other.status &&
          attemptStartedAt == other.attemptStartedAt &&
          attemptCount == other.attemptCount &&
          finishedAt == other.finishedAt &&
          activeMs == other.activeMs &&
          lastResumedAt == other.lastResumedAt &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
    id,
    templateId,
    workspaceId,
    status,
    attemptStartedAt,
    attemptCount,
    finishedAt,
    activeMs,
    lastResumedAt,
    errorMessage,
  );
}
