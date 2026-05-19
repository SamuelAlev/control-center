/// Hit/miss/eviction counters for the caches that carry real cost.
///
/// The performance review's standing complaint about this codebase's caching
/// was not that the caches are badly designed — several are exemplary — but
/// that **not one of them reports anything**. There was no hit rate, no
/// eviction count and no size reading anywhere, which means every capacity and
/// every TTL in the repo is a guess that has never been checked against a
/// running system. You cannot tune what you cannot see.
///
/// This is deliberately the cheapest thing that fixes that: three integer
/// increments and one gauge per cache, read out through `/healthz`. It is NOT
/// a metrics framework — no histograms, no time series, no exporter. A counter
/// that costs an increment can live on a hot path; anything heavier would have
/// to be sampled, and a sampled hit rate is the kind of number that misleads.
///
/// Pure Dart with no dependencies so both tiers can use it.
library;

/// One cache's counters.
class CacheStats {
  /// Creates counters for a cache named [name].
  CacheStats(this.name);

  /// Identifier used in the `/healthz` payload (e.g. `media`, `pr_swr`).
  final String name;

  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _entries = 0;
  int _bytes = 0;

  /// Lookups served from the cache.
  int get hits => _hits;

  /// Lookups that had to do the work.
  int get misses => _misses;

  /// Entries dropped to stay inside a bound.
  int get evictions => _evictions;

  /// Current entry count, when the cache tracks one.
  int get entries => _entries;

  /// Current byte total, when the cache tracks one (-1 = not tracked).
  int get bytes => _bytes;

  /// Hit rate in `[0, 1]`, or null before any lookup — null rather than 0 so a
  /// cache nobody has queried is not read as a cache that never hits.
  double? get hitRate {
    final total = _hits + _misses;
    return total == 0 ? null : _hits / total;
  }

  /// Records a lookup served from the cache.
  void hit() => _hits++;

  /// Records a lookup that missed.
  void miss() => _misses++;

  /// Records [count] evicted entries.
  void evicted([int count = 1]) => _evictions += count;

  /// Updates the size gauges. Pass -1 for a dimension the cache does not know.
  void size({int entries = -1, int bytes = -1}) {
    if (entries >= 0) {
      _entries = entries;
    }
    if (bytes >= 0) {
      _bytes = bytes;
    }
  }

  /// Resets every counter (tests).
  void reset() {
    _hits = 0;
    _misses = 0;
    _evictions = 0;
    _entries = 0;
    _bytes = 0;
  }

  /// The `/healthz` shape.
  Map<String, Object?> toJson() => {
    'hits': _hits,
    'misses': _misses,
    'evictions': _evictions,
    if (_entries > 0) 'entries': _entries,
    if (_bytes > 0) 'bytes': _bytes,
    if (hitRate case final rate?)
      'hitRate': double.parse(rate.toStringAsFixed(3)),
  };
}

/// The process-wide registry of [CacheStats].
///
/// A registry rather than injected dependencies: the caches this instruments
/// are scattered across four packages and several are constructed deep inside
/// other objects, so threading a collaborator to each would be a larger change
/// than the instrumentation itself — and this holds nothing but counters.
class CacheStatsRegistry {
  CacheStatsRegistry._();

  /// The shared instance.
  static final CacheStatsRegistry instance = CacheStatsRegistry._();

  final Map<String, CacheStats> _byName = {};

  /// The counters for [name], created on first use.
  CacheStats of(String name) =>
      _byName.putIfAbsent(name, () => CacheStats(name));

  /// Every registered cache's counters, name-sorted for a stable payload.
  Map<String, Object?> toJson() {
    final names = _byName.keys.toList()..sort();
    return {for (final name in names) name: _byName[name]!.toJson()};
  }

  /// Resets every registered cache (tests).
  void resetAll() {
    for (final stats in _byName.values) {
      stats.reset();
    }
  }
}
