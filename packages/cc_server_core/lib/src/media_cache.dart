import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/services/cache_stats.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

// Async dart:io is DELIBERATE here: this runs on the cc_server RPC isolate,
// where the sync variants this lint prefers would block every in-flight RPC
// behind a disk read/write of up to 16MB.
// ignore_for_file: avoid_slow_async_io

/// Outcome of one upstream fetch driven by [MediaCache.resolve]'s fetcher.
/// The cache never touches the network itself — the caller (the media proxy)
/// owns HTTP; the cache owns storage, freshness, revalidation and
/// single-flight dedup.
sealed class MediaFetchOutcome {
  /// Base of the fetch-outcome union.
  const MediaFetchOutcome();
}

/// The upstream body was buffered and is safe to persist (subject to the
/// entry-size cap). [bytes] are the FINAL bytes to serve — post any
/// transcode/downscale the caller applies — keyed by `(url, w)`.
final class MediaFetchBuffered extends MediaFetchOutcome {
  /// Creates a buffered outcome.
  const MediaFetchBuffered({
    required this.bytes,
    required this.contentType,
    this.etag,
    this.lastModified,
    this.maxAgeSeconds,
    this.cache = true,
  });

  /// The final response body.
  final List<int> bytes;

  /// MIME type to serve the body as (post-transform).
  final String contentType;

  /// Upstream `ETag`, stored for later conditional revalidation.
  final String? etag;

  /// Upstream `Last-Modified`, stored for later conditional revalidation.
  final String? lastModified;

  /// Upstream `Cache-Control: max-age`. Null/absent falls back to the cache's
  /// default TTL; every value is clamped to `[minTtl, maxTtl]`.
  final int? maxAgeSeconds;

  /// False when the upstream forbade storing (`no-store`/`private`): the body
  /// is served but never written to disk.
  final bool cache;
}

/// The body must be relayed WITHOUT caching: a non-image payload or an
/// oversized one the caller chose to stream zero-copy. Ownership of both the
/// response and its client transfers to the awaiter that INITIATED the fetch
/// (see [MediaCache.resolve] — waiters re-fetch instead).
final class MediaFetchStream extends MediaFetchOutcome {
  /// Creates a stream outcome transferring [response] + [client] ownership.
  const MediaFetchStream(this.response, this.client);

  /// The open upstream response, unread.
  final HttpClientResponse response;

  /// The client that produced [response]; the relayer closes it when done.
  final HttpClient client;
}

/// Upstream answered `304 Not Modified` to a conditional request — the stored
/// entry is still valid; only its expiry moves forward.
final class MediaFetchNotModified extends MediaFetchOutcome {
  /// Creates the not-modified outcome.
  const MediaFetchNotModified();
}

/// The fetch failed (connect error, timeout, upstream `>= 400`, blocked
/// redirect, oversize). A stale entry, when one exists, is served instead.
final class MediaFetchFailed extends MediaFetchOutcome {
  /// Creates the failure outcome.
  const MediaFetchFailed();
}

/// What [MediaCache.resolve] settled on for one request.
sealed class MediaCacheResolution {
  /// Base of the resolution union.
  const MediaCacheResolution();
}

/// Serve [bodyFile] as [contentType] — a fresh hit, a revalidated entry, or
/// stale-if-error after a failed refresh.
final class MediaCacheHit extends MediaCacheResolution {
  /// Creates a hit over an on-disk body.
  const MediaCacheHit({required this.bodyFile, required this.contentType});

  /// The on-disk body. Read it promptly; the LRU sweep may evict it later.
  final File bodyFile;

  /// The stored MIME type.
  final String contentType;
}

/// Serve [bytes] directly — the upstream body was fetched but not stored
/// (over the entry cap, or `no-store`).
final class MediaCacheUncached extends MediaCacheResolution {
  /// Creates a serve-from-memory resolution.
  const MediaCacheUncached({required this.bytes, required this.contentType});

  /// The fetched body.
  final List<int> bytes;

  /// The MIME type to serve.
  final String contentType;
}

/// Relay [outcome] zero-copy; nothing was (or should be) cached.
final class MediaCachePassthrough extends MediaCacheResolution {
  /// Creates a relay resolution.
  const MediaCachePassthrough(this.outcome);

  /// The open stream, owned by the caller now.
  final MediaFetchStream outcome;
}

/// Nothing to serve: the fetch failed and no stale entry exists.
final class MediaCacheFailure extends MediaCacheResolution {
  /// Creates the failure resolution.
  const MediaCacheFailure();
}

/// A persistent, bounded disk cache for the `/proxy/media` upstream fetch.
///
/// Before this, EVERY proxied image — avatars, favicons, PR-body media — cost
/// a full upstream round trip per process lifetime: the desktop's Flutter
/// `ImageCache` is memory-only and the web tier's browser cache is per-size,
/// so "this avatar was on the previous page" still hit GitHub again. With the
/// cache, a repeat is a loopback disk read.
///
/// Layout under `dir`: `<sha>.body` + `<sha>.json` (metadata sidecar:
/// content-type, validators, expiry). The key hashes `(url, w)` so each
/// downscale variant caches independently, mirroring GitHub's per-`s`
/// avatars. Freshness honors upstream `max-age` clamped to `[minTtl, maxTtl]`
/// (a floor so a `max-age=300` avatar host doesn't churn, a cap so a missing
/// header can't pin a stale image forever). Expired entries with validators
/// are revalidated with a conditional GET (`304` → serve stored, bump
/// expiry); a failed refresh serves stale rather than erroring — avatars are
/// the classic better-stale-than-broken content.
///
/// Hygiene is a two-pass sweep: a TTL-grace pass deletes entries expired
/// longer than [MediaCache.new]'s `maxStaleAge` (plus any orphan body/meta
/// file), then an LRU pass enforces the total-size cap. The sweep runs after
/// every write AND on a periodic timer ([startPeriodicSweep]) — write-only
/// scheduling would leave a quiet server's dead entries on disk forever.
///
/// Concurrent requests for the same key single-flight: one upstream fetch,
/// every waiter serves the stored result. (A waiter whose shared fetch came
/// back [MediaFetchStream] re-fetches for itself — a stream has exactly one
/// consumer.)
class MediaCache {
  /// Creates a [MediaCache] rooted at [dir] (created lazily on first write).
  ///
  /// [maxStaleAge] is how long an EXPIRED entry is retained for
  /// stale-if-error serving and conditional revalidation before the sweep
  /// deletes it outright — the revalidation value of a week-old expired
  /// avatar no longer justifies the disk.
  MediaCache({
    required Directory dir,
    int maxTotalBytes = 256 << 20,
    int maxEntryBytes = 16 << 20,
    Duration defaultTtl = const Duration(hours: 24),
    Duration minTtl = const Duration(hours: 1),
    Duration maxTtl = const Duration(days: 7),
    Duration maxStaleAge = const Duration(days: 7),
    DateTime Function()? clock,
  }) : _dir = dir,
       _maxTotalBytes = maxTotalBytes,
       _maxEntryBytes = maxEntryBytes,
       _defaultTtl = defaultTtl,
       _minTtl = minTtl,
       _maxTtl = maxTtl,
       _maxStaleAge = maxStaleAge,
       _clock = clock ?? DateTime.now;

  final Directory _dir;
  final int _maxTotalBytes;
  final int _maxEntryBytes;
  final Duration _defaultTtl;
  final Duration _minTtl;
  final Duration _maxTtl;
  final Duration _maxStaleAge;
  final DateTime Function() _clock;

  /// In-flight upstream fetches, for single-flight dedup.
  final Map<String, Future<MediaFetchOutcome>> _inflight = {};
  bool _sweepScheduled = false;

  /// Hit/miss/eviction counters, surfaced through `/healthz`. The media cache
  /// is the one whose TTL clamps and 256 MB cap were chosen without a hit rate
  /// to check them against.
  final CacheStats _stats = CacheStatsRegistry.instance.of('media');

  /// Approximate total bytes on disk, or -1 until the first sweep measures it.
  ///
  /// A sweep lists the whole directory, reads and decodes every meta sidecar
  /// and stats every body. Running one after EVERY write meant a burst of
  /// newly-cached images produced back-to-back O(entries) walks over a
  /// directory that holds thousands at the size cap. Tracking the total in
  /// memory means a write only pays for a walk when it might actually have
  /// pushed the cache over its cap; the 12h timer still runs unconditionally
  /// so TTL/orphan hygiene never depends on write traffic.
  int _approxTotalBytes = -1;

  /// key → when its mtime was last bumped, so LRU recency costs one syscall
  /// per key per [_touchThrottle] instead of one per HIT. 50 avatars on a
  /// screen were 50 disk writes for information the LRU only needs
  /// approximately. Pruned during the sweep.
  final Map<String, DateTime> _lastTouched = {};

  /// Minimum gap between mtime bumps for one key.
  static const Duration _touchThrottle = Duration(minutes: 1);

  /// Records a freshly written entry and sweeps only if the cap may be blown.
  void _noteWritten(int bytes) {
    if (_approxTotalBytes < 0) {
      // Size on disk is unknown (nothing has swept yet) — measure once.
      _scheduleSweep();
      return;
    }
    _approxTotalBytes += bytes;
    if (_approxTotalBytes > _maxTotalBytes) {
      _scheduleSweep();
    }
  }

  Timer? _sweepTimer;

  /// The cache key for one `(rawUrl, maxWidth)` pair — the two dimensions
  /// that change the served bytes. The signature/device never enter the key:
  /// the cache sits BEHIND signature verification, so only already-authorised
  /// fetches are ever stored or served.
  static String keyFor(String rawUrl, int? maxWidth) =>
      sha256.convert(utf8.encode('w=${maxWidth ?? 0}\n$rawUrl')).toString();

  File _bodyFile(String key) => File(p.join(_dir.path, '$key.body'));
  File _metaFile(String key) => File(p.join(_dir.path, '$key.json'));

  /// Resolves [key] to bytes the caller can serve, fetching upstream via
  /// [fetch] only when the stored entry is missing or stale.
  ///
  /// [fetch] receives the stored validators (if any) so it can issue a
  /// conditional request and returns exactly one [MediaFetchOutcome].
  Future<MediaCacheResolution> resolve(
    String key,
    Future<MediaFetchOutcome> Function({String? etag, String? lastModified})
    fetch,
  ) async {
    // Two attempts cover the waiter-won-a-stream case (loop once to become
    // the initiator); anything still failing after that is a plain failure.
    for (var attempt = 0; attempt < 2; attempt++) {
      final meta = await _readMeta(key);
      if (meta != null &&
          meta.expiresAtMs > _clock().millisecondsSinceEpoch &&
          await _bodyFile(key).exists()) {
        _touch(key);
        // Counted only on the FIRST attempt: the retry loop exists for the
        // waiter-won-a-stream case, and counting a second pass as another
        // lookup would inflate both sides of the ratio.
        if (attempt == 0) {
          _stats.hit();
        }
        return MediaCacheHit(
          bodyFile: _bodyFile(key),
          contentType: meta.contentType,
        );
      }
      if (attempt == 0) {
        _stats.miss();
      }

      final initiated = !_inflight.containsKey(key);
      // NOTE: the whenComplete action must use a BLOCK body — an arrow
      // `() => _inflight.remove(key)` would RETURN the removed entry, i.e.
      // the very future whenComplete produces and whenComplete waits on its
      // action's returned future: a self-waiting deadlock.
      final future = _inflight.putIfAbsent(
        key,
        () => fetch(etag: meta?.etag, lastModified: meta?.lastModified)
            .whenComplete(() {
              _inflight.remove(key);
            }),
      );
      final MediaFetchOutcome outcome;
      try {
        outcome = await future;
      } catch (_) {
        // A fetcher should report failure via MediaFetchFailed; a throw must
        // not take the proxy down with it.
        return await _staleOrFailure(key, meta);
      }

      switch (outcome) {
        case MediaFetchBuffered(:final bytes, :final contentType, :final cache):
          if (!cache || bytes.length > _maxEntryBytes) {
            return MediaCacheUncached(bytes: bytes, contentType: contentType);
          }
          await _write(key, outcome);
          _noteWritten(bytes.length);
          return MediaCacheHit(
            bodyFile: _bodyFile(key),
            contentType: contentType,
          );
        case MediaFetchNotModified():
          if (meta != null && await _bodyFile(key).exists()) {
            await _bumpExpiry(key, meta);
            _touch(key);
            return MediaCacheHit(
              bodyFile: _bodyFile(key),
              contentType: meta.contentType,
            );
          }
          // A 304 for an entry whose body is gone is nonsense upstream can't
          // know about — drop the dangling meta and refetch unconditionally.
          await _deleteQuietly(_metaFile(key));
          continue;
        case MediaFetchStream():
          if (initiated) {
            return MediaCachePassthrough(outcome);
          }
          // The stream belongs to the initiating awaiter; loop to fetch again
          // as the initiator (the in-flight entry is gone by now).
          continue;
        case MediaFetchFailed():
          return _staleOrFailure(key, meta);
      }
    }
    return const MediaCacheFailure();
  }

  /// Serves the stale entry after a failed refresh, or reports failure when
  /// there is nothing on disk.
  Future<MediaCacheResolution> _staleOrFailure(
    String key,
    _MediaCacheMeta? meta,
  ) async {
    if (meta != null && await _bodyFile(key).exists()) {
      _touch(key);
      return MediaCacheHit(
        bodyFile: _bodyFile(key),
        contentType: meta.contentType,
      );
    }
    return const MediaCacheFailure();
  }

  Duration _clampedTtl(int? maxAgeSeconds) {
    if (maxAgeSeconds == null) {
      return _defaultTtl;
    }
    var ttl = Duration(seconds: maxAgeSeconds);
    if (ttl < _minTtl) {
      ttl = _minTtl;
    }
    if (ttl > _maxTtl) {
      ttl = _maxTtl;
    }
    return ttl;
  }

  Future<_MediaCacheMeta?> _readMeta(String key) async {
    try {
      final raw = await _metaFile(key).readAsString();
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return _MediaCacheMeta.fromJson(json);
    } on Exception {
      return null;
    }
  }

  Future<void> _write(String key, MediaFetchBuffered fetched) async {
    final ttl = _clampedTtl(fetched.maxAgeSeconds);
    final meta = _MediaCacheMeta(
      contentType: fetched.contentType,
      etag: fetched.etag,
      lastModified: fetched.lastModified,
      expiresAtMs: _clock().add(ttl).millisecondsSinceEpoch,
      ttlSeconds: ttl.inSeconds,
    );
    await _dir.create(recursive: true);
    // Body first, meta second: a crash between the two leaves a body-less
    // meta never (meta presence implies body), the inverse orphan just gets
    // swept by the LRU as any other entry.
    await _bodyFile(key).writeAsBytes(fetched.bytes, flush: false);
    await _metaFile(key).writeAsString(jsonEncode(meta.toJson()), flush: false);
  }

  /// Extends a revalidated entry by its stored TTL (upstream rarely repeats
  /// `max-age` on a `304`; the original lifetime is the best estimate).
  Future<void> _bumpExpiry(String key, _MediaCacheMeta meta) async {
    final ttl = Duration(
      seconds: meta.ttlSeconds > 0 ? meta.ttlSeconds : _defaultTtl.inSeconds,
    );
    await _metaFile(key)
        .writeAsString(
          jsonEncode(
            meta
                .copyWithExpiresAt(_clock().add(ttl).millisecondsSinceEpoch)
                .toJson(),
          ),
          flush: false,
        )
        .catchError((_) => _metaFile(key));
  }

  /// Updates the body file's mtime for LRU ordering (best-effort, throttled).
  void _touch(String key) {
    final now = _clock();
    final last = _lastTouched[key];
    if (last != null && now.difference(last) < _touchThrottle) {
      return;
    }
    _lastTouched[key] = now;
    unawaited(_bodyFile(key).setLastModified(now).catchError((_) {}));
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      await file.delete();
    } on Exception {
      // Already gone — fine.
    }
  }

  /// Starts a periodic sweep on [interval]. Hygiene independent of write
  /// traffic: expired-beyond-grace entries and orphans are reaped even when
  /// nothing new is being cached — a quiet server otherwise only sweeps on
  /// writes and only for the size cap. Idempotent; cancel with [close].
  void startPeriodicSweep({Duration interval = const Duration(hours: 12)}) {
    _sweepTimer ??= Timer.periodic(interval, (_) => _scheduleSweep());
  }

  /// Cancels the periodic sweep (an in-flight sweep finishes). The cache
  /// stays usable; only the timer stops.
  void close() {
    _sweepTimer?.cancel();
    _sweepTimer = null;
  }

  void _scheduleSweep() {
    if (_sweepScheduled) {
      return;
    }
    _sweepScheduled = true;
    unawaited(
      Future(() async {
        try {
          await _sweep();
        } on Exception {
          // A failed sweep just means the cap is enforced next time.
        } finally {
          _sweepScheduled = false;
        }
      }),
    );
  }

  /// Runs the LRU sweep NOW. Production callers get the scheduled,
  /// fire-and-forget sweep after each write; this is the test hook.
  Future<void> sweepForTest() => _sweep();

  /// Two passes over the directory: a TTL-grace pass deleting entries
  /// expired longer than [_maxStaleAge] (plus orphan bodies/metas — dead
  /// weight a resolve would overwrite or never find), then the LRU pass
  /// evicting least-recently-USED survivors (body mtime — refreshed on every
  /// hit) until the total is back under [_maxTotalBytes].
  Future<void> _sweep() async {
    if (!await _dir.exists()) {
      return;
    }
    final bodies = <String, File>{};
    final metas = <String, File>{};
    await for (final entity in _dir.list()) {
      if (entity is! File) {
        continue;
      }
      if (entity.path.endsWith('.body')) {
        bodies[p.basenameWithoutExtension(entity.path)] = entity;
      } else if (entity.path.endsWith('.json')) {
        metas[p.basenameWithoutExtension(entity.path)] = entity;
      }
    }

    // Pass 1 — TTL grace + orphans. An expired entry is still worth its disk
    // (stale-if-error, 304 revalidation) until the grace lapses; an orphan is
    // never worth it.
    final nowMs = _clock().millisecondsSinceEpoch;
    Future<void> drop(String key) async {
      await _deleteQuietly(bodies.remove(key) ?? _bodyFile(key));
      await _deleteQuietly(metas.remove(key) ?? _metaFile(key));
    }

    for (final key in metas.keys.toList()) {
      if (!bodies.containsKey(key)) {
        // Meta without a body can never hit — resolve refetches anyway.
        await drop(key);
        continue;
      }
      final meta = await _readMeta(key);
      // An UNREADABLE meta is skipped, never deleted: the meta file may be
      // mid-write by a concurrent `_write`/`_bumpExpiry` (writes are not
      // atomic) and resolve self-heals a genuinely corrupt one by refetching
      // and overwriting the pair.
      if (meta != null &&
          nowMs - meta.expiresAtMs > _maxStaleAge.inMilliseconds) {
        await drop(key);
      }
    }
    for (final key in bodies.keys.toList()) {
      if (!metas.containsKey(key)) {
        await drop(key);
      }
    }

    // Pass 2 — the size cap over the survivors, least-recently-used first.
    final stats = <File, FileStat>{};
    var total = 0;
    for (final body in bodies.values) {
      final stat = await body.stat();
      stats[body] = stat;
      total += stat.size;
    }
    // The walk just measured the truth; adopt it so writes can decide whether
    // the next sweep is needed without repeating it.
    _approxTotalBytes = total;
    _stats.size(entries: bodies.length, bytes: total);
    _lastTouched.removeWhere((key, _) => !bodies.containsKey(key));
    if (total <= _maxTotalBytes) {
      return;
    }
    final survivors = bodies.values.toList()
      ..sort((a, b) => stats[a]!.modified.compareTo(stats[b]!.modified));
    for (final body in survivors) {
      if (total <= _maxTotalBytes) {
        break;
      }
      total -= stats[body]!.size;
      await drop(p.basenameWithoutExtension(body.path));
      _stats.evicted();
    }
    _approxTotalBytes = total;
    _stats.size(entries: -1, bytes: total);
  }
}

/// The JSON sidecar for one cached body.
final class _MediaCacheMeta {
  const _MediaCacheMeta({
    required this.contentType,
    required this.expiresAtMs,
    required this.ttlSeconds,
    this.etag,
    this.lastModified,
  });

  factory _MediaCacheMeta.fromJson(Map<String, dynamic> json) =>
      _MediaCacheMeta(
        contentType: json['contentType'] as String? ?? '',
        expiresAtMs: json['expiresAt'] as int? ?? 0,
        ttlSeconds: json['ttlSeconds'] as int? ?? 0,
        etag: json['etag'] as String?,
        lastModified: json['lastModified'] as String?,
      );

  final String contentType;
  final int expiresAtMs;
  final int ttlSeconds;
  final String? etag;
  final String? lastModified;

  _MediaCacheMeta copyWithExpiresAt(int expiresAtMs) => _MediaCacheMeta(
    contentType: contentType,
    expiresAtMs: expiresAtMs,
    ttlSeconds: ttlSeconds,
    etag: etag,
    lastModified: lastModified,
  );

  Map<String, dynamic> toJson() => {
    'contentType': contentType,
    'expiresAt': expiresAtMs,
    'ttlSeconds': ttlSeconds,
    if (etag != null) 'etag': etag,
    if (lastModified != null) 'lastModified': lastModified,
  };
}
