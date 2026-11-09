import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show b64url, randomBytes;

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

  /// Sets [key] to [value] for [ttl] only while it still holds [expected]
  /// (compare-and-set). True when this call replaced it.
  Future<bool> replace(String key, String expected, String value, Duration ttl);

  /// Atomically reads and deletes [key]: of two concurrent takers exactly one
  /// sees the value.
  Future<String?> take(String key);

  /// Deletes [key].
  Future<void> delete(String key);

  /// Deletes [key] only while it still holds [expected] (compare-and-delete).
  /// True when this call deleted it.
  Future<bool> deleteIf(String key, String expected);

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
  Future<bool> replace(
    String key,
    String expected,
    String value,
    Duration ttl,
  ) async {
    if (_live(key)?.value != expected) {
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
  Future<bool> deleteIf(String key, String expected) async {
    if (_live(key)?.value != expected) {
      return false;
    }
    _entries.remove(key);
    return true;
  }

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

/// An expiring, owned lock on one [StateStore] key.
///
/// The lease holds a random token under [key] for [ttl]: a holder that
/// crashes (or loses its connection) can never wedge the key past [ttl]. A
/// live holder renews the lease every third of [ttl] while it works, and
/// releasing deletes the key only while it still holds this lease's token,
/// so a holder whose lease lapsed never releases its successor's.
final class StateLease {
  StateLease._(this._store, this.key, this._token, this.ttl) {
    _renewer = Timer.periodic(
      Duration(microseconds: ttl.inMicroseconds ~/ 3),
      (_) => unawaited(_renew()),
    );
  }

  /// Takes [key] for [ttl], or null when another holder has it.
  static Future<StateLease?> acquire(
    StateStore store,
    String key,
    Duration ttl,
  ) async {
    final token = b64url(randomBytes(16));
    if (!await store.putIfAbsent(key, token, ttl)) {
      return null;
    }
    return StateLease._(store, key, token, ttl);
  }

  /// Takes over [key] from the holder that stored [holder] there
  /// (compare-and-set), or null when it changed meanwhile.
  static Future<StateLease?> takeOver(
    StateStore store,
    String key,
    String holder,
    Duration ttl,
  ) async {
    final token = b64url(randomBytes(16));
    if (!await store.replace(key, holder, token, ttl)) {
      return null;
    }
    return StateLease._(store, key, token, ttl);
  }

  final StateStore _store;

  /// The locked key.
  final String key;

  /// How long the lease outlives its last renewal.
  final Duration ttl;
  final String _token;
  late final Timer _renewer;
  bool _lost = false;
  bool _released = false;

  /// The value stored under [key] while this lease holds it.
  String get token => _token;

  /// True once a renewal found the key no longer ours (it lapsed and another
  /// holder took it).
  bool get lost => _lost;

  Future<void> _renew() async {
    if (_released || _lost) {
      return;
    }
    try {
      if (!await _store.replace(key, _token, _token, ttl)) {
        _lost = true;
        _renewer.cancel();
      }
    } on Object {
      // A transient store failure: the next tick retries, and the lease
      // still lapses on its own if the store stays away.
    }
  }

  /// Ends the lease. Never throws: a store that is unreachable now lets the
  /// key lapse after [ttl] instead, and a caller's result must not be lost
  /// to a failed unlock.
  Future<void> release() async {
    if (_released) {
      return;
    }
    _released = true;
    _renewer.cancel();
    try {
      await _store.deleteIf(key, _token);
    } on Object {
      // Lapses after [ttl].
    }
  }
}
