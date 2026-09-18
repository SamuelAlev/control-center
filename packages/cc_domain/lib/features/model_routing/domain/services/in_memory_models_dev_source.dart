import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';

/// A [ModelsDevSource] that serves a caller-supplied in-memory document.
///
/// Pure (no `dart:io`), so it is safe on web and in tests. Production reads
/// go through the disk/network-backed source in `file_models_dev_source.dart`
/// (VM only, cache under the server data dir) or `RpcModelsDevSource` on a
/// thin client. There is no bundled snapshot — tests pass a fixture.
class InMemoryModelsDevSource implements ModelsDevSource {
  /// Creates an [InMemoryModelsDevSource] over [document].
  InMemoryModelsDevSource(this._document);

  final Map<String, dynamic> _document;

  @override
  Future<Map<String, dynamic>?> load() async => _document;

  @override
  Future<Map<String, dynamic>?> refresh({bool force = false}) async =>
      _document;
}
