import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/services/cache_stats.dart';
import 'package:crypto/crypto.dart';

/// A bytes-on-disk cache for media the client fetches over the media proxy.
///
/// ## Why this exists on desktop and NOT on web
///
/// Every remote image the app shows is rewritten to a signed `/proxy/media`
/// URL, and the server answers those with `Cache-Control: max-age=86400` over a
/// URL that is stable for a given `(source, width)`. On **web** that is already
/// a disk cache — the browser's — with eviction, a byte budget and corruption
/// handling that nobody here has to write, so the web build deliberately gets
/// an inert stub instead of a second cache in IndexedDB that would only add a
/// place for a stale image to hide.
///
/// **Desktop has no such cache.** `NetworkImage` on `dart:io` goes through a
/// bare `HttpClient` with no HTTP cache at all, and Flutter's `ImageCache` is
/// memory-only and dies with the process. A desktop paired to a REMOTE server
/// therefore re-downloaded its entire working set — every avatar, favicon and
/// feed image — on every launch. (A desktop on loopback is covered by the
/// server's own `MediaCache`; this closes the remote case.)
///
/// ## Shape
///
/// Deliberately the smallest thing that works: content addressed by a hash of
/// the resolved URL, a body file plus a tiny sidecar, and an LRU sweep by total
/// bytes. It is NOT an HTTP cache — no revalidation, no `ETag`, no `Vary`.
/// That is sound only because of the URL property above: the signed URL embeds
/// the source and the width, so *different bytes mean a different URL*. An
/// entry can go stale only if the upstream replaces an image in place under a
/// URL it already served, which the [ttl] bounds.
///
/// Reports to [CacheStatsRegistry] under `media_disk`, because a cache that
/// reports nothing is a capacity number nobody ever checked.
class MediaDiskCache {
  /// Creates a cache rooted at [root].
  MediaDiskCache({
    required this.root,
    this.maxBytes = 256 * 1024 * 1024,
    this.maxEntryBytes = 16 * 1024 * 1024,
    this.ttl = const Duration(days: 30),
    HttpClient Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory ?? HttpClient.new;

  /// Directory holding the cached bodies.
  final Directory root;
  final HttpClient Function() _httpClientFactory;

  /// Total byte ceiling before the LRU sweep drops the oldest entries.
  final int maxBytes;

  /// Bodies larger than this are served but never written — one video-sized
  /// response must not evict the entire avatar working set.
  final int maxEntryBytes;

  /// How long an entry is served before it is re-fetched.
  final Duration ttl;

  final CacheStats _stats = CacheStatsRegistry.instance.of('media_disk');

  /// Single-flight: two widgets mounting the same avatar in one frame is the
  /// normal case, and without this they issue two GETs and race to write the
  /// same file.
  final Map<String, Future<Uint8List?>> _inFlight = {};

  /// Running total, adopted from each sweep and incremented per write, so a
  /// write only triggers a walk when it might have blown the cap.
  int _approxBytes = -1;

  /// Tail of the sweep queue — see [sweep].
  Future<void> _sweepChain = Future<void>.value();

  /// Hard memory bound on a single response body, whatever [maxEntryBytes] is.
  /// These bytes are headed for an image decode; past this nothing useful can
  /// be done with them, so the fetch gives up rather than growing the heap.
  static const int _hardBodyCeiling = 64 * 1024 * 1024;

  /// Returns the bytes for [url], from disk when possible.
  ///
  /// Returns null when the fetch fails — callers fall back to loading the URL
  /// directly, because a cache miss must never be the reason an image does not
  /// render.
  Future<Uint8List?> get(String url) {
    final key = _keyFor(url);
    final existing = _inFlight[key];
    if (existing != null) {
      return existing;
    }
    // The body must be a BLOCK, not an arrow. `Map.remove` returns the value
    // it removed — which here is this very future — and `whenComplete` awaits
    // a returned Future, so the arrow form made every read wait on itself.
    // Every call hung forever, and the fallback in the image provider meant
    // the symptom would have been "images never load", not an error.
    final future = _load(url, key).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  Future<Uint8List?> _load(String url, String key) async {
    final body = _bodyFile(key);
    try {
      if (body.existsSync()) {
        final age = DateTime.now().difference(body.lastModifiedSync());
        if (age <= ttl) {
          final bytes = await body.readAsBytes();
          _stats.hit();
          // Touch is deliberately NOT done per hit: an mtime write per avatar
          // per frame is write amplification for an LRU whose resolution is
          // days. The sweep drops by age, and a re-fetch after the TTL
          // rewrites the file anyway.
          return bytes;
        }
      }
    } on FileSystemException {
      // A half-written or unreadable entry is a miss, not an error.
    }
    _stats.miss();
    return _fetchAndStore(url, key);
  }

  Future<Uint8List?> _fetchAndStore(String url, String key) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }
    final client = _httpClientFactory();
    try {
      final res = await client.getUrl(uri).then((r) => r.close());
      if (res.statusCode != HttpStatus.ok) {
        return null;
      }
      // ONE pass over the response. An earlier version broke out into a second
      // `await for` over the same stream to drain an oversized body, which
      // throws (a response stream is single-subscription) — the throw landed
      // in the catch-all below and every large image silently failed to load.
      final builder = BytesBuilder(copy: false);
      // Past the per-entry cap the body is still served but never stored: one
      // video-sized response must not evict the whole avatar working set.
      var tooBigToStore = false;
      await for (final chunk in res) {
        builder.add(chunk);
        if (builder.length > maxEntryBytes) {
          tooBigToStore = true;
          // Absolute ceiling, deliberately NOT a multiple of [maxEntryBytes]:
          // the store cap is a policy about what is worth keeping, this is a
          // memory bound on what can be held at all. Tying them together made
          // a small store cap silently refuse to SERVE ordinary images.
          if (builder.length > _hardBodyCeiling) {
            return null;
          }
        }
      }
      if (tooBigToStore) {
        return builder.takeBytes();
      }
      final bytes = builder.takeBytes();
      // Awaited, not fire-and-forget: the caller has already waited for the
      // network, so a flush that takes a fraction of that makes "fetched
      // implies stored" TRUE. Left unawaited, two reads a few milliseconds
      // apart both missed and both re-downloaded, which is most of what the
      // cache exists to prevent.
      await _write(key, bytes);
      return bytes;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _write(String key, Uint8List bytes) async {
    try {
      final body = _bodyFile(key);
      await body.parent.create(recursive: true);
      // Write-then-rename, so a crash or a concurrent reader never sees a
      // half-written body and decodes garbage.
      final tmp = File('${body.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(body.path);
      if (_approxBytes >= 0) {
        _approxBytes += bytes.length;
        _stats.size(bytes: _approxBytes);
      }
      if (_approxBytes < 0 || _approxBytes > maxBytes) {
        unawaited(sweep());
      }
    } on FileSystemException {
      // A cache that cannot write is a cache that misses, not a broken app.
    }
  }

  /// Drops expired entries, then the oldest entries until the total is back
  /// under [maxBytes].
  ///
  /// Serialized rather than skipped-if-busy: a caller that awaits this wants
  /// the state AFTER its own writes, and returning early from a sweep that
  /// started before them would answer about a tree that no longer exists.
  Future<void> sweep() {
    final next = _sweepChain.then((_) => _sweep());
    _sweepChain = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _sweep() async {
    try {
      if (!root.existsSync()) {
        _approxBytes = 0;
        return;
      }
      final now = DateTime.now();
      final entries = <({File file, DateTime modified, int length})>[];
      var total = 0;
      var evicted = 0;
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || entity.path.endsWith('.tmp')) {
          continue;
        }
        final FileStat stat;
        try {
          stat = entity.statSync();
        } on FileSystemException {
          continue;
        }
        if (now.difference(stat.modified) > ttl) {
          try {
            entity.deleteSync();
            evicted++;
          } on FileSystemException {
            // Raced with another sweep or an external delete.
          }
          continue;
        }
        entries.add((file: entity, modified: stat.modified, length: stat.size));
        total += stat.size;
      }
      if (total > maxBytes) {
        entries.sort((a, b) => a.modified.compareTo(b.modified));
        for (final entry in entries) {
          if (total <= maxBytes) {
            break;
          }
          try {
            entry.file.deleteSync();
            total -= entry.length;
            evicted++;
          } on FileSystemException {
            // Skip and keep going; the next sweep retries.
          }
        }
      }
      _approxBytes = total;
      if (evicted > 0) {
        _stats.evicted(evicted);
      }
      _stats.size(entries: entries.length, bytes: total);
    } on FileSystemException {
      // The tree was moved or removed under us; the next sweep re-measures.
    }
  }

  /// Deletes every entry (used by "clear cache" and by tests).
  Future<void> clear() async {
    _inFlight.clear();
    _approxBytes = 0;
    if (root.existsSync()) {
      try {
        await root.delete(recursive: true);
      } on FileSystemException {
        // Best effort.
      }
    }
  }

  File _bodyFile(String key) =>
      File('${root.path}${Platform.pathSeparator}'
          '${key.substring(0, 2)}${Platform.pathSeparator}$key');

  /// Content address of [url]. sha256 rather than `hashCode` because a
  /// collision here serves one image's bytes under another's URL.
  static String _keyFor(String url) =>
      sha256.convert(utf8.encode(url)).toString();
}
