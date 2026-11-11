import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';

/// The trigger-payload key a run's requester is recorded under. Written only
/// by [PipelineEnginePort.start]; never read from step state, which agents can
/// write.
const String kPipelineRequestedByKey = 'requested_by_user_id';

/// The trigger-payload key a run started by an armed trigger records,
/// as a list of user ids, everyone who armed it (or edited it, or its
/// pipeline, while armed) under. Like [kPipelineRequestedByKey], written only
/// by the engine (from the trigger, never a payload) and inherited by
/// sub-pipelines. They are not requesters: the run still acts as the
/// workspace's accountable human. They name who may not approve a pull
/// request the run's agents open.
const String kPipelineArmedByKey = 'armed_by_user_ids';

/// The user ids a run's [payload] records under [kPipelineArmedByKey].
Set<String> pipelineArmedByOf(Map<String, dynamic>? payload) {
  final raw = payload?[kPipelineArmedByKey];
  return {
    if (raw is List)
      for (final id in raw)
        if (id is String && id.isNotEmpty) id,
  };
}

/// Port that decouples `SubPipelineLauncher` from the concrete `PipelineEngine`
/// implementation, breaking the circular dependency between the engine and the
/// body registry.
abstract interface class PipelineEnginePort {
  /// Starts a pipeline run for the given [templateId].
  ///
  /// [requestedByUserId] is the member the run acts for: agents it
  /// dispatches are bounded by that member's forge access. It is recorded
  /// under [kPipelineRequestedByKey] in the trigger payload, and only from
  /// this argument — a payload naming someone is stripped. A sub-pipeline
  /// inherits its parent's. Null means nobody asked (a schedule, a webhook):
  /// the workspace's accountable human bounds the run.
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
    String? requestedByUserId,
  });

  /// Resumes every interrupted run (called on startup).
  Future<void> resumeAll();

  /// Cancels an in-flight pipeline run.
  Future<void> cancel(String workspaceId, String pipelineRunId);

  /// Kills a single in-flight step's live work. [workspaceId] owns [stepRunId];
  /// a step-run id is not routable to a workspace on its own.
  Future<void> killStep(String workspaceId, String stepRunId);

  /// Retries a failed pipeline run from its failed step.
  Future<void> retry(String workspaceId, String pipelineRunId);
}
