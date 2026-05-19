import 'dart:collection';

/// Per-session sliding-window rate limiter for remote `tools/call` traffic.
///
/// A paired phone is authenticated but untrusted: after approval a modified or
/// hijacked client could loop tool calls to burn resources, flood local writes,
/// or churn the desktop. This caps both the overall call rate and a tighter
/// sub-limit for mutating verbs (see `RemoteToolPolicy.mutating`).
///
/// One instance per `RemoteRpcSession`; not shared across devices. Uses an
/// injectable `now` clock so tests are deterministic.
class RemoteRateLimiter {
  /// Creates a limiter allowing [maxCallsPerWindow] total calls and
  /// [maxMutationsPerWindow] mutating calls within a rolling [window].
  RemoteRateLimiter({
    this.window = const Duration(minutes: 1),
    this.maxCallsPerWindow = 120,
    this.maxMutationsPerWindow = 30,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// The rolling window over which calls are counted.
  final Duration window;

  /// Maximum total `tools/call` invocations per [window].
  final int maxCallsPerWindow;

  /// Maximum mutating invocations per [window] (subset of the total).
  final int maxMutationsPerWindow;

  final DateTime Function() _now;
  final Queue<DateTime> _calls = Queue<DateTime>();
  final Queue<DateTime> _mutations = Queue<DateTime>();

  /// Attempts to admit one call. Returns `true` when within limits (and records
  /// it), `false` when the relevant window is saturated (nothing recorded).
  bool tryAcquire({required bool mutating}) {
    final now = _now();
    _evictOlderThan(_calls, now);
    _evictOlderThan(_mutations, now);

    if (_calls.length >= maxCallsPerWindow) {
      return false;
    }
    if (mutating && _mutations.length >= maxMutationsPerWindow) {
      return false;
    }

    _calls.add(now);
    if (mutating) {
      _mutations.add(now);
    }
    return true;
  }

  void _evictOlderThan(Queue<DateTime> q, DateTime now) {
    final cutoff = now.subtract(window);
    while (q.isNotEmpty && !q.first.isAfter(cutoff)) {
      q.removeFirst();
    }
  }
}
