import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/active_process_info.dart';
import 'package:cc_domain/core/domain/ports/process_detection_port.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ProcessDetectionPort] backed by the RPC client — the thin-client data
/// path for the dashboard's "active agent processes" matrix.
///
/// The agent processes live in the SERVER's OS process table (and killing one
/// stops it on the host), so the thin client reads them over `process.detect`
/// and stops one over `process.kill`. Both are host-global — the OS process
/// table is not workspace data — and the detection spans every workspace's
/// agents (the dashboard's cross-workspace overview), so the host serves them
/// `workspaceScoped: false`. A host that wires no detector leaves the ops absent
/// (default-deny → `opUnknown`); the client degrades to an empty list.
class RpcProcessDetectionPort implements ProcessDetectionPort {
  /// Creates an [RpcProcessDetectionPort] over [_client].
  RpcProcessDetectionPort(this._client);

  final RemoteRpcClient _client;

  @override
  Future<List<ActiveProcessInfo>> detect() async {
    try {
      final data = await _client.call('process.detect', const {});
      return ((data['processes'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .map(
            (w) => ActiveProcessInfo(
              agentName: w['agent_name'] as String? ?? '',
              workspaceName: w['workspace_name'] as String? ?? '',
              pid: (w['pid'] as num?)?.toInt() ?? 0,
              command: w['command'] as String? ?? '',
              startTime: _parseTime(w['start_time']),
            ),
          )
          .toList();
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<void> killProcess(int pid) async {
    await _client.call('process.kill', {'pid': pid});
  }

  static DateTime _parseTime(Object? iso) {
    if (iso is String && iso.isNotEmpty) {
      return DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
