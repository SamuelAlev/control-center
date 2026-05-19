import 'dart:typed_data';

/// The web build's [MediaDiskCache]: deliberately inert.
///
/// **The browser's HTTP cache already is this cache, and it is a better one.**
/// Every remote image goes through a signed `/proxy/media` URL that is stable
/// for a given `(source, width)` — the signature is an HMAC over the source, so
/// it carries no nonce and no timestamp — and the server answers with
/// `Cache-Control: max-age=86400`. That is precisely the contract a browser
/// cache needs, and it comes with eviction, a byte budget, quota handling and
/// corruption recovery that nobody in this repo has to write or test.
///
/// A second cache in IndexedDB would duplicate all of that, add a place for a
/// stale image to survive a hard refresh, and cost an async hop before every
/// avatar. So the web tier keeps ONE cache and the code that guarantees it is
/// usable lives on the server side: `_setBufferedMediaHeaders` in
/// `local_rpc_server.dart` and the memoized signer in `MediaProxyConfig.resolve`
/// are what make the browser able to reuse a response, and both are pinned by
/// tests.
///
/// Kept as a real (no-op) class rather than a conditional import at every call
/// site so callers do not branch on the platform.
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
  Future<Uint8List?> get(String url) async => null;

  /// No-op.
  Future<void> sweep() async {}

  /// No-op.
  Future<void> clear() async {}
}
