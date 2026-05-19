import 'package:cc_domain/core/domain/services/cache_stats.dart';
import 'package:test/test.dart';

void main() {
  setUp(CacheStatsRegistry.instance.resetAll);

  group('CacheStats', () {
    test('hitRate is null before any lookup, not zero', () {
      // Zero would read as "this cache never hits", which is a different and
      // much more alarming claim than "nobody has asked it anything".
      expect(CacheStats('x').hitRate, isNull);
      expect(CacheStats('x').toJson().containsKey('hitRate'), isFalse);
    });

    test('counts hits, misses and evictions', () {
      final stats = CacheStats('x')
        ..hit()
        ..hit()
        ..hit()
        ..miss()
        ..evicted(2);
      expect(stats.hits, 3);
      expect(stats.misses, 1);
      expect(stats.evictions, 2);
      expect(stats.hitRate, closeTo(0.75, 1e-9));
    });

    test('size gauges ignore the -1 "not tracked" sentinel', () {
      final stats = CacheStats('x')
        ..size(entries: 12, bytes: 4096)
        // A cache that knows its entry count but not its bytes passes -1 for
        // the dimension it cannot answer; that must not clobber the other.
        ..size(entries: 20, bytes: -1);
      expect(stats.entries, 20);
      expect(stats.bytes, 4096);
    });

    test('json omits dimensions the cache never reported', () {
      final json = (CacheStats('x')..hit()).toJson();
      expect(json['hits'], 1);
      expect(json.containsKey('entries'), isFalse);
      expect(json.containsKey('bytes'), isFalse);
    });

    test('hitRate is rounded, not full float noise', () {
      final stats = CacheStats('x')
        ..hit()
        ..hit()
        ..miss();
      expect(stats.toJson()['hitRate'], 0.667);
    });
  });

  group('CacheStatsRegistry', () {
    test('returns the same counters for one name', () {
      final a = CacheStatsRegistry.instance.of('media')..hit();
      final b = CacheStatsRegistry.instance.of('media');
      expect(identical(a, b), isTrue);
      expect(b.hits, 1);
    });

    test('serializes registered caches name-sorted', () {
      CacheStatsRegistry.instance.of('zebra').hit();
      CacheStatsRegistry.instance.of('alpha').miss();
      final keys = CacheStatsRegistry.instance.toJson().keys.toList();
      // Registration is process-wide and permanent (resetAll zeroes counters,
      // it does not unregister), so assert the ORDER, not the membership — a
      // name another test registered is expected to still be listed.
      expect(keys, containsAllInOrder(['alpha', 'zebra']));
      expect(keys, orderedEquals(List<String>.of(keys)..sort()));
    });

    test('resetAll zeroes every registered cache', () {
      CacheStatsRegistry.instance.of('media')
        ..hit()
        ..evicted();
      CacheStatsRegistry.instance.resetAll();
      expect(CacheStatsRegistry.instance.of('media').hits, 0);
      expect(CacheStatsRegistry.instance.of('media').evictions, 0);
      expect(CacheStatsRegistry.instance.of('media').hitRate, isNull);
    });
  });
}
