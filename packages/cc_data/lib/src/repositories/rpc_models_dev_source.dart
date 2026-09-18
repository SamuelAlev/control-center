import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ModelsDevSource] over the host's `models.catalog` /
/// `models.refreshCatalog` ops.
///
/// The host owns the models.dev fetch and the on-disk cache under its data
/// dir. Thin clients never dial models.dev and never ship a bundled snapshot —
/// they read the same document the server already cached.
class RpcModelsDevSource implements ModelsDevSource {
  /// Creates an [RpcModelsDevSource] over [_client].
  RpcModelsDevSource(this._client);

  final RemoteRpcClient _client;

  @override
  Future<Map<String, dynamic>?> load() async {
    final data = await _client.call('models.catalog', const {});
    return _document(data);
  }

  @override
  Future<Map<String, dynamic>?> refresh({bool force = false}) async {
    final data = await _client.call(
      'models.refreshCatalog',
      {'force': force},
      timeout: const Duration(minutes: 1),
    );
    return _document(data);
  }

  Map<String, dynamic>? _document(Map<String, dynamic> data) {
    final raw = data['document'];
    if (raw is Map && raw.isNotEmpty) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
