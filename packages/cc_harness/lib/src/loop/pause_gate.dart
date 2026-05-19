import 'dart:async';

/// Pauses an agent loop at the next clean turn boundary (PRD 16 §8).
///
/// Take-over needs the agent stopped mid-run WITHOUT killing it: the human
/// grabs the worktree, edits through the embedded IDE and hands back — the
/// agent then resumes and re-reads the thread (the hand-back summary arrives
/// as steering). The gate is checked at the TOP of each loop turn, so an
/// in-flight provider call / tool execution always completes first — a pause
/// never corrupts a half-applied turn.
///
/// Not persisted: a server restart kills the run entirely and the DURABLE
/// half of take-over (the space's take-over marker) independently prevents
/// auto-redispatch — a restart comes back paused-by-construction, never
/// auto-resuming into a human's half-finished edit.
class PauseGate {
  bool _paused = false;
  Completer<void>? _resume;

  /// Whether the loop should hold at the next turn boundary.
  bool get isPaused => _paused;

  /// Requests a pause. Idempotent.
  void pause() {
    if (_paused) {
      return;
    }
    _paused = true;
    _resume = Completer<void>();
  }

  /// Releases the loop. Idempotent.
  void resume() {
    if (!_paused) {
      return;
    }
    _paused = false;
    final resume = _resume;
    _resume = null;
    if (resume != null && !resume.isCompleted) {
      resume.complete();
    }
  }

  /// Completes immediately when running; otherwise waits for [resume].
  /// [onPaused] fires once when the wait actually blocks (the loop reports
  /// "paused at turn boundary" exactly when it holds, not when the pause was
  /// merely requested).
  Future<void> waitWhilePaused({void Function()? onPaused}) async {
    while (_paused) {
      final resume = _resume;
      if (resume == null) {
        return;
      }
      onPaused?.call();
      await resume.future;
    }
  }
}
