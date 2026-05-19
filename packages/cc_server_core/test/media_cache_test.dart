import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/src/media_cache.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('cc_media_cache_test');
  });
  tearDown(() {
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  /// A cache whose clock the test controls, rooted in [tmp].
  DateTime now = DateTime.utc(2026, 8, 11, 12);
  MediaCache cache({int maxTotalBytes = 256 << 20, int maxEntryBytes = 16 << 20}) =>
      MediaCache(
        dir: tmp,
        maxTotalBytes: maxTotalBytes,
        maxEntryBytes: maxEntryBytes,
        defaultTtl: const Duration(hours: 24),
        minTtl: const Duration(hours: 1),
        maxTtl: const Duration(days: 7),
        clock: () => now,
      );

  MediaFetchBuffered avatar({
    String body = 'png-bytes',
    String? etag,
    String? lastModified,
    int? maxAgeSeconds,
  }) => MediaFetchBuffered(
    bytes: body.codeUnits,
    contentType: 'image/png',
    etag: etag,
    lastModified: lastModified,
    maxAgeSeconds: maxAgeSeconds,
  );

  Future<List<int>> servedBody(MediaCacheResolution resolution) async {
    switch (resolution) {
      case MediaCacheHit(:final bodyFile):
        return bodyFile.readAsBytes();
      case MediaCacheUncached(:final bytes):
        return bytes;
      default:
        fail('expected a servable resolution, got $resolution');
    }
  }

  /// Writes one cache entry (body + meta sidecar) directly, keyed [key],
  /// expiring at [expiresAtMs].
  Future<void> writeEntry(
    String key, {
    required int expiresAtMs,
    int bodyBytes = 9,
  }) async {
    await File(
      '${tmp.path}/$key.body',
    ).writeAsBytes(List<int>.filled(bodyBytes, 120));
    await File('${tmp.path}/$key.json').writeAsString(
      jsonEncode({
        'contentType': 'image/png',
        'expiresAt': expiresAtMs,
        'ttlSeconds': 60,
      }),
    );
  }

  group('MediaCache.resolve', () {
    test('a miss fetches once and later resolves hit the disk cache', () async {
      final c = cache();
      var fetches = 0;
      Future<MediaFetchOutcome> fetch({String? etag, String? lastModified}) async {
        fetches++;
        return avatar(etag: '"v1"');
      }

      final key = MediaCache.keyFor('https://x/avatar.png', 64);
      expect(
        String.fromCharCodes(await servedBody(await c.resolve(key, fetch))),
        'png-bytes',
      );
      expect(
        String.fromCharCodes(await servedBody(await c.resolve(key, fetch))),
        'png-bytes',
      );
      expect(fetches, 1, reason: 'the second resolve must be a disk hit');
    });

    test('a fresh hit preserves the stored content type', () async {
      final c = cache();
      final key = MediaCache.keyFor('https://x/a.png', null);
      await c.resolve(key, ({etag, lastModified}) async => avatar());
      final hit = await c.resolve(
        key,
        ({etag, lastModified}) async => throw StateError('must not fetch'),
      );
      expect(hit, isA<MediaCacheHit>());
      expect((hit as MediaCacheHit).contentType, 'image/png');
    });

    test(
      'an expired entry is revalidated with its stored validators; a 304 '
      'serves the stored body and bumps the expiry',
      () async {
        final c = cache();
        final key = MediaCache.keyFor('https://x/a.png', 64);
        await c.resolve(
          key,
          ({etag, lastModified}) async =>
              avatar(etag: '"tag"', lastModified: 'Wed, 01 Jul 2026'),
        );

        // Advance past the (min-clamped) TTL so the entry is stale.
        now = now.add(const Duration(days: 2));
        final seenValidators = <String?>[];
        final resolution = await c.resolve(key, ({etag, lastModified}) async {
          seenValidators.addAll([etag, lastModified]);
          return const MediaFetchNotModified();
        });

        expect(seenValidators, ['"tag"', 'Wed, 01 Jul 2026']);
        expect(
          String.fromCharCodes(await servedBody(resolution)),
          'png-bytes',
        );

        // The bump made it fresh again: a third resolve fetches nothing.
        final third = await c.resolve(
          key,
          ({etag, lastModified}) async =>
              throw StateError('must not fetch after 304 bump'),
        );
        expect(third, isA<MediaCacheHit>());
      },
    );

    test('an expired entry is replaced when the refetch returns new bytes', () async {
      final c = cache();
      final key = MediaCache.keyFor('https://x/a.png', null);
      await c.resolve(
        key,
        ({etag, lastModified}) async => avatar(body: 'old'),
      );
      now = now.add(const Duration(days: 2));
      final resolution = await c.resolve(
        key,
        ({etag, lastModified}) async => avatar(body: 'new'),
      );
      expect(String.fromCharCodes(await servedBody(resolution)), 'new');
    });

    test('a failed refresh serves stale rather than erroring', () async {
      final c = cache();
      final key = MediaCache.keyFor('https://x/a.png', null);
      await c.resolve(
        key,
        ({etag, lastModified}) async => avatar(body: 'stale-but-fine'),
      );
      now = now.add(const Duration(days: 30));
      final resolution = await c.resolve(
        key,
        ({etag, lastModified}) async => const MediaFetchFailed(),
      );
      expect(
        String.fromCharCodes(await servedBody(resolution)),
        'stale-but-fine',
      );
    });

    test('a failed fetch with nothing stored is a failure', () async {
      final c = cache();
      final resolution = await c.resolve(
        MediaCache.keyFor('https://x/missing.png', null),
        ({etag, lastModified}) async => const MediaFetchFailed(),
      );
      expect(resolution, isA<MediaCacheFailure>());
    });

    test('concurrent resolves single-flight the upstream fetch', () async {
      final c = cache();
      var fetches = 0;
      final gate = Completer<void>();
      Future<MediaFetchOutcome> fetch({String? etag, String? lastModified}) async {
        fetches++;
        await gate.future;
        return avatar();
      }

      final key = MediaCache.keyFor('https://x/a.png', 96);
      final first = c.resolve(key, fetch);
      final second = c.resolve(key, fetch);
      final third = c.resolve(key, fetch);
      // Let all three reaches the in-flight join BEFORE the fetch finishes —
      // completing the gate first would let fetch #1 complete (and the entry
      // be removed) before the waiters even check the map.
      while (fetches == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      gate.complete();
      await Future.wait([first, second, third]);
      expect(fetches, 1);
    });

    test('a waiter on a stream outcome re-fetches for itself', () async {
      // A stream has exactly one consumer: the waiter must become the
      // initiator of a second fetch rather than share the first's stream.
      final upstreamServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() => upstreamServer.close(force: true));
      upstreamServer.listen((req) async {
        req.response
          ..headers.contentType = ContentType('video', 'mp4')
          ..add(const [1, 2, 3]);
        await req.response.close();
      });

      final c = cache();
      var fetches = 0;
      final gate = Completer<void>();
      final key = MediaCache.keyFor('https://x/movie.mp4', null);
      Future<MediaFetchOutcome> fetch({
        String? etag,
        String? lastModified,
      }) async {
        fetches++;
        await gate.future;
        if (fetches == 1) {
          final client = HttpClient();
          final response = await (await client.getUrl(
            Uri.parse('http://127.0.0.1:${upstreamServer.port}/v.mp4'),
          )).close();
          return MediaFetchStream(response, client);
        }
        return avatar(body: 'second-fetch');
      }

      final first = c.resolve(key, fetch);
      // Let `first` claim the single-flight slot and enter its fetch BEFORE the
      // waiter joins. Starting both and only then waiting for `fetches == 1`
      // leaves which call initiates up to the scheduler — and the roles are not
      // symmetric here: the initiator gets the stream (a passthrough) while the
      // waiter loops and re-fetches for itself (a cache hit). When the race
      // inverted, `first` came back a hit and the test failed about one run in
      // four.
      while (fetches == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      final second = c.resolve(key, fetch);
      // The waiter must be parked on the shared future before the stream
      // outcome lands.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      gate.complete();

      final passthrough = await first;
      expect(passthrough, isA<MediaCachePassthrough>());
      final stream = (passthrough as MediaCachePassthrough).outcome;
      await stream.response.drain<void>();
      stream.client.close(force: true);

      expect(
        String.fromCharCodes(await servedBody(await second)),
        'second-fetch',
      );
      expect(fetches, 2);
    });

    test('oversized bodies are served but never written to disk', () async {
      final c = cache(maxEntryBytes: 8);
      final key = MediaCache.keyFor('https://x/big.png', null);
      final resolution = await c.resolve(
        key,
        ({etag, lastModified}) async => const MediaFetchBuffered(
          bytes: [1, 2, 3, 4, 5, 6, 7, 8, 9],
          contentType: 'image/png',
        ),
      );
      expect(resolution, isA<MediaCacheUncached>());
      expect(tmp.listSync(recursive: true), isEmpty);
    });

    test('a no-store body is served but never written to disk', () async {
      final c = cache();
      final key = MediaCache.keyFor('https://x/private.png', null);
      final resolution = await c.resolve(
        key,
        ({etag, lastModified}) async => const MediaFetchBuffered(
          bytes: [1],
          contentType: 'image/png',
          cache: false,
        ),
      );
      expect(resolution, isA<MediaCacheUncached>());
      expect(tmp.listSync(recursive: true), isEmpty);
    });

    test('upstream max-age is clamped into the configured TTL window', () async {
      final c = cache();
      final key = MediaCache.keyFor('https://x/a.png', null);
      // max-age of one second → clamped UP to the 1h floor: still fresh 10
      // minutes later.
      await c.resolve(
        key,
        ({etag, lastModified}) async => avatar(maxAgeSeconds: 1),
      );
      now = now.add(const Duration(minutes: 10));
      final hit = await c.resolve(
        key,
        ({etag, lastModified}) async =>
            throw StateError('must not fetch inside the clamped floor'),
      );
      expect(hit, isA<MediaCacheHit>());

      // max-age of a year → clamped DOWN to the 7d cap: stale on day 8.
      now = now.add(const Duration(days: 30));
      final key2 = MediaCache.keyFor('https://x/b.png', null);
      await c.resolve(
        key2,
        ({etag, lastModified}) async => avatar(maxAgeSeconds: 365 * 24 * 3600),
      );
      now = now.add(const Duration(days: 8));
      var refetched = false;
      await c.resolve(key2, ({etag, lastModified}) async {
        refetched = true;
        return avatar();
      });
      expect(refetched, isTrue);
    });
  });

  group('MediaCache LRU sweep', () {
    test('evicts least-recently-used entries once over the byte cap', () async {
      final c = cache(maxTotalBytes: 30);
      // Bodies + FRESH metas written directly (no resolve → no scheduled
      // sweep racing the mtime setup below; a meta-less body is an orphan
      // the TTL pass reaps). 12 bytes each; the cap of 30 keeps two, evicts
      // one.
      final freshMs = now.add(const Duration(days: 30)).millisecondsSinceEpoch;
      File bodyOf(String name) => File('${tmp.path}/$name.body');
      for (final name in ['a', 'b', 'c']) {
        await writeEntry(name, expiresAtMs: freshMs, bodyBytes: 12);
      }
      // Deterministic LRU order: c most recently used, a least.
      final t = DateTime(2026, 1, 1);
      await bodyOf('a').setLastModified(t);
      await bodyOf('b').setLastModified(t.add(const Duration(hours: 1)));
      await bodyOf('c').setLastModified(t.add(const Duration(hours: 2)));

      await c.sweepForTest();

      expect(bodyOf('a').existsSync(), isFalse);
      expect(File('${tmp.path}/a.json').existsSync(), isFalse);
      expect(bodyOf('b').existsSync(), isTrue);
      expect(bodyOf('c').existsSync(), isTrue);
    });
  });

  group('MediaCache TTL-grace sweep', () {
    test(
      'entries expired beyond the grace window are deleted, the rest kept',
      () async {
        final c = cache(); // default maxStaleAge: 7 days past expiry
        final t0 = now.millisecondsSinceEpoch;
        const day = Duration(days: 1);
        await writeEntry('old', expiresAtMs: t0 - (day * 8).inMilliseconds);
        await writeEntry('recent', expiresAtMs: t0 - day.inMilliseconds);
        await writeEntry('fresh', expiresAtMs: t0 + day.inMilliseconds);

        await c.sweepForTest();

        // Past the 7-day grace: the stale-if-error / revalidation value no
        // longer justifies the disk.
        expect(File('${tmp.path}/old.body').existsSync(), isFalse);
        expect(File('${tmp.path}/old.json').existsSync(), isFalse);
        // Within grace: still serves stale-if-error and revalidates by 304.
        expect(File('${tmp.path}/recent.body').existsSync(), isTrue);
        expect(File('${tmp.path}/recent.json').existsSync(), isTrue);
        expect(File('${tmp.path}/fresh.body').existsSync(), isTrue);
      },
    );

    test('orphan bodies and metas are reaped', () async {
      final c = cache();
      await File(
        '${tmp.path}/bodyOnly.body',
      ).writeAsBytes(List<int>.filled(9, 120));
      await File('${tmp.path}/metaOnly.json').writeAsString(
        jsonEncode({
          'contentType': 'image/png',
          'expiresAt': now
              .add(const Duration(days: 1))
              .millisecondsSinceEpoch,
          'ttlSeconds': 60,
        }),
      );

      await c.sweepForTest();

      expect(File('${tmp.path}/bodyOnly.body').existsSync(), isFalse);
      expect(File('${tmp.path}/metaOnly.json').existsSync(), isFalse);
    });

    test('the periodic sweep reaps dead entries with no write traffic', () async {
      final c = cache();
      await writeEntry(
        'dead',
        expiresAtMs:
            now.millisecondsSinceEpoch - const Duration(days: 8).inMilliseconds,
      );

      c.startPeriodicSweep(interval: const Duration(milliseconds: 20));
      addTearDown(c.close);

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (File('${tmp.path}/dead.body').existsSync() &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(File('${tmp.path}/dead.body').existsSync(), isFalse);
    });

    test('close stops the periodic sweep', () async {
      final c = cache();
      c.startPeriodicSweep(interval: const Duration(milliseconds: 20));
      c.close();
      await writeEntry(
        'dead',
        expiresAtMs:
            now.millisecondsSinceEpoch - const Duration(days: 8).inMilliseconds,
      );
      // Several intervals pass with no timer armed: nothing is reaped.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(File('${tmp.path}/dead.body').existsSync(), isTrue);
    });
  });

  group('MediaCache.keyFor', () {
    test('keys on (url, w) and nothing else', () {
      final a = MediaCache.keyFor('https://x/a.png', 64);
      expect(a, MediaCache.keyFor('https://x/a.png', 64));
      expect(a, isNot(MediaCache.keyFor('https://x/a.png', 96)));
      expect(a, isNot(MediaCache.keyFor('https://x/a.png', null)));
      expect(a, isNot(MediaCache.keyFor('https://x/b.png', 64)));
    });
  });
}
