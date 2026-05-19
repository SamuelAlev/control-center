import 'dart:async';

/// Signature for a function that cleans up the live work of a pipeline
/// step. Bodies register one of these at start (e.g. kill the bash
/// subprocess, kill the dispatched agent's PID and cancel its task) so the
/// UI's "Stop" button can interrupt them.
typedef StepKillFn = FutureOr<void> Function();

/// In-memory registry mapping `stepRunId` → kill callback. Process IDs and
/// task IDs are transient — they don't need to survive an app restart — so
/// the registry stays in memory. Bodies must call [unregister] when they
/// finish so we don't leak callbacks for steps that already terminated.
class StepProcessRegistry {
  final Map<String, StepKillFn> _callbacks = {};

  /// Registers [kill] for [stepRunId], replacing any previous registration.
  void register(String stepRunId, StepKillFn kill) {
    _callbacks[stepRunId] = kill;
  }

  /// Removes the registration for [stepRunId]. No-op if absent.
  void unregister(String stepRunId) {
    _callbacks.remove(stepRunId);
  }

  /// Invokes the registered callback for [stepRunId] and removes it.
  /// Returns true if a callback was registered, false otherwise (in which
  /// case the engine should still mark the row killed but the body's
  /// underlying work is presumed already gone).
  Future<bool> kill(String stepRunId) async {
    final fn = _callbacks.remove(stepRunId);
    if (fn == null) {
      return false;
    }
    await Future.sync(fn);
    return true;
  }

  /// Whether [stepRunId] has a live kill callback.
  bool isLive(String stepRunId) => _callbacks.containsKey(stepRunId);
}
