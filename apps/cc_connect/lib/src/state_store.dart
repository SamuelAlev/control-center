import 'dart:async';

/// Short-lived shared state: nonces, staged logins, seal handoffs, Slack
/// reference queues, install tickets and counters. Every entry expires;
/// nothing here is durable, and nothing here is a plaintext token.
abstract interface class StateStore {
  /// The value at [key], or null.
  Future<String?> get(String key);

  /// Sets [key] to [value] for [ttl].
  Future<void> set(String key, String value, Duration ttl);

  /// Sets [key] only when absent. True when this call set it.
  Future<bool> putIfAbsent(String key, String value, Duration ttl);

  /// Atomically reads and deletes [key]: of two concurrent takers exactly one
  /// sees the value.
  Future<String?> take(String key);

  /// Deletes [key].
  Future<void> delete(String key);

  /// Increments the counter at [key] (created at 0 with [ttl]) and returns
  /// the new value.
  Future<int> increment(String key, Duration ttl);

  /// Appends [value] to the list at [key], keeps only the newest [maxLength]
  /// items, and (re)sets the list's expiry to [ttl].
  Future<void> push(String key, String value, Duration ttl, {int maxLength});

  /// Atomically removes and returns up to [max] of the oldest items.
  Future<List<String>> drain(String key, {int max});

  /// Releases connections.
  Future<void> close();
}

final class _Entry {
  _Entry(this.value, this.expiresAt);

  Object value;
  DateTime expiresAt;
}

/// [StateStore] in process memory. Correct for exactly one instance (a
/// self-hosted container or an embedded Connect); a multi-instance deploy
/// needs [StateStore] on Redis.
final class MemoryStateStore implements StateStore {
  /// Creates the store. [clock] drives expiry (tests pin it).
  MemoryStateStore({DateTime Function()? clock, this.maxEntries = 200000})
    : _clock = clock ?? DateTime.now {
    _sweeper = Timer.periodic(const Duration(minutes: 1), (_) => _sweep());
  }

  /// Hard cap on live keys; the oldest-expiring entries go first beyond it.
  final int maxEntries;
  final DateTime Function() _clock;
  final Map<String, _Entry> _entries = {};
  late final Timer _sweeper;
  DateTime? _lastOverflowSweep;

  _Entry? _live(String key) {
    final entry = _entries[key];
    if (entry == null) {
      return null;
    }
    if (!_clock().isBefore(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry;
  }

  void _put(String key, Object value, Duration ttl) {
    final now = _clock();
    if (_entries.remove(key) == null && _entries.length >= maxEntries) {
      // Sweep expired entries at most once a second when at capacity so a
      // burst on a full store stays O(1) instead of scanning 200k keys/op.
      final lastSweep = _lastOverflowSweep;
      if (lastSweep == null ||
          now.difference(lastSweep) >= const Duration(seconds: 1)) {
        _lastOverflowSweep = now;
        _sweepAt(now);
      }
      if (_entries.length >= maxEntries) {
        String? victimKey;
        DateTime? victimExpiry;
        var inspected = 0;
        for (final entry in _entries.entries) {
          if (!now.isBefore(entry.value.expiresAt)) {
            victimKey = entry.key;
            break;
          }
          if (victimExpiry == null ||
              entry.value.expiresAt.isBefore(victimExpiry)) {
            victimKey = entry.key;
            victimExpiry = entry.value.expiresAt;
          }
          if (++inspected >= 16) {
            break;
          }
        }
        if (victimKey != null) {
          _entries.remove(victimKey);
        }
      }
    }
    _entries[key] = _Entry(value, now.add(ttl));
  }

  void _sweep() => _sweepAt(_clock());

  void _sweepAt(DateTime now) {
    _entries.removeWhere((_, entry) => !now.isBefore(entry.expiresAt));
  }

  @override
  Future<String?> get(String key) async {
    final value = _live(key)?.value;
    return value is String ? value : null;
  }

  @override
  Future<void> set(String key, String value, Duration ttl) async =>
      _put(key, value, ttl);

  @override
  Future<bool> putIfAbsent(String key, String value, Duration ttl) async {
    if (_live(key) != null) {
      return false;
    }
    _put(key, value, ttl);
    return true;
  }

  @override
  Future<String?> take(String key) async {
    final value = _live(key)?.value;
    _entries.remove(key);
    return value is String ? value : null;
  }

  @override
  Future<void> delete(String key) async => _entries.remove(key);

  @override
  Future<int> increment(String key, Duration ttl) async {
    final entry = _live(key);
    if (entry == null || entry.value is! int) {
      _put(key, 1, ttl);
      return 1;
    }
    final next = (entry.value as int) + 1;
    entry.value = next;
    return next;
  }

  @override
  Future<void> push(
    String key,
    String value,
    Duration ttl, {
    int maxLength = 1000,
  }) async {
    final entry = _live(key);
    final list = entry?.value is List<String>
        ? entry!.value as List<String>
        : <String>[];
    list.add(value);
    if (list.length > maxLength) {
      list.removeRange(0, list.length - maxLength);
    }
    _put(key, list, ttl);
  }

  @override
  Future<List<String>> drain(String key, {int max = 100}) async {
    final entry = _live(key);
    if (entry == null || entry.value is! List<String>) {
      return const [];
    }
    final list = entry.value as List<String>;
    final count = list.length < max ? list.length : max;
    final out = list.sublist(0, count);
    list.removeRange(0, count);
    if (list.isEmpty) {
      _entries.remove(key);
    }
    return out;
  }

  @override
  Future<void> close() async {
    _sweeper.cancel();
    _entries.clear();
  }
}
