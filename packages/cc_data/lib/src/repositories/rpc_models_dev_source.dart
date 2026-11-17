import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';
import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:cc_domain/features/model_routing/domain/services/models_dev_parser.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [ModelsDevSource] over the host's `models.catalog` /
/// `models.refreshCatalog` ops.
///
/// The host owns the models.dev fetch and the on-disk cache under its data
/// dir. Thin clients never dial models.dev and never ship a bundled snapshot —
/// they read the same document the server already cached.
///
/// It arrives as `document_json`, the document's text in one string, and is
/// parsed provider by provider. As a decoded map in the response it was tens
/// of megabytes of maps this client read once and then went on paying for.
class RpcModelsDevSource implements ModelsDevSource {
  /// Creates an [RpcModelsDevSource] over [_client].
  RpcModelsDevSource(this._client);

  final RemoteRpcClient _client;

  @override
  Future<Map<String, ProviderEntry>?> load() async =>
      _providers(await documentText());

  @override
  Future<String?> documentText() async =>
      _text(await _client.call('models.catalog', const {}));

  @override
  Future<Map<String, ProviderEntry>?> refresh({bool force = false}) async {
    final data = await _client.call('models.refreshCatalog', {
      'force': force,
    }, timeout: const Duration(minutes: 1));
    return _providers(_text(data));
  }

  String? _text(Map<String, dynamic> data) {
    final text = data['document_json'];
    return text is String && text.isNotEmpty ? text : null;
  }

  /// Null for a missing, empty or unreadable document: the catalog keeps what
  /// it has, as it does when the host has nothing cached yet.
  Map<String, ProviderEntry>? _providers(String? text) {
    if (text == null) {
      return null;
    }
    try {
      final providers = ModelsDevParser.parse(text);
      return providers.isEmpty ? null : providers;
    } on FormatException {
      return null;
    }
  }
}
