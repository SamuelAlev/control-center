/// Prevents the OS from sleeping / suspending the app while held. Implemented
/// per-platform (e.g. a power-save / app-suspension assertion on macOS); a
/// no-op on platforms without a sleep concern (a headless server).
abstract interface class SleepBlockerPort {
  /// Acquires a sleep-prevention assertion with a human-readable [reason].
  /// Idempotent: a second begin while already held is a no-op.
  Future<void> begin(String reason);

  /// Releases the assertion, allowing the OS to sleep again. Idempotent.
  Future<void> end();
}

/// A [SleepBlockerPort] that does nothing — the default on platforms where
/// sleep prevention is irrelevant.
class NoopSleepBlocker implements SleepBlockerPort {
  /// Creates a [NoopSleepBlocker].
  const NoopSleepBlocker();

  @override
  Future<void> begin(String reason) async {}

  @override
  Future<void> end() async {}
}
