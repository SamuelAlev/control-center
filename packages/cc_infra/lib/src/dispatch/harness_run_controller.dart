import 'package:cc_harness/loop.dart';

/// The turn-boundary control a built-in harness run exposes to the session
/// host: whether a loop is driving the session, the pause gate a take-over
/// (PRD 16 §8) holds it at, and what the run restored and activated.
///
/// External-CLI transports never [begin] it, so [pause] refuses for them —
/// they have no safe boundary, and callers fall back to stopping the run.
class HarnessRunController {
  /// The gate the loop (and every subagent loop, which shares it) waits on at
  /// the next clean turn boundary, so a take-over holds the whole
  /// conversation.
  final PauseGate pauseGate = PauseGate();

  bool _active = false;

  /// Whether a built-in harness loop is currently driving this session (the
  /// only transport that can pause at a turn boundary).
  bool get isActive => _active;

  /// Deferred tools this run pulled in, in activation order.
  ///
  /// Recorded on the run row so the question "did the agent ever find the
  /// tool it needed?" is answerable from the log rather than by re-running it.
  final List<String> activatedToolNames = [];

  /// Checkpoint labels restored from the persisted transcript, as indices
  /// into the history this run seeded.
  Map<String, int> resumedCheckpoints = const {};

  /// Marks a harness loop as driving the session.
  void begin() => _active = true;

  /// Marks the loop finished and releases any pause, so nothing stays parked
  /// on a gate no loop will check again.
  void end() {
    _active = false;
    pauseGate.resume();
  }

  /// Requests a turn-boundary pause. Returns false when no harness loop is
  /// live.
  bool pause() {
    if (!_active) {
      return false;
    }
    pauseGate.pause();
    return true;
  }

  /// Releases a paused loop (hand-back). Idempotent.
  void resume() => pauseGate.resume();
}
