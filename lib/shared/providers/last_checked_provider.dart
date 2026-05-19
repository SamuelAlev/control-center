import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the last time each remote-data surface successfully fetched, keyed by
/// a stable surface identifier (e.g. `dashboard`, `pr-list`, `analytics`).
///
/// Surfaces stamp on successful data arrival (covers both first load and
/// post-refresh) and read their key back to render a "Checked {time}" label.
/// Surfaces that already persist a real fetch timestamp (GitHub status'
/// `fetchedAt`, RSS feeds' `lastFetchedAt`) derive their label from that data
/// instead of this store.
class LastCheckedNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() => const {};

  /// Records [DateTime.now] as the last-checked time for [key].
  void stamp(String key) {
    state = {...state, key: DateTime.now()};
  }
}

/// In-memory store of last-fetched times per surface. See [LastCheckedNotifier].
final lastCheckedProvider =
    NotifierProvider<LastCheckedNotifier, Map<String, DateTime>>(
      LastCheckedNotifier.new,
    );
