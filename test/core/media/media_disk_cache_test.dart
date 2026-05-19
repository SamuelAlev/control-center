import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/services/cache_stats.dart';
import 'package:control_center/core/media/media_disk_cache.dart';
import 'package:flutter_test/flutter_test.dart';

/// The desktop client's media disk cache.
///
/// The gap it closes: `NetworkImage` over `dart:io` has no HTTP cache and
/// Flutter's `ImageCache` is memory-only, so a desktop paired to a REMOTE
/// server re-downloaded its whole working set on every launch.
///
/// These run against a real loopback `HttpServer` rather than a mocked client,
/// because what is being asserted is that the SECOND request does not happen —
/// and a mock that counts calls it was told about proves less than a socket
/// nobody connected to.
void main() {
  late Directory root;
  late HttpServer server;
  late int requests;
  late List<int> body;
  late int status;

  setUp(() async {
    CacheStatsRegistry.instance.resetAll();
    root = await Directory.systemTemp.createTemp('cc-media-cache-test');
    requests = 0;
    status = HttpStatus.ok;
    body = utf8.encode('image-bytes');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests++;
      req.response
        ..statusCode = status
        ..headers.contentType = ContentType('image', 'png');
      if (status == HttpStatus.ok) {
        req.response.add(body);
      }
      await req.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  String urlFor(String path) =>
      'http://${server.address.host}:${server.port}/$path';

  MediaDiskCache build({
    int maxBytes = 1 << 20,
    int maxEntryBytes = 1 << 20,
    Duration ttl = const Duration(days: 30),
  }) => MediaDiskCache(
    root: root,
    maxBytes: maxBytes,
    maxEntryBytes: maxEntryBytes,
    ttl: ttl,
  );

  test('a second read is served from disk, not the network', () async {
    final cache = build();
    expect(await cache.get(urlFor('a.png')), isNotNull);
    expect(requests, 1);

    // A fresh instance, as after a restart — the whole point is surviving one.
    final restarted = build();
    expect(await restarted.get(urlFor('a.png')), Uint8List.fromList(body));
    expect(
      requests,
      1,
      reason: 'the launch after the first must not re-download the image',
    );
  });

  test('distinct URLs are distinct entries', () async {
    final cache = build();
    await cache.get(urlFor('a.png'));
    await cache.get(urlFor('b.png'));
    expect(requests, 2);
    await cache.get(urlFor('a.png'));
    expect(requests, 2);
  });

  test('concurrent reads of one URL issue a single request', () async {
    // Two widgets mounting the same avatar in one frame is the normal case.
    final cache = build();
    final results = await Future.wait([
      cache.get(urlFor('a.png')),
      cache.get(urlFor('a.png')),
      cache.get(urlFor('a.png')),
    ]);
    expect(requests, 1);
    expect(results.every((r) => r != null), isTrue);
  });

  test('an expired entry is re-fetched', () async {
    final cache = build(ttl: Duration.zero);
    await cache.get(urlFor('a.png'));
    await cache.get(urlFor('a.png'));
    expect(requests, 2);
  });

  test('a failed fetch returns null and caches nothing', () async {
    status = HttpStatus.notFound;
    final cache = build();
    expect(await cache.get(urlFor('a.png')), isNull);
    // A miss must not poison the entry: a later success still populates.
    status = HttpStatus.ok;
    expect(await cache.get(urlFor('a.png')), isNotNull);
    expect(await cache.get(urlFor('a.png')), isNotNull);
    expect(requests, 2);
  });

  test('a body over the per-entry cap is served but never stored', () async {
    // One video-sized response must not be able to evict the entire avatar
    // working set, so it is returned to the caller and dropped.
    body = List<int>.filled(4096, 7);
    final cache = build(maxEntryBytes: 128);
    expect(await cache.get(urlFor('big.png')), hasLength(4096));
    expect(await cache.get(urlFor('big.png')), hasLength(4096));
    expect(requests, 2, reason: 'an oversized body is not written to disk');
  });

  test('the sweep drops oldest-first back under the byte cap', () async {
    body = List<int>.filled(1000, 1);
    final cache = build(maxBytes: 2500);
    for (final name in ['a', 'b', 'c', 'd']) {
      await cache.get(urlFor('$name.png'));
    }
    await cache.sweep();

    final total = root
        .listSync(recursive: true)
        .whereType<File>()
        .fold<int>(0, (sum, f) => sum + f.lengthSync());
    expect(total, lessThanOrEqualTo(2500));
  });

  test('the sweep drops entries past the TTL', () async {
    final cache = build();
    await cache.get(urlFor('a.png'));
    final stored = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => !f.path.endsWith('.tmp'))
        .single;
    stored.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 90)));

    await cache.sweep();
    expect(stored.existsSync(), isFalse);
  });

  test('it reports hits, misses and size to the registry', () async {
    // The standing complaint about this codebase's caching was that not one of
    // ~30 caches reported anything, so every capacity and TTL was a guess. A
    // new cache that repeats that is not worth adding.
    final cache = build();
    await cache.get(urlFor('a.png'));
    await cache.get(urlFor('a.png'));
    await cache.sweep();

    final stats = CacheStatsRegistry.instance.of('media_disk');
    expect(stats.hits, 1);
    expect(stats.misses, 1);
    expect(stats.hitRate, 0.5);
    expect(stats.bytes, greaterThan(0));
  });

  test('an unreachable host is a miss, not a crash', () async {
    final cache = build();
    // Port 1 on loopback: reliably refused, no DNS involved.
    expect(await cache.get('http://127.0.0.1:1/a.png'), isNull);
  });

  test('clear removes every entry', () async {
    final cache = build();
    await cache.get(urlFor('a.png'));
    await cache.clear();
    expect(root.existsSync(), isFalse);
    await cache.get(urlFor('a.png'));
    expect(requests, 2);
  });
}
