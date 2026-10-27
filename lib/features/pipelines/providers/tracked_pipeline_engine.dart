import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';

/// [PipelineEnginePort] that records what this client asked of the engine.
///
/// The server reports how runs END (`pipeline_run_finished`); this reports
/// what a person requested from the app: runs started, retried, cancelled and
/// steps killed. Every call is delegated unchanged, and an event is recorded
/// only once the delegate returns, so a refused request is not counted as
/// done.
class TrackedPipelineEngine implements PipelineEnginePort {
  /// Wraps [_inner], recording through [_analytics].
  TrackedPipelineEngine(this._inner, this._analytics);

  final PipelineEnginePort _inner;
  final Analytics _analytics;

  @override
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  }) async {
    final run = await _inner.start(
      templateId,
      workspaceId: workspaceId,
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
      dedupKey: dedupKey,
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      dryRun: dryRun,
    );
    _analytics.track(
      AnalyticsEvents.pipelineRunRequested(
        workspaceId: workspaceId,
        templateId: templateId,
        trigger: AnalyticsEvents.pipelineTriggerKind(triggerEventType),
        dryRun: dryRun,
        started: run != null,
      ),
    );
    return run;
  }

  @override
  Future<void> resumeAll() => _inner.resumeAll();

  @override
  Future<void> cancel(String workspaceId, String pipelineRunId) async {
    await _inner.cancel(workspaceId, pipelineRunId);
    _analytics.track(
      AnalyticsEvents.pipelineRunCancelRequested(
        workspaceId: workspaceId,
        pipelineRunId: pipelineRunId,
      ),
    );
  }

  @override
  Future<void> killStep(String workspaceId, String stepRunId) async {
    await _inner.killStep(workspaceId, stepRunId);
    _analytics.track(
      AnalyticsEvents.pipelineStepKilled(
        workspaceId: workspaceId,
        stepRunId: stepRunId,
      ),
    );
  }

  @override
  Future<void> retry(String workspaceId, String pipelineRunId) async {
    await _inner.retry(workspaceId, pipelineRunId);
    _analytics.track(
      AnalyticsEvents.pipelineRunRetried(
        workspaceId: workspaceId,
        pipelineRunId: pipelineRunId,
      ),
    );
  }
}
