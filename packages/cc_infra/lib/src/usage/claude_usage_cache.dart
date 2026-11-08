import 'dart:async';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';

/// Short-lived single-flight cache in front of Claude's usage reading.
///
/// Each reading spawns the `claude` CLI, and the CLI asks a rate-limited
/// endpoint: multi-account × pill + dispatch readers once caused 429s that
/// looked like "all plans broken". Guarantees: one in-flight future per config
/// dir; success reused for [ttl]; failures cached for [errorTtl] (immediate
/// retries sustain a throttle).
class ClaudeUsageCache {
  /// Creates a [ClaudeUsageCache] over [_fetch].
  ClaudeUsageCache({
    required this._fetch,
    this.ttl = const Duration(minutes: 5),
    this.errorTtl = const Duration(minutes: 2),
    this.forceFloor = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Future<SubscriptionUsage> Function(String configDir) _fetch;
  final DateTime Function() _now;

  /// How long a good reading is reused. Comfortably under the pill's own
  /// ten-minute refresh, so an operator who opens it still sees fresh numbers.
  final Duration ttl;

  /// How long a failed reading is reused before another request is allowed.
  final Duration errorTtl;

  /// The youngest reading a forced read will replace. A refresh button is a
  /// button: clicked repeatedly it must not become the 429 storm this cache
  /// exists to prevent, so a reading this fresh is returned as-is.
  final Duration forceFloor;

  final Map<String, ({DateTime at, SubscriptionUsage usage})> _entries = {};
  final Map<String, Future<SubscriptionUsage>> _inFlight = {};

  /// Usage for [configDir], from cache when it is fresh enough.
  ///
  /// [force] is the operator asking for a new reading now: it ignores [ttl]
  /// and [errorTtl] down to [forceFloor], and still joins a fetch already in
  /// flight rather than starting a second one.
  Future<SubscriptionUsage> get(String configDir, {bool force = false}) async {
    final cached = _entries[configDir];
    if (cached != null) {
      final age = _now().difference(cached.at);
      final limit = force
          ? forceFloor
          : cached.usage.status == SubscriptionStatus.ok
          ? ttl
          : errorTtl;
      if (age < limit) {
        return cached.usage;
      }
    }
    return _inFlight[configDir] ??= _load(configDir);
  }

  Future<SubscriptionUsage> _load(String configDir) async {
    try {
      final usage = await _fetch(configDir);
      _entries[configDir] = (at: _now(), usage: usage);
      return usage;
    } finally {
      // `remove` hands back the future we are already inside; dropping it
      // explicitly keeps the analyzer from reading that as a forgotten await.
      unawaited(_inFlight.remove(configDir) ?? Future<void>.value());
    }
  }

  /// Folds [windows] from a live run into [configDir]'s reading.
  ///
  /// A running `claude` reports the plan's windows with its responses, so an
  /// account in use never needs another CLI spawn to stay current, and the
  /// rotation sees a window closing without waiting out [ttl]. Only a good
  /// reading is updated: a run reports windows alone, so it cannot stand in for
  /// a reading that failed or has yet to be taken.
  void observe(String configDir, List<SubscriptionWindow> windows) {
    final cached = _entries[configDir];
    if (cached == null ||
        windows.isEmpty ||
        cached.usage.status != SubscriptionStatus.ok) {
      return;
    }
    final fresh = {for (final w in windows) w.id: w};
    final merged = [
      for (final w in cached.usage.windows) fresh.remove(w.id) ?? w,
      ...fresh.values,
    ];
    _entries[configDir] = (
      at: _now(),
      usage: cached.usage.copyWith(windows: merged),
    );
  }

  /// Forgets [configDir]'s reading, so the next call refetches.
  ///
  /// Used when the credential underneath it changed — a stale reading taken
  /// with the old token would otherwise outlive the reason it failed.
  void invalidate(String configDir) => _entries.remove(configDir);

  /// Forgets every reading.
  void clear() => _entries.clear();
}
