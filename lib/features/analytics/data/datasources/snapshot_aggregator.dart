import 'dart:async';

import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/analytics/domain/repositories/analytics_repository.dart';

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
      AppLog.e('SnapshotAggregator', 'rebuildDailyStats failed: $e', e, st);
    }
  }
}
