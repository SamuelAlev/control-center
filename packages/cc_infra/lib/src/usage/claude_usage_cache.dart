import 'dart:async';

import 'package:cc_domain/features/subscriptions/subscriptions.dart';

/// A short-lived, single-flight cache in front of Claude's usage endpoint.
///
/// ## Why this has to exist
///
/// `/api/oauth/usage` rate-limits callers aggressively, and multi-account
/// turned one read per machine into one read PER ACCOUNT — then two independent
/// readers wanted them: the title-bar pill (every ten minutes, and on every
/// open) and the dispatch-time headroom check (before every run). Three
/// accounts times two readers is six requests where there used to be one, and
/// the endpoint answered with 429s. The visible symptom is the worst kind:
/// every account reports no usage at once, which reads as "all my plans are
/// broken" rather than "we asked too often".
///
/// ## What it guarantees
///
/// * At most one in-flight request per config dir — concurrent callers share
///   the same future rather than racing (the pill opening while a dispatch
///   resolves is the normal case, not a rare one).
/// * A successful reading is reused for [ttl].
/// * A FAILED reading is cached too, for [errorTtl]. That is the important
///   half: retrying a 429 immediately is what turns a brief throttle into a
///   sustained one.
class ClaudeUsageCache {
  /// Creates a [ClaudeUsageCache] over [fetch].
  ClaudeUsageCache({
    required Future<SubscriptionUsage> Function(String configDir) fetch,
    this.ttl = const Duration(minutes: 5),
    this.errorTtl = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _fetch = fetch,
       _now = now ?? DateTime.now;

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
