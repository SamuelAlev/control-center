import 'dart:async';

import 'package:control_center/core/utils/app_log.dart';

/// Detects agent-based inactivity during execution. Resets on every event
/// received. Fires [onIdle] when no events arrive within [timeout].
class IdleWatchdog {
  /// Creates a watchdog that fires [onIdle] after [timeout] of inactivity.
  IdleWatchdog({
    required this.timeout,
    required this.onIdle,
  });

  /// Maximum time to wait without activity before the watchdog fires.
  final Duration timeout;

  /// Callback invoked when no activity is recorded within [timeout].
  final void Function() onIdle;
  Timer? _timer;

  /// Starts monitoring for inactivity.
  void start() {
    reset();
  }

  /// Resets the inactivity timer to start counting from now.
  void reset() {
    _timer?.cancel();
    _timer = Timer(timeout, _onTimeout);
  }

  /// Stops monitoring and clears any pending timeout.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Records activity and refreshes the inactivity timer.
  void recordEvent() {
    reset();
  }

  void _onTimeout() {
    AppLog.w('IdleWatchdog', 'No activity for ${timeout.inSeconds}s — flagging as idle');
    onIdle();
  }
}
