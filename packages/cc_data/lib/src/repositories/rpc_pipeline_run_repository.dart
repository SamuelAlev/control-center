import 'package:cc_data/src/repositories/remote_pipeline_run_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_attempt.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PipelineRunReader] backed by the RPC client — the thin-client data path.
///
/// Read-only (plus deleting a finished run): run rows are written only by the
/// server's engine. Implements the reader interface over the host's `pipeline_run.*` ops + the
/// `pipeline_run.watchRun` / `pipeline_run.watchAll` /
/// `pipeline_run.watchForWorkspace` / `pipeline_run.watchStepRunsForPipeline`
/// subscriptions, mapping the [PipelineRunDto] / [PipelineStepRunDto] wire
/// shapes back to [PipelineRun] / [PipelineStepRun]. The host owns persistence;
/// this client never touches a database.
class RpcPipelineRunRepository implements PipelineRunReader {
  /// Creates an [RpcPipelineRunRepository] over [client].
  RpcPipelineRunRepository(RemoteRpcClient client)
    : _remote = RemotePipelineRunRepository(client);

  final RemotePipelineRunRepository _remote;

  /// Rebuilds a [PipelineRun] from its wire DTO. Enum fields are encoded as
  /// `.name`; timestamps are ISO-8601 strings. Public so the
  /// `RpcPipelineEnginePort` (which decodes a `pipeline.start` result) reuses
  /// the same mapper instead of duplicating it.
  static PipelineRun runFromDto(PipelineRunDto d) => PipelineRun(
    id: d.id,
    templateId: d.templateId,
    workspaceId: d.workspaceId,
    status: PipelineRunStatus.fromString(d.status),
    state: d.state,
    triggerEventType: d.triggerEventType,
    triggerPayload: d.triggerPayload,
    dedupKey: d.dedupKey,
    startedAt: DateTime.parse(d.startedAt),
    attemptStartedAt: d.attemptStartedAt == null
        ? null
        : DateTime.parse(d.attemptStartedAt!),
    attemptCount: d.attemptCount,
    finishedAt: d.finishedAt == null ? null : DateTime.parse(d.finishedAt!),
    activeMs: d.activeMs,
    lastResumedAt: d.lastResumedAt == null
        ? null
        : DateTime.parse(d.lastResumedAt!),
    errorMessage: d.errorMessage,
    errorStackTrace: d.errorStackTrace,
    parentPipelineRunId: d.parentPipelineRunId,
    parentStepId: d.parentStepId,
    templateVersion: d.templateVersion,
    templateSnapshot: _snapshotFromWire(d.templateSnapshot),
    totalCostMicros: d.totalCostMicros,
    totalTokens: d.totalTokens,
    dryRun: d.dryRun,
  );

  /// The pinned graph, or null when the host sent none (list views) or sent
  /// one this client cannot read.
  static PipelineDefinition? _snapshotFromWire(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    try {
      return PipelineDefinition.fromJson(json);
    } on Object {
      return null;
    }
  }

  /// Rebuilds a [PipelineStepRun] from its wire DTO.
  static PipelineStepRun _stepFromDto(PipelineStepRunDto d) => PipelineStepRun(
    id: d.id,
    pipelineRunId: d.pipelineRunId,
    stepId: d.stepId,
    status: PipelineStepStatus.fromString(d.status),
    inputJson: d.inputJson,
    outputJson: d.outputJson,
    spaceId: d.spaceId,
    errorMessage: d.errorMessage,
    attemptCount: d.attemptCount,
    priorAttempts: [
      for (final a in d.priorAttempts) PipelineStepAttempt.fromJson(a),
    ],
    startedAt: DateTime.parse(d.startedAt),
    finishedAt: d.finishedAt == null ? null : DateTime.parse(d.finishedAt!),
  );

  @override
  Future<PipelineRun?> getRun(String id) async {
    try {
      final dto = await _remote.getRun(id);
      return dto == null ? null : runFromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Stream<PipelineRun?> watchRun(String id) =>
      _remote.watchRun(id).map((dto) => dto == null ? null : runFromDto(dto));

  @override
  Stream<List<PipelineRun>> watchAll() =>
      _remote.watchAll().map((dtos) => dtos.map(runFromDto).toList());

  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) => _remote
      .watchForWorkspace(workspaceId)
      .map((dtos) => dtos.map(runFromDto).toList());

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async {
    final dto = await _remote.activeForDedupKey(
      workspaceId: workspaceId,
      templateId: templateId,
      dedupKey: dedupKey,
    );
    return dto == null ? null : runFromDto(dto);
  }

  @override
  Future<void> deleteRun(String workspaceId, String runId) =>
      _remote.deleteRun(workspaceId, runId);

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(
    String pipelineRunId,
  ) async {
    final dtos = await _remote.stepRunsForPipeline(pipelineRunId);
    return dtos.map(_stepFromDto).toList();
  }

  @override
  Future<PipelineStepRun?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async {
    final dto = await _remote.getStepRunById(workspaceId, stepRunId);
    return dto == null ? null : _stepFromDto(dto);
  }

  @override
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(
    String pipelineRunId,
  ) => _remote
      .watchStepRunsForPipeline(pipelineRunId)
      .map((dtos) => dtos.map(_stepFromDto).toList());
}
