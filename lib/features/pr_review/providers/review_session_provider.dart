import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the start time of active PR review sessions, keyed by PR number.
///
/// When a PR detail screen is opened, it calls [ReviewSessionNotifier.start]
/// which records the session start time. The timer banner in the detail screen
/// reads from this provider to show the 60-min fatigue warning.
class ReviewSessionNotifier
    extends Notifier<Map<int, DateTime>> {
  @override
  Map<int, DateTime> build() => const {};

  /// Records a session start for [prNumber]. No-op if already tracking.
  void start(int prNumber) {
    if (state.containsKey(prNumber)) {
      return;
    }
    state = {...state, prNumber: DateTime.now()};
  }

  /// Clears the session for [prNumber].
  void end(int prNumber) {
    state = Map.of(state)..remove(prNumber);
  }

  /// Returns the session start time for [prNumber], or null if not tracked.
  DateTime? startedAt(int prNumber) => state[prNumber];
}

/// Provides the [ReviewSessionNotifier].
final reviewSessionProvider =
    NotifierProvider<ReviewSessionNotifier, Map<int, DateTime>>(
  ReviewSessionNotifier.new,
);
