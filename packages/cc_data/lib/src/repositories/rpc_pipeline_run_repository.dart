import 'package:cc_data/src/repositories/remote_pipeline_run_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [PipelineRunRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `pipeline_run.*` ops + the
/// `pipeline_run.watchRun` / `pipeline_run.watchAll` /
/// `pipeline_run.watchForWorkspace` / `pipeline_run.watchStepRunsForPipeline`
/// subscriptions, mapping the [PipelineRunDto] / [PipelineStepRunDto] wire
/// shapes back to [PipelineRun] / [PipelineStepRun]. The host owns persistence;
/// this client never touches a database.
class RpcPipelineRunRepository implements PipelineRunRepository {
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
    finishedAt: d.finishedAt == null ? null : DateTime.parse(d.finishedAt!),
    errorMessage: d.errorMessage,
    errorStackTrace: d.errorStackTrace,
    parentPipelineRunId: d.parentPipelineRunId,
    parentStepId: d.parentStepId,
    templateVersion: d.templateVersion,
    totalCostCents: d.totalCostCents,
    totalTokens: d.totalTokens,
    dryRun: d.dryRun,
  );

  static PipelineRunDto _runToDto(PipelineRun r) => PipelineRunDto(
    id: r.id,
    templateId: r.templateId,
    workspaceId: r.workspaceId,
    status: r.status.name,
    state: r.state,
    triggerEventType: r.triggerEventType,
    triggerPayload: r.triggerPayload,
    dedupKey: r.dedupKey,
    startedAt: r.startedAt.toIso8601String(),
    finishedAt: r.finishedAt?.toIso8601String(),
    errorMessage: r.errorMessage,
    errorStackTrace: r.errorStackTrace,
    parentPipelineRunId: r.parentPipelineRunId,
    parentStepId: r.parentStepId,
    templateVersion: r.templateVersion,
    totalCostCents: r.totalCostCents,
    totalTokens: r.totalTokens,
    dryRun: r.dryRun,
  );

  /// Rebuilds a [PipelineStepRun] from its wire DTO.
  static PipelineStepRun _stepFromDto(PipelineStepRunDto d) => PipelineStepRun(
    id: d.id,
    pipelineRunId: d.pipelineRunId,
    stepId: d.stepId,
    status: PipelineStepStatus.fromString(d.status),
    inputJson: d.inputJson,
    outputJson: d.outputJson,
    channelId: d.channelId,
    errorMessage: d.errorMessage,
    branchIndex: d.branchIndex,
    attemptCount: d.attemptCount,
    startedAt: DateTime.parse(d.startedAt),
    finishedAt: d.finishedAt == null ? null : DateTime.parse(d.finishedAt!),
  );

  static PipelineStepRunDto _stepToDto(PipelineStepRun s) => PipelineStepRunDto(
    id: s.id,
    pipelineRunId: s.pipelineRunId,
    stepId: s.stepId,
    status: s.status.name,
    inputJson: s.inputJson,
    outputJson: s.outputJson,
    channelId: s.channelId,
    errorMessage: s.errorMessage,
    branchIndex: s.branchIndex,
    attemptCount: s.attemptCount,
    startedAt: s.startedAt.toIso8601String(),
    finishedAt: s.finishedAt?.toIso8601String(),
  );

  @override
  Future<void> insertRun(PipelineRun run) => _remote.insertRun(_runToDto(run));

  @override
  Future<void> updateRun(PipelineRun run) => _remote.updateRun(_runToDto(run));

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
  Future<void> updateRunState(String runId, Map<String, dynamic> state) =>
      _remote.updateRunState(runId, state);

  @override
  Future<void> incrementCost(String runId, int cents, int tokens) =>
      _remote.incrementCost(runId, cents, tokens);

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async {
    final dtos = await _remote.nonTerminalRuns();
    return dtos.map(runFromDto).toList();
  }

  @override
  Stream<List<PipelineRun>> watchAll() =>
      _remote.watchAll().map((dtos) => dtos.map(runFromDto).toList());

  @override
  Stream<List<PipelineRun>> watchForWorkspace(String workspaceId) =>
      _remote.watchForWorkspace().map(
        (dtos) => dtos.map(runFromDto).toList(),
      );

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async {
    final dto = await _remote.activeForDedupKey(
      templateId: templateId,
      dedupKey: dedupKey,
    );
    return dto == null ? null : runFromDto(dto);
  }

  @override
  Future<void> deleteRun(String workspaceId, String runId) =>
      _remote.deleteRun(runId);

  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) =>
      _remote.insertStepRun(_stepToDto(stepRun));

  @override
  Future<void> updateStepRun(
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) => _remote.updateStepRun(
    stepRunId,
    status: status?.name,
    inputJson: inputJson,
    outputJson: outputJson,
    channelId: channelId,
    errorMessage: errorMessage,
    errorStackTrace: errorStackTrace,
    finishedAt: finishedAt?.toIso8601String(),
  );

  @override
  Future<void> deleteStepRun(String stepRunId) =>
      _remote.deleteStepRun(stepRunId);

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(
    String pipelineRunId,
  ) async {
    final dtos = await _remote.stepRunsForPipeline(pipelineRunId);
    return dtos.map(_stepFromDto).toList();
  }

  @override
  Future<PipelineStepRun?> getStepRunById(String stepRunId) async {
    final dto = await _remote.getStepRunById(stepRunId);
    return dto == null ? null : _stepFromDto(dto);
  }

  @override
  Stream<List<PipelineStepRun>> watchStepRunsForPipeline(String pipelineRunId) =>
      _remote
          .watchStepRunsForPipeline(pipelineRunId)
          .map((dtos) => dtos.map(_stepFromDto).toList());
}
