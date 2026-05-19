import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_domain/features/settings/domain/repositories/adapter_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AdapterRepository] backed by the RPC client — the thin-client data path.
///
/// Detecting an adapter probes the CLI binaries installed on the SERVER's
/// machine (`which <cli>`, `<cli> --version`), so the thin client runs detection
/// over the host's `adapter.detectOne` / `adapter.detectAll` ops rather than its
/// own (absent) filesystem. The host returns only the detection RESULT (status /
/// version / path / capabilities) keyed by the adapter id; the client re-attaches
/// the [Adapter] it sent. A host that wires no detector leaves the ops absent
/// (default-deny → `opUnknown`); the client degrades each probe to
/// [DetectionStatus.notFound] rather than surfacing an error.
class RpcAdapterRepository implements AdapterRepository {
  /// Creates an [RpcAdapterRepository] over [_client].
  RpcAdapterRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Future<DetectedAdapter> detectOne(Adapter adapter) async {
    try {
      final data = await _client.call('adapter.detectOne', {
        'adapter': _adapterToWire(adapter),
      });
      return _detectedFromWire(adapter, data);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return DetectedAdapter(
          adapter: adapter,
          status: DetectionStatus.notFound,
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<DetectedAdapter>> detectAll(List<Adapter> adapters) async {
    try {
      final data = await _client.call('adapter.detectAll', {
        'adapters': adapters.map(_adapterToWire).toList(),
      });
      final byId = {for (final a in adapters) a.id: a};
      return ((data['detected'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .map((w) {
            final adapter = byId[w['adapter_id'] as String? ?? ''];
            return adapter == null ? null : _detectedFromWire(adapter, w);
          })
          .whereType<DetectedAdapter>()
          .toList();
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        return [
          for (final a in adapters)
            DetectedAdapter(adapter: a, status: DetectionStatus.notFound),
        ];
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _adapterToWire(Adapter a) => {
    'id': a.id,
    'name': a.name,
    'description': a.description,
    'cli_name': a.cliName,
  };

  static DetectedAdapter _detectedFromWire(
    Adapter adapter,
    Map<String, dynamic> w,
  ) {
    final statusName = w['status'] as String?;
    final status = DetectionStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => DetectionStatus.notFound,
    );
    final caps = w['capabilities'];
    return DetectedAdapter(
      adapter: adapter,
      status: status,
      version: w['version'] as String?,
      path: w['path'] as String?,
      capabilities: caps is Map
          ? AdapterCapabilities(
              supportsJsonMode: caps['supports_json_mode'] as bool? ?? false,
              supportsModelSelection:
                  caps['supports_model_selection'] as bool? ?? false,
            )
          : null,
    );
  }
}
