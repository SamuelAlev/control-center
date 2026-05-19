import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The result of a `fleet.registerWorker` call.
typedef WorkerRegistrationResult = ({
  /// The id the server assigned this worker (used on every subsequent call).
  String workerId,

  /// The protocol version the server speaks.
  int serverProtocolVersion,

  /// Whether the worker and server protocol versions are compatible.
  bool compatible,
});

/// The result of a `fleet.workerPoll` call.
typedef WorkerPollResult = ({
  /// Newly leased jobs the worker should start.
  List<LeaseOffer> leases,

  /// Ids of running jobs the server has terminated; the worker must stop them.
  List<String> cancelledJobIds,
});

/// A typed wrapper over [RemoteRpcClient] for the worker-facing fleet RPC ops
/// (PRD 20 §1, §3, §8).
///
/// Speaks the exact op names and argument shapes the server's
/// `buildFleetWorkerOps` declares. Stateless: it forwards to the underlying
/// client and reshapes the responses into typed records.
class FleetClient {
  /// Creates a [FleetClient] over an authenticated, started [RemoteRpcClient].
  FleetClient(this._rpc);

  final RemoteRpcClient _rpc;

  /// Registers this worker and its capabilities (`fleet.registerWorker`).
  Future<WorkerRegistrationResult> registerWorker({
    required WorkerRegistration registration,
    String? workerId,
  }) async {
    final data = await _rpc.call('fleet.registerWorker', <String, dynamic>{
      'registration': registration.toJson(),
      'worker_id': ?workerId,
    });
    return (
      workerId: data['workerId'] as String? ?? workerId ?? '',
      serverProtocolVersion:
          (data['serverProtocolVersion'] as num?)?.toInt() ?? 0,
      compatible: data['compatible'] as bool? ?? false,
    );
  }

  /// Sends a liveness heartbeat with the current capabilities
  /// (`fleet.workerHeartbeat`).
  Future<void> heartbeat({
    required String workerId,
    required int protocolVersion,
    String? capsJson,
  }) async {
    await _rpc.call('fleet.workerHeartbeat', <String, dynamic>{
      'worker_id': workerId,
      'protocol_version': protocolVersion,
      'caps_json': ?capsJson,
    });
  }

  /// Pulls newly leased jobs and server-side cancellations (`fleet.workerPoll`).
  Future<WorkerPollResult> poll({
    required String workerId,
    required List<String> activeJobIds,
  }) async {
    final data = await _rpc.call('fleet.workerPoll', <String, dynamic>{
      'worker_id': workerId,
      'active_job_ids': activeJobIds,
    });
    final leases = ((data['leases'] as List?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((m) => LeaseOffer.fromJson(m.cast<String, dynamic>()))
        .toList();
    final cancelled =
        ((data['cancelledJobIds'] as List?) ?? const <dynamic>[])
            .cast<String>();
    return (leases: leases, cancelledJobIds: cancelled);
  }

  /// Streams a batch of sequenced events (`fleet.workerEvents`) and returns the
  /// server's acked high-water sequence number.
  Future<int> sendEvents(List<WorkerEventFrame> frames) async {
    final data = await _rpc.call('fleet.workerEvents', <String, dynamic>{
      'frames': frames.map((f) => f.toJson()).toList(),
    });
    return (data['ackedSeq'] as num?)?.toInt() ?? 0;
  }

  /// Reports terminal job completion (`fleet.workerComplete`).
  Future<void> complete(JobCompletionReport report) async {
    await _rpc.call('fleet.workerComplete', <String, dynamic>{
      'report': report.toJson(),
    });
  }
}
