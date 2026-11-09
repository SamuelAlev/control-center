import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads pipeline runs and step runs over the RPC client instead of a local
/// database, and deletes a finished run.
///
/// Read-only otherwise: run rows are written only by the server's engine, and
/// a client changes a run through the `pipeline.*` engine ops
/// (`RemotePipelineEngine`). A workspace id selects the database file
/// server-side, so every call that can name its workspace does (`workspace_id`
/// in the args). The exceptions are the run-id-addressed reads ([getRun],
/// [watchRun], [stepRunsForPipeline], [watchStepRunsForPipeline]) and
/// [watchAll]: a run id routes to its own workspace server-side. A STEP-run id
/// does not route — it is always paired with a workspace.
/// Mirrors the `pipeline_run.*` ops + the
/// `pipeline_run.watchRun` / `pipeline_run.watchAll` /
/// `pipeline_run.watchForWorkspace` / `pipeline_run.watchStepRunsForPipeline`
/// subscriptions in the host catalog.
class RemotePipelineRunRepository {
  /// Creates a [RemotePipelineRunRepository] over [_client].
  RemotePipelineRunRepository(this._client);

  final RemoteRpcClient _client;

  /// A single pipeline run by id (scoped by the `workspace_id` the request carries),
  /// or null when it does not exist.
  Future<PipelineRunDto?> getRun(String id) async {
    final data = await _client.call('pipeline_run.getRun', {'id': id});
    final run = data['run'];
    return run is Map
        ? PipelineRunDto.fromJson(run.cast<String, dynamic>())
        : null;
  }

  /// The active non-terminal run for `(templateId, workspaceId, dedupKey)`, or
  /// null.
  Future<PipelineRunDto?> activeForDedupKey({
    required String workspaceId,
    required String templateId,
    required String dedupKey,
  }) async {
    final data = await _client.call('pipeline_run.activeForDedupKey', {
      'workspace_id': workspaceId,
      'template_id': templateId,
      'dedup_key': dedupKey,
    });
    final run = data['run'];
    return run is Map
        ? PipelineRunDto.fromJson(run.cast<String, dynamic>())
        : null;
  }

  /// Deletes a finished pipeline run (and its step runs via cascade) from
  /// [workspaceId]. The host refuses a live run (cancel it first) and one
  /// owned by another workspace.
  Future<void> deleteRun(String workspaceId, String runId) => _client.call(
    'pipeline_run.deleteRun',
    {'workspace_id': workspaceId, 'run_id': runId},
  );

  /// All step runs for [pipelineRunId] (ownership-checked server-side).
  Future<List<PipelineStepRunDto>> stepRunsForPipeline(
    String pipelineRunId,
  ) async {
    final data = await _client.call('pipeline_run.stepRunsForPipeline', {
      'pipeline_run_id': pipelineRunId,
    });
    return _stepRuns(data);
  }

  /// A single step run by its id within [workspaceId], or null.
  Future<PipelineStepRunDto?> getStepRunById(
    String workspaceId,
    String stepRunId,
  ) async {
    final data = await _client.call('pipeline_run.getStepRunById', {
      'workspace_id': workspaceId,
      'step_run_id': stepRunId,
    });
    final stepRun = data['step_run'];
    return stepRun is Map
        ? PipelineStepRunDto.fromJson(stepRun.cast<String, dynamic>())
        : null;
  }

  /// Live single pipeline run by id (scoped to the bound workspace
  /// server-side) — a fresh snapshot on every change, or null when absent.
  Stream<PipelineRunDto?> watchRun(String id) =>
      _client.subscribe('pipeline_run.watchRun', {'id': id}).map((data) {
        final run = data['run'];
        return run is Map
            ? PipelineRunDto.fromJson(run.cast<String, dynamic>())
            : null;
      });

  /// Live pipeline runs across ALL workspaces, newest first.
  Stream<List<PipelineRunDto>> watchAll() =>
      _client.subscribe('pipeline_run.watchAll', const {}).map(_runs);

  /// Live pipeline runs for [workspaceId], newest first.
  Stream<List<PipelineRunDto>> watchForWorkspace(String workspaceId) => _client
      .subscribe('pipeline_run.watchForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map(_runs);

  /// Live step runs for [pipelineRunId] (ownership-checked server-side).
  Stream<List<PipelineStepRunDto>> watchStepRunsForPipeline(
    String pipelineRunId, {
    String? workspaceId,
  }) => _client
      .subscribe('pipeline_run.watchStepRunsForPipeline', {
        'workspace_id': ?workspaceId,
        'pipeline_run_id': pipelineRunId,
      })
      .map(_stepRuns);

  List<PipelineRunDto> _runs(Map<String, dynamic> data) =>
      ((data['runs'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => PipelineRunDto.fromJson(r.cast<String, dynamic>()))
          .toList();

  List<PipelineStepRunDto> _stepRuns(Map<String, dynamic> data) =>
      ((data['step_runs'] as List?) ?? const [])
          .whereType<Map>()
          .map((r) => PipelineStepRunDto.fromJson(r.cast<String, dynamic>()))
          .toList();
}
