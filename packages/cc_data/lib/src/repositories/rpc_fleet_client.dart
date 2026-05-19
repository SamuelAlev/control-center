import 'package:cc_rpc/cc_rpc.dart';

DateTime? _date(Object? iso) => iso is String ? DateTime.tryParse(iso) : null;

List<String> _strs(Object? raw) =>
    ((raw as List?) ?? const []).map((e) => e.toString()).toList();

List<Map<String, dynamic>> _maps(Object? raw) => ((raw as List?) ?? const [])
    .whereType<Map>()
    .map((m) => m.cast<String, dynamic>())
    .toList();

/// A worker as the fleet panel sees it (PRD 20 §7). A thin read view over the
/// `fleet.*` wire — decoupled from the server-only `Worker` entity.
class FleetWorkerView {
  /// Creates a [FleetWorkerView].
  const FleetWorkerView({
    required this.id,
    required this.name,
    required this.status,
    required this.capabilityKeys,
    required this.platform,
    this.cores = 0,
    this.lastHeartbeatAt,
    this.lastError,
  });

  /// Parses from the `fleet.watchWorkers` wire map.
  factory FleetWorkerView.fromWire(Map<String, dynamic> w) {
    final caps = (w['caps'] as Map?)?.cast<String, dynamic>() ?? const {};
    return FleetWorkerView(
      id: w['id'] as String? ?? '',
      name: w['name'] as String? ?? '',
      status: w['status'] as String? ?? 'offline',
      capabilityKeys: _strs(w['capabilityKeys']),
      platform: caps['os'] as String? ?? 'unknown',
      cores: (caps['cores'] as num?)?.toInt() ?? 0,
      lastHeartbeatAt: _date(w['lastHeartbeatAt']),
      lastError: w['lastError'] as String?,
    );
  }

  /// Worker id.
  final String id;

  /// Worker name.
  final String name;

  /// Lifecycle status wire string.
  final String status;

  /// Advertised capability keys.
  final List<String> capabilityKeys;

  /// Host OS.
  final String platform;

  /// Logical cores.
  final int cores;

  /// Last heartbeat time.
  final DateTime? lastHeartbeatAt;

  /// Last error, if any.
  final String? lastError;
}

/// A job as the fleet panel sees it (PRD 20 §7).
class FleetJobView {
  /// Creates a [FleetJobView].
  const FleetJobView({
    required this.id,
    required this.kind,
    required this.status,
    required this.requiredCaps,
    this.workerId,
    this.pinnedWorkerId,
    this.priority = 0,
    this.attempts = 0,
    this.maxAttempts = 1,
    this.costCents = 0,
    this.error,
    this.createdAt,
  });

  /// Parses from the `fleet.watchJobs` wire map.
  factory FleetJobView.fromWire(Map<String, dynamic> w) => FleetJobView(
    id: w['id'] as String? ?? '',
    kind: w['kind'] as String? ?? '',
    status: w['status'] as String? ?? 'queued',
    requiredCaps: _strs(w['requiredCaps']),
    workerId: w['workerId'] as String?,
    pinnedWorkerId: w['pinnedWorkerId'] as String?,
    priority: (w['priority'] as num?)?.toInt() ?? 0,
    attempts: (w['attempts'] as num?)?.toInt() ?? 0,
    maxAttempts: (w['maxAttempts'] as num?)?.toInt() ?? 1,
    costCents: (w['costCents'] as num?)?.toInt() ?? 0,
    error: w['error'] as String?,
    createdAt: _date(w['createdAt']),
  );

  /// Job id.
  final String id;

  /// Job kind wire string.
  final String kind;

  /// Status wire string.
  final String status;

  /// Required capability keys.
  final List<String> requiredCaps;

  /// The worker currently running it.
  final String? workerId;

  /// The pinned worker, if any.
  final String? pinnedWorkerId;

  /// Scheduling priority.
  final int priority;

  /// Attempt count.
  final int attempts;

  /// Max attempts.
  final int maxAttempts;

  /// Metered cost in cents.
  final int costCents;

  /// Failure reason, if any.
  final String? error;

  /// Submission time.
  final DateTime? createdAt;
}

/// A placement-log entry as the fleet panel sees it (PRD 20 §7).
class FleetPlacementView {
  /// Creates a [FleetPlacementView].
  const FleetPlacementView({
    required this.decision,
    required this.reason,
    this.workerId,
    this.createdAt,
  });

  /// Parses from the `fleet.watchPlacements` wire map.
  factory FleetPlacementView.fromWire(Map<String, dynamic> w) =>
      FleetPlacementView(
        decision: w['decision'] as String? ?? 'queued',
        reason: w['reason'] as String? ?? '',
        workerId: w['workerId'] as String?,
        createdAt: _date(w['createdAt']),
      );

  /// The decision code wire string.
  final String decision;

  /// The human-readable reason.
  final String reason;

  /// The chosen worker, if any.
  final String? workerId;

  /// Decision time.
  final DateTime? createdAt;
}

/// Client access to the fleet (PRD 20 §7): live workers/jobs, placement reasons,
/// job submission/cancellation, and worker drain/resume/revoke/remove — all over
/// the `fleet.*` RPC ops. `workspace_id` is auto-injected by the RPC client.
class RpcFleetClient {
  /// Creates an [RpcFleetClient] over the RPC [_client].
  RpcFleetClient(this._client);

  final RemoteRpcClient _client;

  /// Live worker list (server-global).
  Stream<List<FleetWorkerView>> watchWorkers() => _client
      .subscribe('fleet.watchWorkers', const {})
      .map((d) => _maps(d['workers']).map(FleetWorkerView.fromWire).toList());

  /// Live job list for the active workspace.
  Stream<List<FleetJobView>> watchJobs() => _client
      .subscribe('fleet.watchJobs', const {})
      .map((d) => _maps(d['jobs']).map(FleetJobView.fromWire).toList());

  /// Live placement decisions for one job.
  Stream<List<FleetPlacementView>> watchPlacements(String jobId) => _client
      .subscribe('fleet.watchPlacements', {'job_id': jobId})
      .map(
        (d) => _maps(d['placements']).map(FleetPlacementView.fromWire).toList(),
      );

  /// Submits a job (e.g. a benchmark or eval batch) to the fleet.
  Future<String> submitJob({
    required String kind,
    Map<String, dynamic> spec = const {},
    int priority = 0,
    String? pinnedWorkerId,
    List<String> requiredCaps = const [],
    List<String> preferredCaps = const [],
    int maxAttempts = 1,
  }) async {
    final data = await _client.call('fleet.submitJob', {
      'kind': kind,
      'spec': spec,
      'priority': priority,
      'pinned_worker_id': ?pinnedWorkerId,
      'required_caps': requiredCaps,
      'preferred_caps': preferredCaps,
      'max_attempts': maxAttempts,
    });
    return data['jobId'] as String? ?? '';
  }

  /// Cancels a job.
  Future<void> cancelJob(String jobId) =>
      _client.call('fleet.cancelJob', {'job_id': jobId});

  /// Drains a worker (finish current, take no new leases).
  Future<void> drainWorker(String workerId) =>
      _client.call('fleet.drainWorker', {'worker_id': workerId});

  /// Brings a drained worker back online.
  Future<void> resumeWorker(String workerId) =>
      _client.call('fleet.resumeWorker', {'worker_id': workerId});

  /// Revokes a worker (its session ends; active jobs reap).
  Future<void> revokeWorker(String workerId) =>
      _client.call('fleet.revokeWorker', {'worker_id': workerId});

  /// Removes a worker row entirely.
  Future<void> removeWorker(String workerId) =>
      _client.call('fleet.removeWorker', {'worker_id': workerId});
}
