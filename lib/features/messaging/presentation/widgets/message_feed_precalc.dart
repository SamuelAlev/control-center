part of 'message_feed.dart';

extension _PrecalcMethods on _SpaceMessageFeedState {
  /// Holds extent precalculation off until the feed has been still for
  /// [_precalcIdleDelay], then re-arms it.
  ///
  /// Called on open, on every window emission and on every scroll, so
  /// precalculation only ever runs in the gaps: opening a chat, growing the
  /// window and reading through it all push it back out.
  ///
  /// Runs per scroll tick, so it only flags the pending wait: one timer is
  /// alive at a time and, when it fires after fresh activity, waits again.
  /// Idle is therefore detected [_precalcIdleDelay]–2×[_precalcIdleDelay]
  /// after the last movement.
  void _deferPrecalculation() {
    _precalcPolicy.disarm();
    if (_precalcTimer != null) {
      _precalcDeferredAgain = true;
      return;
    }
    _precalcTimer = Timer(_precalcIdleDelay, _onPrecalcIdle);
  }

  void _onPrecalcIdle() {
    _precalcTimer = null;
    if (!mounted) {
      return;
    }
    if (_precalcDeferredAgain) {
      _precalcDeferredAgain = false;
      _precalcTimer = Timer(_precalcIdleDelay, _onPrecalcIdle);
      return;
    }
    _precalcPolicy.arm();
  }
}
