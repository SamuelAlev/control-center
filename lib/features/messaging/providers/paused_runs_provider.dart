import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Run-log ids the operator has paused from the AGENTS panel (optimistic,
/// client-local).
///
/// The turn-boundary pause itself lives server-side (the harness pause gate);
/// this set only tracks which rows should show a "resume" affordance instead of
/// "pause". It is intentionally NOT persisted — a server restart clears both
/// the gate and this set, so a stale "paused" badge can never outlive the run.
class PausedRunsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  /// Marks [runId] as paused.
  void markPaused(String runId) => state = {...state, runId};

  /// Clears the paused mark for [runId].
  void markResumed(String runId) => state = {...state}..remove(runId);
}

/// Tracks which agent runs the operator has paused (see [PausedRunsNotifier]).
final pausedRunsProvider = NotifierProvider<PausedRunsNotifier, Set<String>>(
  PausedRunsNotifier.new,
);
