import 'dart:async';

/// Cancels in-flight `ForgePrClient` calls, in domain terms.
///
/// The port must not name an HTTP library, so callers hold this and each
/// adapter maps it onto its transport's own cancellation (rhttp's
/// `CancelToken` today). One token may be handed to several calls; cancelling
/// it aborts every one still in flight and any started afterwards.
///
/// An aborted call fails with the transport's cancellation error, which callers
/// that cancel on purpose (a subscriber that went away) treat as a quiet stop,
/// never as a failure to surface.
final class ForgeCancelToken {
  /// Creates a token that has not been cancelled.
  ForgeCancelToken();

  final Completer<void> _requested = Completer<void>();

  /// Whether [cancel] has been called.
  bool get isCancelled => _requested.isCompleted;

  /// Completes on the first [cancel], whether or not a call is in flight.
  Future<void> get whenCancelRequested => _requested.future;

  /// Requests cancellation. Idempotent; returns at once and never waits for a
  /// transport to observe it.
  void cancel() {
    if (!_requested.isCompleted) {
      _requested.complete();
    }
  }
}
