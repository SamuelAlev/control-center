import 'dart:convert';

import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';
import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:cc_domain/features/model_routing/domain/services/models_dev_parser.dart';

/// A [ModelsDevSource] that serves a caller-supplied in-memory document.
///
/// Pure (no `dart:io`), so it is safe on web and in tests. Production reads
/// go through `FileModelsDevSource` (VM only, cache under the server data dir)
/// or `RpcModelsDevSource` on a thin client. There is no bundled snapshot —
/// tests pass a fixture.
class InMemoryModelsDevSource implements ModelsDevSource {
  /// Creates an [InMemoryModelsDevSource] over a caller-supplied document.
  InMemoryModelsDevSource(Map<String, dynamic> document)
    : _text = jsonEncode(document);

  /// The document as models.dev serves it: its JSON text.
  final String _text;

  @override
  Future<Map<String, ProviderEntry>?> load() async =>
      ModelsDevParser.parse(_text);

  @override
  Future<Map<String, ProviderEntry>?> refresh({bool force = false}) async =>
      ModelsDevParser.parse(_text);

  @override
  Future<String?> documentText() async => _text;
}
