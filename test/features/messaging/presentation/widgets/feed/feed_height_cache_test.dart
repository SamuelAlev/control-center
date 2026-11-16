import 'package:control_center/features/messaging/presentation/widgets/feed/feed_height_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedHeightCache lookups', () {
    test('hits within half a pixel of the recorded width', () {
      final cache = FeedHeightCache()
        ..recordMeasured('seg:m1:0', 120, width: 400, revision: 1);

      expect(cache.measured('seg:m1:0', width: 400, revision: 1), 120);
      expect(cache.measured('seg:m1:0', width: 400.5, revision: 1), 120);
      expect(cache.measured('seg:m1:0', width: 399.5, revision: 1), 120);
      expect(cache.measured('seg:m1:0', width: 400.6, revision: 1), isNull);
      expect(cache.measured('seg:m1:0', width: 380, revision: 1), isNull);
    });

    test('misses on any other revision', () {
      final cache = FeedHeightCache()
        ..recordMeasured('k', 50, width: 300, revision: 3);

      expect(cache.measured('k', width: 300, revision: 2), isNull);
      expect(cache.measured('k', width: 300, revision: 4), isNull);
      expect(cache.measured('k', width: 300, revision: 3), 50);
    });

    test('misses on an unknown key', () {
      final cache = FeedHeightCache();
      expect(cache.measured('nope', width: 300, revision: 0), isNull);
      expect(cache.estimated('nope', width: 300, revision: 0), isNull);
      expect(cache.length, 0);
    });
  });

  group('FeedHeightCache measured vs estimated', () {
    test('recording one keeps the other at the same revision', () {
      final cache = FeedHeightCache()
        ..recordEstimated('k', 90, width: 300, revision: 1)
        ..recordMeasured('k', 104, width: 300, revision: 1);

      expect(cache.estimated('k', width: 300, revision: 1), 90);
      expect(cache.measured('k', width: 300, revision: 1), 104);

      cache.recordEstimated('k', 95, width: 300, revision: 1);
      expect(cache.measured('k', width: 300, revision: 1), 104);
      expect(cache.estimated('k', width: 300, revision: 1), 95);
      expect(cache.length, 1);
    });

    test('each value keeps its own width', () {
      final cache = FeedHeightCache()
        ..recordEstimated('k', 90, width: 300, revision: 1)
        ..recordMeasured('k', 70, width: 500, revision: 1);

      expect(cache.estimated('k', width: 300, revision: 1), 90);
      expect(cache.estimated('k', width: 500, revision: 1), isNull);
      expect(cache.measured('k', width: 500, revision: 1), 70);
      expect(cache.measured('k', width: 300, revision: 1), isNull);
    });

    test('a new revision replaces both values', () {
      final cache = FeedHeightCache()
        ..recordEstimated('k', 90, width: 300, revision: 1)
        ..recordMeasured('k', 104, width: 300, revision: 1)
        ..recordMeasured('k', 140, width: 300, revision: 2);

      expect(cache.measured('k', width: 300, revision: 2), 140);
      expect(cache.estimated('k', width: 300, revision: 2), isNull);
      expect(cache.estimated('k', width: 300, revision: 1), isNull);
      expect(cache.measured('k', width: 300, revision: 1), isNull);
    });
  });

  group('FeedHeightCache eviction', () {
    test('evicts the least recently used key past capacity', () {
      final cache = FeedHeightCache(maxEntries: 3)
        ..recordMeasured('a', 1, width: 100, revision: 0)
        ..recordMeasured('b', 2, width: 100, revision: 0)
        ..recordMeasured('c', 3, width: 100, revision: 0);

      // Touch `a` so `b` becomes the oldest.
      expect(cache.measured('a', width: 100, revision: 0), 1);
      cache.recordEstimated('d', 4, width: 100, revision: 0);

      expect(cache.length, 3);
      expect(cache.measured('b', width: 100, revision: 0), isNull);
      expect(cache.measured('a', width: 100, revision: 0), 1);
      expect(cache.measured('c', width: 100, revision: 0), 3);
      expect(cache.estimated('d', width: 100, revision: 0), 4);
    });

    test('a lookup that misses on width still refreshes recency', () {
      final cache = FeedHeightCache(maxEntries: 2)
        ..recordMeasured('a', 1, width: 100, revision: 0)
        ..recordMeasured('b', 2, width: 100, revision: 0);

      expect(cache.measured('a', width: 900, revision: 0), isNull);
      cache.recordMeasured('c', 3, width: 100, revision: 0);

      expect(cache.measured('a', width: 100, revision: 0), 1);
      expect(cache.measured('b', width: 100, revision: 0), isNull);
    });

    test('re-recording a key moves it to the newest end', () {
      final cache = FeedHeightCache(maxEntries: 2)
        ..recordMeasured('a', 1, width: 100, revision: 0)
        ..recordMeasured('b', 2, width: 100, revision: 0)
        ..recordMeasured('a', 5, width: 100, revision: 0)
        ..recordMeasured('c', 3, width: 100, revision: 0);

      expect(cache.measured('a', width: 100, revision: 0), 5);
      expect(cache.measured('b', width: 100, revision: 0), isNull);
    });
  });

  group('FeedHeightCache invalidation', () {
    test('invalidate drops both values for one key only', () {
      final cache = FeedHeightCache()
        ..recordMeasured('a', 1, width: 100, revision: 0)
        ..recordEstimated('a', 2, width: 100, revision: 0)
        ..recordMeasured('b', 3, width: 100, revision: 0)
        ..invalidate('a');

      expect(cache.measured('a', width: 100, revision: 0), isNull);
      expect(cache.estimated('a', width: 100, revision: 0), isNull);
      expect(cache.measured('b', width: 100, revision: 0), 3);
      expect(cache.length, 1);
    });

    test('clear empties the cache', () {
      final cache = FeedHeightCache()
        ..recordMeasured('a', 1, width: 100, revision: 0)
        ..recordMeasured('b', 3, width: 100, revision: 0)
        ..clear();

      expect(cache.length, 0);
      expect(cache.measured('b', width: 100, revision: 0), isNull);
    });
  });

  test('the provider hands out one shared cache', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final first = container.read(feedHeightCacheProvider)
      ..recordMeasured('a', 1, width: 100, revision: 0);
    expect(identical(container.read(feedHeightCacheProvider), first), isTrue);
    expect(first.maxEntries, 20000);
  });
}
