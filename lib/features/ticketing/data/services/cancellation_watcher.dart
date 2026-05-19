import 'dart:async';

import 'package:control_center/core/utils/app_log.dart';

/// Periodically polls a condition to check if the running task should be cancelled.
class CancellationWatcher {
  CancellationWatcher({this.pollInterval = const Duration(seconds: 5)});

  final Duration pollInterval;
  Timer? _timer;

  void start({
    required Future<bool> Function() shouldCancel,
    required void Function() onCancel,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (timer) async {
      try {
        if (await shouldCancel()) {
          timer.cancel();
          onCancel();
        }
      } on Object catch (e) {
        AppLog.w('CancellationWatcher', 'Poll error (will retry): $e');
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
