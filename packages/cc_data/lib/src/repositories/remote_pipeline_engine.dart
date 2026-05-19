import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Drives the host's pipeline EXECUTOR (the `PipelineEngine`) over the RPC
/// client — the thin-client run-control path (start / cancel / retry a run,
/// kill a step).
///
/// Forwards every method to the matching `pipeline.*` op the host catalog
/// registers (wired only by a host that constructs the engine — the desktop
/// in-process host; a pure-Dart headless server omits the ops). The run
/// executes SERVER-SIDE; live run/step state streams back via the existing
/// `pipeline_run.watch*` subscriptions, so this wrapper has no streaming
/// surface of its own. Against a HEADLESS server (which omits the `pipeline.*`
/// ops) the calls fail loudly — the web client then surfaces an honest
/// "pipelines run on the server host" state.
///
/// Carries no `workspace_id`: every `pipeline.*` op is workspace-scoped, so the
/// host injects the authoritative bound workspace per session and validates
/// run/step ownership before touching the engine (the workspace-isolation
/// invariant).
class RemotePipelineEngine {
  /// Creates a [RemotePipelineEngine] over [_client].
  RemotePipelineEngine(this._client);

  final RemoteRpcClient _client;

  /// Starts a pipeline run for [templateId] in the bound workspace; returns the
  /// created run DTO (or null when the engine declined to start one — e.g. a
  /// dedup-key collision).
  Future<PipelineRunDto?> start(
    String templateId, {
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  }) async {
    final data = await _client.call('pipeline.start', {
      'template_id': templateId,
      'trigger_event_type': ?triggerEventType,
      'trigger_payload': ?triggerPayload,
      'dedup_key': ?dedupKey,
      'parent_pipeline_run_id': ?parentPipelineRunId,
      'parent_step_id': ?parentStepId,
      'dry_run': dryRun,
    });
    final run = data['run'];
    return run is Map
        ? PipelineRunDto.fromJson(run.cast<String, dynamic>())
        : null;
  }

  /// Cancels an in-flight run (ownership-checked server-side).
  Future<void> cancel(String pipelineRunId) =>
      _client.call('pipeline.cancel', {'pipeline_run_id': pipelineRunId});

  /// Retries a failed run from its failed step (ownership-checked server-side).
  Future<void> retry(String pipelineRunId) =>
      _client.call('pipeline.retry', {'pipeline_run_id': pipelineRunId});

  /// Kills a single in-flight step's live work (ownership-checked through its
  /// parent run server-side).
  Future<void> killStep(String stepRunId) =>
      _client.call('pipeline.killStep', {'step_run_id': stepRunId});
}
