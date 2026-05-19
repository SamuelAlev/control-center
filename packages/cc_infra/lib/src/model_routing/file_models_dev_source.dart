import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_infra/src/model_routing/models_dev_snapshot.dart';
import 'package:dio/dio.dart';

/// The canonical models.dev catalog endpoint.
const String kModelsDevUrl = 'https://models.dev/api.json';

/// A [ModelsDevSource] backed by a disk cache, the bundled snapshot and the
/// network, in that resolution order.
///
/// [load] returns the freshest catalog it can without blocking on the network
/// when the cache is warm (TTL [ttl]); [refresh] forces a network fetch (past
/// the TTL when `force`). The bundled snapshot guarantees an offline fallback.
class FileModelsDevSource implements ModelsDevSource {
  /// Creates a [FileModelsDevSource].
  ///
  /// [cacheFilePath] is where the fetched JSON is persisted (the host picks a
  /// writable app-data path). [allowNetwork] gates the fetch entirely (off for
  /// tests / restricted environments).
  FileModelsDevSource({
    required this.cacheFilePath,
    Dio? dio,
    this.url = kModelsDevUrl,
    this.ttl = const Duration(minutes: 5),
    this.allowNetwork = true,
  }) : _dio = dio ?? Dio();

  /// Path of the on-disk cache file.
  final String cacheFilePath;

  /// The catalog endpoint.
  final String url;

  /// Freshness window for the disk cache.
  final Duration ttl;

  /// Whether network fetches are permitted.
  final bool allowNetwork;

  final Dio _dio;

  Map<String, dynamic>? _bundled;

  /// The bundled snapshot, decoded lazily once.
  Map<String, dynamic> get bundledSnapshot => _bundled ??=
      jsonDecode(bundledModelsDevSnapshotJson) as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>?> load() async {
    final cached = await _readFreshCache();
    if (cached != null) {
      return cached;
    }
    // Cache is stale/absent: try the network, but never return null — fall
    // back to a stale cache, then to the bundled snapshot.
    final fetched = await _fetch();
    if (fetched != null) {
      return fetched;
    }
    final stale = await _readRawCache();
    return stale ?? bundledSnapshot;
  }

  @override
  Future<Map<String, dynamic>?> refresh({bool force = false}) async {
    if (!force) {
      final cached = await _readFreshCache();
      if (cached != null) {
        return cached;
      }
    }
    final fetched = await _fetch();
    if (fetched != null) {
      return fetched;
    }
    final stale = await _readRawCache();
    return stale ?? bundledSnapshot;
  }

  Future<Map<String, dynamic>?> _readFreshCache() async {
    final file = File(cacheFilePath);
    if (!file.existsSync()) {
      return null;
    }
    final age = DateTime.now().difference(file.lastModifiedSync());
    if (age > ttl) {
      return null;
    }
    return _readRawCache();
  }

  Future<Map<String, dynamic>?> _readRawCache() async {
    final file = File(cacheFilePath);
    if (!file.existsSync()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
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
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final body = res.data;
      final decoded = body is String ? jsonDecode(body) : body;
      if (decoded is Map<String, dynamic> && decoded.isNotEmpty) {
        await _writeCache(decoded);
        return decoded;
      }
    } catch (_) {
      // Network / parse failure → caller falls back to cache/snapshot.
    }
    return null;
  }

  Future<void> _writeCache(Map<String, dynamic> json) async {
    try {
      final file = File(cacheFilePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(json));
    } catch (_) {
      // A read-only cache dir is non-fatal; we still serve the fetched data.
    }
  }
}
