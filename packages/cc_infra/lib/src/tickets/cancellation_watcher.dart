import 'dart:async';

import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Periodically polls a condition to check if the running task should be cancelled.
class CancellationWatcher {
  /// Creates a watcher that polls for cancellation at [pollInterval].
  CancellationWatcher({this.pollInterval = const Duration(seconds: 5)});

  /// Interval between cancellation checks.
  final Duration pollInterval;
  Timer? _timer;

  /// Starts polling [shouldCancel] and invokes [onCancel] when cancellation is requested.
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
        CcInfraLog.warning('Poll error (will retry): $e');
      }
    });
  }

  /// Stops polling for cancellation requests.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
