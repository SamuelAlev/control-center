import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates orchestrations over the RPC client instead of a local
/// database.
///
/// Backs the web build and the desktop in REMOTE mode. The workspace is bound
/// server-side (via `session/set_workspace`), so the workspace-scoped calls
/// never pass a `workspace_id` — the server injects the authoritative one and
/// enforces ownership before touching a row. Mirrors the `orchestration.*` ops
/// + the `orchestration.watchForWorkspace` / `orchestration.watchById`
/// subscriptions in the host catalog.
class RemoteOrchestrationRepository {
  /// Creates a [RemoteOrchestrationRepository] over [_client].
  RemoteOrchestrationRepository(this._client);

  final RemoteRpcClient _client;

  /// Inserts a new orchestration (the host owns persistence).
  Future<void> insert(OrchestrationDto orchestration) =>
      _client.call('orchestration.insert', {
        'orchestration': orchestration.toJson(),
      });

  /// Updates an existing orchestration (scoped to the bound workspace
  /// server-side).
  Future<void> update(OrchestrationDto orchestration) =>
      _client.call('orchestration.update', {
        'orchestration': orchestration.toJson(),
      });

  /// A single orchestration by id (scoped to the bound workspace server-side),
  /// or null when it does not exist.
  Future<OrchestrationDto?> getById(String id) async {
    final data = await _client.call('orchestration.getById', {'id': id});
    return _one(data);
  }

  /// The orchestration anchored to [ticketId] in the bound workspace, or null.
  Future<OrchestrationDto?> forParentTicket(String ticketId) async {
    final data = await _client.call('orchestration.forParentTicket', {
      'ticket_id': ticketId,
    });
    return _one(data);
  }

  /// The orchestration owning [pipelineRunId] in the bound workspace, or null.
  Future<OrchestrationDto?> forPipelineRun(String pipelineRunId) async {
    final data = await _client.call('orchestration.forPipelineRun', {
      'pipeline_run_id': pipelineRunId,
    });
    return _one(data);
  }

  /// The orchestration owning [pipelineRunId] across ALL workspaces (event
  /// routers that receive only a run id), or null.
  Future<OrchestrationDto?> forPipelineRunAnyWorkspace(
    String pipelineRunId,
  ) async {
    final data = await _client.call('orchestration.forPipelineRunAnyWorkspace', {
      'pipeline_run_id': pipelineRunId,
    });
    return _one(data);
  }

  /// Approved orchestrations with no pipeline run yet, across ALL workspaces
  /// (materialization resume on startup).
  Future<List<OrchestrationDto>> approvedNeedingMaterialization() async {
    final data = await _client.call(
      'orchestration.approvedNeedingMaterialization',
      const {},
    );
    return _many(data);
  }

  /// Live orchestrations in the bound workspace — a fresh snapshot on every
  /// change, newest first.
  Stream<List<OrchestrationDto>> watchForWorkspace() => _client
      .subscribe('orchestration.watchForWorkspace', const {})
      .map(_many);

  /// Live single orchestration by id in the bound workspace — a fresh snapshot
  /// ([OrchestrationDto] or null) on every change.
  Stream<OrchestrationDto?> watchById(String id) =>
      _client.subscribe('orchestration.watchById', {'id': id}).map(_one);

  OrchestrationDto? _one(Map<String, dynamic> data) {
    final o = data['orchestration'];
    return o is Map
        ? OrchestrationDto.fromJson(o.cast<String, dynamic>())
        : null;
  }

  List<OrchestrationDto> _many(Map<String, dynamic> data) =>
      ((data['orchestrations'] as List?) ?? const [])
          .whereType<Map>()
          .map((o) => OrchestrationDto.fromJson(o.cast<String, dynamic>()))
          .toList();
}
