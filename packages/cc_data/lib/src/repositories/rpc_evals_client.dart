import 'package:cc_rpc/cc_rpc.dart';

DateTime? _date(Object? iso) => iso is String ? DateTime.tryParse(iso) : null;

List<Map<String, dynamic>> _maps(Object? raw) => ((raw as List?) ?? const [])
    .whereType<Map>()
    .map((m) => m.cast<String, dynamic>())
    .toList();

/// An eval suite as the evals surface sees it (PRD 21 §5).
class EvalSuiteView {
  /// Creates an [EvalSuiteView].
  const EvalSuiteView({
    required this.id,
    required this.name,
    required this.description,
    required this.defaultBatchSize,
    required this.isStarter,
  });

  /// Parses from the `evals.watchSuites` wire map.
  factory EvalSuiteView.fromWire(Map<String, dynamic> w) => EvalSuiteView(
    id: w['id'] as String? ?? '',
    name: w['name'] as String? ?? '',
    description: w['description'] as String? ?? '',
    defaultBatchSize: (w['defaultBatchSize'] as num?)?.toInt() ?? 1,
    isStarter: w['isStarter'] as bool? ?? false,
  );

  /// Suite id.
  final String id;

  /// Suite name.
  final String name;

  /// Description.
  final String description;

  /// Default batch size.
  final int defaultBatchSize;

  /// Whether it's a built-in starter suite.
  final bool isStarter;
}

/// An eval run (batch result) as the evals surface sees it (PRD 21 §5).
class EvalRunView {
  /// Creates an [EvalRunView].
  const EvalRunView({
    required this.id,
    required this.suiteId,
    required this.configHash,
    required this.batchSize,
    required this.passRate,
    required this.status,
    required this.costCents,
    required this.triggeredBy,
    this.createdAt,
    this.scorecardJson,
  });

  /// Parses from the `evals.watchRunsForSuite` wire map.
  factory EvalRunView.fromWire(Map<String, dynamic> w) => EvalRunView(
    id: w['id'] as String? ?? '',
    suiteId: w['suiteId'] as String? ?? '',
    configHash: w['configHash'] as String? ?? '',
    batchSize: (w['batchSize'] as num?)?.toInt() ?? 0,
    passRate: (w['passRate'] as num?)?.toDouble() ?? 0,
    status: w['status'] as String? ?? 'queued',
    costCents: (w['costCents'] as num?)?.toInt() ?? 0,
    triggeredBy: w['triggeredBy'] as String? ?? 'manual',
    createdAt: _date(w['createdAt']),
    scorecardJson: w['scorecardJson'] as String?,
  );

  /// Run id.
  final String id;

  /// The suite that ran.
  final String suiteId;

  /// The config hash evaluated.
  final String configHash;

  /// Batch size.
  final int batchSize;

  /// Aggregate pass-rate `[0,1]`.
  final double passRate;

  /// Status.
  final String status;

  /// Metered cost in cents.
  final int costCents;

  /// What triggered it.
  final String triggeredBy;

  /// Creation time.
  final DateTime? createdAt;

  /// The full scorecard JSON, when done.
  final String? scorecardJson;
}

/// An agent's measured reliability, for the autonomy dial (PRD 21 §7).
class ReliabilityView {
  /// Creates a [ReliabilityView].
  const ReliabilityView({
    required this.score,
    required this.recommended,
    required this.rationale,
  });

  /// Parses from the `evals.reliability` wire map.
  factory ReliabilityView.fromWire(Map<String, dynamic> w) => ReliabilityView(
    score: (w['score'] as num?)?.toDouble() ?? 0,
    recommended: w['recommended'] as String? ?? 'observe_only',
    rationale: ((w['rationale'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
  );

  /// The reliability score `[0,1]`.
  final double score;

  /// The recommended autonomy wire string.
  final String recommended;

  /// The evidence lines shown on the dial.
  final List<String> rationale;
}

/// Client access to agent evals (PRD 21): live suites/runs/recordings/goldens,
/// suite CRUD, batch runs, golden blessing, and reliability — over `evals.*`.
class RpcEvalsClient {
  /// Creates an [RpcEvalsClient] over the RPC [_client].
  RpcEvalsClient(this._client);

  final RemoteRpcClient _client;

  /// Live suites for the active workspace.
  Stream<List<EvalSuiteView>> watchSuites() => _client
      .subscribe('evals.watchSuites', const {})
      .map((d) => _maps(d['suites']).map(EvalSuiteView.fromWire).toList());

  /// Live runs for one suite.
  Stream<List<EvalRunView>> watchRunsForSuite(String suiteId) => _client
      .subscribe('evals.watchRunsForSuite', {'suite_id': suiteId})
      .map((d) => _maps(d['runs']).map(EvalRunView.fromWire).toList());

  /// Creates or updates a suite.
  Future<String> upsertSuite({
    String? id,
    required String name,
    String description = '',
    Map<String, dynamic> task = const {},
    List<Map<String, dynamic>> graders = const [],
    int defaultBatchSize = 1,
  }) async {
    final data = await _client.call('evals.upsertSuite', {
      'id': ?id,
      'name': name,
      'description': description,
      'task': task,
      'graders': graders,
      'default_batch_size': defaultBatchSize,
    });
    return data['id'] as String? ?? '';
  }

  /// Deletes a suite.
  Future<void> deleteSuite(String suiteId) =>
      _client.call('evals.deleteSuite', {'suite_id': suiteId});

  /// Runs a suite batch and returns the scorecard map.
  Future<Map<String, dynamic>> runSuite(
    String suiteId, {
    int? batchSize,
    String? configHash,
  }) async {
    final data = await _client.call('evals.runSuite', {
      'suite_id': suiteId,
      'batch_size': ?batchSize,
      'config_hash': ?configHash,
    });
    return (data['scorecard'] as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Blesses a recording as a golden for an agent.
  Future<String> blessGolden({
    required String agentId,
    required String recordingId,
    String mode = 'deterministic',
    String name = '',
  }) async {
    final data = await _client.call('evals.blessGolden', {
      'agent_id': agentId,
      'recording_id': recordingId,
      'mode': mode,
      'name': name,
    });
    return data['id'] as String? ?? '';
  }

  /// The measured reliability for an agent.
  Future<ReliabilityView> reliability(String agentId) async {
    final data = await _client.call('evals.reliability', {'agent_id': agentId});
    return ReliabilityView.fromWire(
      (data['reliability'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
