import 'dart:async';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';

/// Short-lived single-flight cache in front of Claude's usage endpoint.
///
/// `/api/oauth/usage` rate-limits hard; multi-account × pill + dispatch readers
/// caused 429s that looked like "all plans broken". Guarantees: one in-flight
/// future per config dir; success reused for [ttl]; failures cached for
/// [errorTtl] (immediate 429 retries sustain the throttle).
class ClaudeUsageCache {
  /// Creates a [ClaudeUsageCache] over [_fetch].
  ClaudeUsageCache({
    required this._fetch,
    this.ttl = const Duration(minutes: 5),
    this.errorTtl = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Future<SubscriptionUsage> Function(String configDir) _fetch;
  final DateTime Function() _now;

  /// How long a good reading is reused. Comfortably under the pill's own
  /// ten-minute refresh, so an operator who opens it still sees fresh numbers.
  final Duration ttl;

  /// How long a failed reading is reused before another request is allowed.
  final Duration errorTtl;

  final Map<String, ({DateTime at, SubscriptionUsage usage})> _entries = {};
  final Map<String, Future<SubscriptionUsage>> _inFlight = {};

  /// Usage for [configDir], from cache when it is fresh enough.
  Future<SubscriptionUsage> get(String configDir) async {
    final cached = _entries[configDir];
    if (cached != null) {
      final age = _now().difference(cached.at);
      final limit = cached.usage.status == SubscriptionStatus.ok
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

  /// Forgets [configDir]'s reading, so the next call refetches.
  ///
  /// Used when the credential underneath it changed — a stale reading taken
  /// with the old token would otherwise outlive the reason it failed.
  void invalidate(String configDir) => _entries.remove(configDir);

  /// Forgets every reading.
  void clear() => _entries.clear();
}
