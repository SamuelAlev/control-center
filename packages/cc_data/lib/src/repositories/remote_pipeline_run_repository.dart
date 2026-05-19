import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates pipeline runs and step runs over the RPC client instead of a
/// local database.
///
/// Backs the web build and the desktop in REMOTE mode. A workspace id selects
/// the database file server-side, so every call that can name its workspace does
/// (`workspace_id` in the args). The exceptions are the run-id-addressed ops
/// ([getRun], [watchRun], [updateRunState], [incrementCost],
/// [stepRunsForPipeline], [watchStepRunsForPipeline]) and the cross-workspace
/// startup views ([nonTerminalRuns], [watchAll]): a run id routes to its own
/// workspace server-side and the reconciler runs before any workspace is
/// chosen. A STEP-run id does not route — it is always paired with a workspace.
/// Mirrors the `pipeline_run.*` ops + the
/// `pipeline_run.watchRun` / `pipeline_run.watchAll` /
/// `pipeline_run.watchForWorkspace` / `pipeline_run.watchStepRunsForPipeline`
/// subscriptions in the host catalog.
class RemotePipelineRunRepository {
  /// Creates a [RemotePipelineRunRepository] over [_client].
  RemotePipelineRunRepository(this._client);

  final RemoteRpcClient _client;

  /// Inserts a new pipeline run (the host owns persistence).
  Future<void> insertRun(PipelineRunDto run) =>
      _client.call('pipeline_run.insertRun', {
        // The run's own workspace, sent explicitly rather than left to the
        // client's ambient session id: the host asserts the two agree, so
        // relying on the ambient value only means the assertion fires whenever
        // the caller is on another workspace's route.
        'workspace_id': run.workspaceId,
        'run': run.toJson(),
      });

  /// Updates an existing pipeline run.
  Future<void> updateRun(PipelineRunDto run) => _client.call(
    'pipeline_run.updateRun',
    {'workspace_id': run.workspaceId, 'run': run.toJson()},
  );

  /// A single pipeline run by id (scoped by the `workspace_id` the request carries),
  /// or null when it does not exist.
  Future<PipelineRunDto?> getRun(String id) async {
    final data = await _client.call('pipeline_run.getRun', {'id': id});
    final run = data['run'];
    return run is Map
        ? PipelineRunDto.fromJson(run.cast<String, dynamic>())
        : null;
  }

  /// Replaces the run's state JSON bag.
  Future<void> updateRunState(String runId, Map<String, dynamic> state) =>
      _client.call('pipeline_run.updateRunState', {
        'run_id': runId,
        'state': state,
      });

  /// Adds [cents] and [tokens] to the run's aggregated cost totals.
  Future<void> incrementCost(String runId, int cents, int tokens) =>
      _client.call('pipeline_run.incrementCost', {
        'run_id': runId,
        'cents': cents,
        'tokens': tokens,
      });

  /// All non-terminal runs across ALL workspaces (resume-on-startup view).
  Future<List<PipelineRunDto>> nonTerminalRuns() async {
    final data = await _client.call('pipeline_run.nonTerminalRuns', const {});
    return _runs(data);
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

  /// Deletes a pipeline run (and its step runs via cascade) from
  /// [workspaceId]. A run owned by another workspace is not matched.
  Future<void> deleteRun(String workspaceId, String runId) => _client.call(
    'pipeline_run.deleteRun',
    {'workspace_id': workspaceId, 'run_id': runId},
  );

  /// Inserts a new step run.
  Future<void> insertStepRun(PipelineStepRunDto stepRun) => _client.call(
    'pipeline_run.insertStepRun',
    {'step_run': stepRun.toJson()},
  );

  /// Updates a step run's status and optional fields within [workspaceId].
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    String? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    String? finishedAt,
  }) => _client.call('pipeline_run.updateStepRun', {
    'workspace_id': workspaceId,
    'step_run_id': stepRunId,
    'status': ?status,
    'input_json': ?inputJson,
    'output_json': ?outputJson,
    'channel_id': ?channelId,
    'error_message': ?errorMessage,
    'error_stack_trace': ?errorStackTrace,
    'finished_at': ?finishedAt,
  });

  /// Deletes a single step run row from [workspaceId].
  Future<void> deleteStepRun(String workspaceId, String stepRunId) =>
      _client.call('pipeline_run.deleteStepRun', {
        'workspace_id': workspaceId,
        'step_run_id': stepRunId,
      });

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
    String pipelineRunId,
  ) => _client
      .subscribe('pipeline_run.watchStepRunsForPipeline', {
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
