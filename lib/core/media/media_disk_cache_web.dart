import 'dart:typed_data';

/// The web build's [MediaDiskCache]: deliberately inert.
///
/// The browser already caches signed `/proxy/media` URLs (`Cache-Control:
/// max-age=86400`, stable for `(source, width)`). A second IndexedDB cache
/// would only hide stale bytes.
class MediaDiskCache {
  /// Creates the inert web cache. Parameters are accepted and ignored so the
  /// two platform variants share one constructor shape.
  MediaDiskCache({
    Object? root,
    this.maxBytes = 0,
    this.maxEntryBytes = 0,
    this.ttl = Duration.zero,
    Object? httpClientFactory,
  });

  /// Always 0 — nothing is stored here.
  final int maxBytes;

  /// Always 0 — nothing is stored here.
  final int maxEntryBytes;

  /// Always zero — nothing is stored here.
  final Duration ttl;

  /// Always null: the caller falls back to loading the URL directly, which on
  /// web means the browser's own cache serves it.
  Future<Uint8List?> get(String url, {String? cacheKey}) async => null;

  /// Always null — see [get]. The browser's HTTP cache is the web's disk cache.
  Future<Uint8List?> peek(String url, {String? cacheKey}) async => null;

  /// No-op.
  Future<void> put(String url, Uint8List bytes, {String? cacheKey}) async {}

  /// No-op.
  Future<void> sweep() async {}

  /// No-op.
  Future<void> clear() async {}
}
