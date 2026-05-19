import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart' show PipelineRun;
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';

/// A single step execution within a [PipelineRun].
///
/// Persisted to `PipelineStepRunsTable` so the engine can resume from
/// the deepest suspended/pending step after a crash.
class PipelineStepRun {
  /// Creates a [PipelineStepRun].
  const PipelineStepRun({
    required this.id,
    required this.pipelineRunId,
    required this.stepId,
    required this.status,
    this.inputJson,
    this.outputJson,
    this.channelId,
    this.errorMessage,
    this.branchIndex,
    this.attemptCount = 0,
    required this.startedAt,
    this.finishedAt,
  });

  /// Unique step run identifier (UUID v4).
  final String id;

  /// Parent pipeline run.
  final String pipelineRunId;

  /// Step definition ID from the template (e.g. 'setup', 'fetch_context').
  final String stepId;

  /// Current lifecycle status.
  final PipelineStepStatus status;

  /// JSON-serialized input passed to this step.
  final String? inputJson;
  /// JSON-serialized output produced by this step. Null until complete.
  final String? outputJson;

  /// Conversation/channel this step spawned (when it dispatched agents into a
  /// hidden conversation). The step-detail UI links to it; null for steps that
  /// don't create a conversation.
  final String? channelId;

  /// Error message if status is [PipelineStepStatus.failed].
  final String? errorMessage;

  /// Identifies which parallel branch this step belongs to when multiple
  /// `.listen()` calls fan out from the same source. Null for non-parallel.
  final int? branchIndex;

  /// Number of body attempts so far (retry policy bookkeeping).
  final int attemptCount;

  /// When this step was started.
  final DateTime startedAt;

  /// When this step reached a terminal state.
  final DateTime? finishedAt;

  /// Whether this step is in a terminal state.
  bool get isTerminal => status.isTerminal;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipelineStepRun &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pipelineRunId == other.pipelineRunId &&
          stepId == other.stepId &&
          status == other.status &&
          branchIndex == other.branchIndex;

  @override
  int get hashCode => Object.hash(
        id,
        pipelineRunId,
        stepId,
        status,
        branchIndex,
      );
}
