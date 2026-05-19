import 'package:cc_data/src/repositories/remote_pipeline_engine.dart';
import 'package:cc_data/src/repositories/rpc_pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PipelineEnginePort] backed by the RPC client — the thin-client run-control
/// path (start / cancel / retry a run, kill a step).
///
/// Every action runs SERVER-SIDE: this port forwards to the host's `pipeline.*`
/// ops (the live `PipelineEngine` running on a host that constructs it — the
/// desktop in-process host). Live run/step state streams back via the existing
/// `pipeline_run.watch*` subscriptions; no streaming surface is needed here.
/// Against a HEADLESS server (which omits the `pipeline.*` ops) the calls fail
/// loudly — the web client then surfaces an honest "pipelines run on the server
/// host" state.
///
/// Carries no `workspace_id` on the wire: every `pipeline.*` op is
/// workspace-scoped, so the host injects the authoritative bound workspace per
/// session and a client can never reach another workspace's runs (the
/// workspace-isolation invariant). The [start] `workspaceId` arg is informational
/// only — the host binds the real one.
class RpcPipelineEnginePort implements PipelineEnginePort {
  /// Creates an [RpcPipelineEnginePort] over [client].
  RpcPipelineEnginePort(RemoteRpcClient client)
    : _remote = RemotePipelineEngine(client);

  final RemotePipelineEngine _remote;

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
    final dto = await _remote.start(
      templateId,
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
      dedupKey: dedupKey,
      parentPipelineRunId: parentPipelineRunId,
      parentStepId: parentStepId,
      dryRun: dryRun,
    );
    // Reuse the canonical DTO→entity mapper (no duplicate).
    return dto == null ? null : RpcPipelineRunRepository.runFromDto(dto);
  }

  @override
  Future<void> resumeAll() {
    // Documented no-op: `resumeAll` is a GLOBAL startup reconciler the SERVER
    // runs on its OWN startup (it resumes every interrupted run across ALL
    // workspaces). A thin/web client must never trigger a cross-workspace
    // resume — so there is no `pipeline.resumeAll` op and this is intentionally
    // inert.
    return Future.value();
  }

  @override
  Future<void> cancel(String pipelineRunId) => _remote.cancel(pipelineRunId);

  @override
  Future<void> retry(String pipelineRunId) => _remote.retry(pipelineRunId);

  @override
  Future<void> killStep(String stepRunId) => _remote.killStep(stepRunId);
}
