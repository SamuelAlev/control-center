import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:dio/dio.dart';

/// The models.dev catalogue endpoint — key-less public JSON.
const String kModelsDevApiUrl = 'https://models.dev/api.json';

/// Disk- and network-backed [ModelsDevSource].
///
/// The live document is fetched from [url] and persisted at [cacheFilePath]
/// under the server data dir. There is deliberately no bundled snapshot in
/// source: a first run with no cache and no network yields null, and a later
/// fetch fills the cache. [load] never dials the network (boot and RPC reads
/// stay off the ready-banner path); [refresh] fetches when the cache is stale
/// or `force` is set, then falls back to a stale cache on failure.
class FileModelsDevSource implements ModelsDevSource {
  /// Creates a [FileModelsDevSource].
  ///
  /// [allowNetwork] gates fetching entirely, for tests, the demo, and
  /// restricted environments.
  FileModelsDevSource({
    required this.cacheFilePath,
    Dio? dio,
    this.url = kModelsDevApiUrl,
    this.ttl = const Duration(hours: 1),
    this.allowNetwork = true,
  }) : _dio = dio ?? Dio();

  /// Path of the on-disk catalogue cache (`<dataDir>/models_dev/api.json`).
  final String cacheFilePath;

  /// The catalogue endpoint.
  final String url;

  /// Freshness window for the disk cache. Hourly background refresh matches.
  final Duration ttl;

  /// Whether network fetches are permitted.
  final bool allowNetwork;

  /// Identifies this app to the catalogue host, mirroring the font fetcher.
  static const _userAgent =
      'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)';

  final Dio _dio;

  @override
  Future<Map<String, dynamic>?> load() => _readCache(requireFresh: false);

  @override
  Future<Map<String, dynamic>?> refresh({bool force = false}) async {
    if (!force) {
      final fresh = await _readCache(requireFresh: true);
      if (fresh != null) {
        return fresh;
      }
    }
    final fetched = await _fetch();
    if (fetched != null) {
      return fetched;
    }
    return _readCache(requireFresh: false);
  }

  Future<Map<String, dynamic>?> _readCache({required bool requireFresh}) async {
    try {
      final file = File(cacheFilePath);
      if (!file.existsSync()) {
        return null;
      }
      if (requireFresh &&
          DateTime.now().difference(file.lastModifiedSync()) > ttl) {
        return null;
      }
      final decoded = jsonDecode(await file.readAsString());
      return _asDocument(decoded);
    } on Object {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetch() async {
    if (!allowNetwork) {
      return null;
    }
    try {
      final res = await _dio.getUri<Object?>(
        Uri.parse(url),
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {'User-Agent': _userAgent},
        ),
      );
      final body = res.data;
      final decoded = body is String ? jsonDecode(body) : body;
      final document = _asDocument(decoded);
      if (document == null || document.isEmpty) {
        return null;
      }
      await _writeCache(document);
      return document;
    } on Object {
      return null;
    }
  }

  Future<void> _writeCache(Map<String, dynamic> document) async {
    try {
      final file = File(cacheFilePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(document));
    } on Object {
      // A read-only cache dir is non-fatal; the fetched document still serves.
    }
  }

  Map<String, dynamic>? _asDocument(Object? decoded) {
    if (decoded is! Map || decoded.isEmpty) {
      return null;
    }
    return {
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
  }
}
