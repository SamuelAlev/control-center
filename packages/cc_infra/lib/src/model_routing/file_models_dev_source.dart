import 'dart:io';
import 'dart:isolate';

import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';
import 'package:cc_domain/features/model_routing/domain/ports/models_dev_source.dart';
import 'package:cc_domain/features/model_routing/domain/services/models_dev_parser.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:rhttp/rhttp.dart';

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
///
/// The document is several megabytes of JSON. It is always parsed on a
/// throwaway isolate: on the caller's it held the server's event loop for
/// about a tenth of a second per read, at boot and again on every refresh.
/// And it is parsed as it is read (`ModelsDevParser`), never
/// decoded whole first: the decoded document was 67 MB the server went on
/// holding for a catalog a tenth of that size.
class FileModelsDevSource implements ModelsDevSource {
  /// Creates a [FileModelsDevSource].
  ///
  /// [allowNetwork] gates fetching entirely, for tests, the demo, and
  /// restricted environments.
  FileModelsDevSource({
    required this.cacheFilePath,
    RhttpClient? httpClient,
    this.url = kModelsDevApiUrl,
    this.ttl = const Duration(hours: 6),
    this.allowNetwork = true,
  }) : _httpClientOverride = httpClient;

  /// Path of the on-disk catalogue cache (`<dataDir>/models_dev/api.json`).
  final String cacheFilePath;

  /// The catalogue endpoint.
  final String url;

  /// Freshness window for the disk cache. The background refresh matches it.
  /// Prices and context windows change a few times a month, and model lists
  /// come live from the providers, so a few hours of staleness costs nothing.
  final Duration ttl;

  /// Whether network fetches are permitted.
  final bool allowNetwork;

  /// Identifies this app to the catalogue host, mirroring the font fetcher.
  static const _userAgent =
      'ControlCenter/1.0 (+https://github.com/SamuelAlev/control-center)';

  final RhttpClient? _httpClientOverride;

  /// The [RhttpClient] used for [refresh], created on first use so that a
  /// cache-only source (boot, [allowNetwork] false) never touches the
  /// transport. A plain client (no app interceptor chain), bounded like the
  /// per-request timeouts it replaces (15s to connect, 30s overall).
  late final RhttpClient _httpClient =
      _httpClientOverride ??
      RhttpClient.createSync(
        settings: httpClientSettings(
          settings: const ClientSettings(
            timeoutSettings: TimeoutSettings(
              connectTimeout: Duration(seconds: 15),
              timeout: Duration(seconds: 30),
            ),
          ),
        ),
      );

  /// The cache file's state when its document was last handed out, so a
  /// refresh that finds the same fresh file does not decode it again.
  ({DateTime modified, int length})? _served;

  @override
  Future<Map<String, ProviderEntry>?> load() => _readCache(requireFresh: false);

  @override
  Future<String?> documentText() async {
    try {
      final file = File(cacheFilePath);
      return file.existsSync() ? await file.readAsString() : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<Map<String, ProviderEntry>?> refresh({bool force = false}) async {
    if (!force) {
      final file = File(cacheFilePath);
      if (_isFresh(file)) {
        if (_stampOf(file) == _served) {
          // The caller already has this document. Boot loads the cache and
          // then asks for a refresh: handing the same file out twice decoded
          // it twice within a second.
          return null;
        }
        final fresh = await _readCache(requireFresh: true);
        if (fresh != null) {
          return fresh;
        }
      }
    }
    final fetched = await _fetch();
    if (fetched != null) {
      return fetched;
    }
    // Offline: the stale cache is all there is, and the caller may have it.
    final served = _served;
    if (served != null && _stampOf(File(cacheFilePath)) == served) {
      return null;
    }
    return _readCache(requireFresh: false);
  }

  bool _isFresh(File file) {
    try {
      return file.existsSync() &&
          DateTime.now().difference(file.lastModifiedSync()) <= ttl;
    } on FileSystemException {
      return false;
    }
  }

  ({DateTime modified, int length})? _stampOf(File file) {
    try {
      final stat = file.statSync();
      return stat.type == FileSystemEntityType.notFound
          ? null
          : (modified: stat.modified, length: stat.size);
    } on FileSystemException {
      return null;
    }
  }

  Future<Map<String, ProviderEntry>?> _readCache({
    required bool requireFresh,
  }) async {
    try {
      final file = File(cacheFilePath);
      if (!file.existsSync()) {
        return null;
      }
      if (requireFresh && !_isFresh(file)) {
        return null;
      }
      final stamp = _stampOf(file);
      final path = cacheFilePath;
      final providers = await Isolate.run(
        () => ModelsDevParser.parseUtf8(File(path).readAsBytesSync()),
        debugName: 'models-dev-parse',
      );
      if (providers.isEmpty) {
        return null;
      }
      _served = stamp;
      return providers;
    } on Object {
      return null;
    }
  }

  Future<Map<String, ProviderEntry>?> _fetch() async {
    if (!allowNetwork) {
      return null;
    }
    try {
      final response = await _httpClient.getText(
        url,
        headers: const HttpHeaders.rawMap({'User-Agent': _userAgent}),
      );
      final body = response.body;
      if (body.isEmpty) {
        return null;
      }
      final providers = await Isolate.run(
        () => ModelsDevParser.parse(body),
        debugName: 'models-dev-parse',
      );
      if (providers.isEmpty) {
        return null;
      }
      await _writeCache(body);
      return providers;
    } on Object {
      return null;
    }
  }

  /// Stores [body], the response exactly as received: encoding the decoded
  /// document again would only reproduce it.
  Future<void> _writeCache(String body) async {
    try {
      final file = File(cacheFilePath);
      await file.parent.create(recursive: true);
      await file.writeAsString(body);
      _served = _stampOf(file);
    } on Object {
      // A read-only cache dir is non-fatal; the fetched document still serves.
    }
  }
}
