import 'dart:async';

import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_host/cc_host.dart';

/// Snapshot aggregator.
class SnapshotAggregator {
  /// Creates a new [SnapshotAggregator].
  SnapshotAggregator(this._analyticsRepo);

  final AnalyticsRepository _analyticsRepo;
  Timer? _timer;

  /// Starts the hourly snapshot aggregation timer.
  void start() {
    _rebuild();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => _rebuild());
  }

  /// Cancels the aggregation timer and releases resources.
  void dispose() {
    _timer?.cancel();
  }

  Future<void> _rebuild() async {
    try {
      await _analyticsRepo.rebuildDailyStats();
    } catch (e, st) {
      CcHostLog.error('SnapshotAggregator: rebuildDailyStats failed: $e', e, st);
    }
  }
}
