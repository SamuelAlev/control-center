import 'dart:async';

import 'package:control_center/core/utils/app_log.dart';

/// Detects agent-based inactivity during execution. Resets on every event
/// received. Fires [onIdle] when no events arrive within [timeout].
class IdleWatchdog {
  IdleWatchdog({
    required this.timeout,
    required this.onIdle,
  });

  final Duration timeout;
  final void Function() onIdle;
  Timer? _timer;

  void start() {
    reset();
  }

  void reset() {
    _timer?.cancel();
    _timer = Timer(timeout, _onTimeout);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void recordEvent() {
    reset();
  }

  void _onTimeout() {
    AppLog.w('IdleWatchdog', 'No activity for ${timeout.inSeconds}s — flagging as idle');
    onIdle();
  }
}
