/// Value object combining (ticketId, agentId, triggerSource) to prevent
/// duplicate dispatches for the same logical operation.
class IdempotencyKey {
  const IdempotencyKey({
    required this.ticketId,
    required this.agentId,
    required this.source,
  });

  final String ticketId;
  final String agentId;
  final String source;

  String get value => '$ticketId|$agentId|$source';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IdempotencyKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'IdempotencyKey($value)';
}

/// Guards against duplicate dispatches using in-memory dedup.
/// Production use should persist to DB to survive restarts.
class DispatchDedupGuard {

  DispatchDedupGuard({Duration window = const Duration(minutes: 5)})
      : _window = window;
  final Duration _window;

  final Map<String, DateTime> _recent = {};

  /// Returns true if a dispatch with [key] was already recorded within the window.
  bool isDuplicate(IdempotencyKey key) {
    final existing = _recent[key.value];
    if (existing == null) return false;
    return DateTime.now().difference(existing) < _window;
  }

  /// Records [key] as having been dispatched.
  void record(IdempotencyKey key) {
    _recent[key.value] = DateTime.now();
  }

  /// Clears the record for [key].
  void clear(IdempotencyKey key) {
    _recent.remove(key.value);
  }

  /// Purge expired entries.
  void purge() {
    final now = DateTime.now();
    _recent.removeWhere((_, ts) => now.difference(ts) >= _window);
  }
}
