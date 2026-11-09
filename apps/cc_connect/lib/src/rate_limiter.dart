import 'dart:async';
import 'dart:collection';

/// Token buckets keyed by an opaque string (install id, client IP, `*`).
/// Process-local: a cheap first line in front of Cloud Armor, not a
/// distributed quota.
final class TokenBucketLimiter {
  /// A bucket of [capacity] tokens refilled at [capacity] per [per].
  TokenBucketLimiter({
    required this.capacity,
    required this.per,
    this.maxKeys = 100000,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Burst size and refill amount per [per].
  final int capacity;

  /// The refill window.
  final Duration per;

  /// Most keys tracked; the least recently used are forgotten beyond it.
  final int maxKeys;
  final DateTime Function() _clock;
  final LinkedHashMap<String, ({double tokens, DateTime at})> _buckets =
      LinkedHashMap();

  /// Takes one token for [key]; false when the bucket is empty.
  bool tryTake(String key) {
    final now = _clock();
    final previous = _buckets.remove(key);
    var tokens = capacity.toDouble();
    if (previous != null) {
      final elapsed = now.difference(previous.at).inMicroseconds;
      final refill = elapsed / per.inMicroseconds * capacity;
      tokens = (previous.tokens + refill).clamp(0, capacity).toDouble();
    }
    final allowed = tokens >= 1;
    _buckets[key] = (tokens: allowed ? tokens - 1 : tokens, at: now);
    while (_buckets.length > maxKeys) {
      _buckets.remove(_buckets.keys.first);
    }
    return allowed;
  }
}

/// Bounds concurrent work (signature verification) and the queue in front of
/// it, so a flood waits briefly or is refused instead of piling up.
final class BoundedPool {
  /// Creates the pool.
  BoundedPool({required this.concurrency, required this.maxQueued});

  /// Jobs running at once.
  final int concurrency;

  /// Jobs allowed to wait.
  final int maxQueued;
  int _running = 0;
  final Queue<Completer<void>> _waiting = Queue();

  /// Runs [job] when a slot is free; null without running it when the queue
  /// is full.
  Future<T?> run<T>(Future<T> Function() job) async {
    if (_running >= concurrency) {
      if (_waiting.length >= maxQueued) {
        return null;
      }
      final slot = Completer<void>();
      _waiting.add(slot);
      await slot.future;
    } else {
      _running++;
    }
    try {
      return await job();
    } finally {
      if (_waiting.isNotEmpty) {
        _waiting.removeFirst().complete();
      } else {
        _running--;
      }
    }
  }
}
