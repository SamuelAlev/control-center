
import 'package:cc_domain/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake analytics repository for testing SnapshotAggregator.
class _FakeAnalyticsRepo implements AnalyticsRepository {
  int rebuildCallCount = 0;
  final List<Exception> _errors = [];

  void setErrors(List<Exception> errors) => _errors.addAll(errors);

  @override
  Future<void> rebuildDailyStats() async {
    rebuildCallCount++;
    if (_errors.isNotEmpty) {
      throw _errors.removeAt(0);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SnapshotAggregator', () {
    test('dispose is safe when never started', () {
      final agg = SnapshotAggregator(_FakeAnalyticsRepo());
      agg.dispose();
    });

    test('start triggers initial rebuild', () {
      final repo = _FakeAnalyticsRepo();
      final agg = SnapshotAggregator(repo);

      agg.start();
      expect(repo.rebuildCallCount, 1);

      agg.dispose();
    });


    test('dispose prevents further rebuilds', () {
      final repo = _FakeAnalyticsRepo();
      final agg = SnapshotAggregator(repo);

      agg.start();
      expect(repo.rebuildCallCount, 1);
      agg.dispose();

      // After dispose, no more rebuilds — verify the initial was the only one.
      expect(repo.rebuildCallCount, 1);
    });

    test('rebuild errors are caught and do not crash the timer', () {
      final repo = _FakeAnalyticsRepo();
      repo.setErrors([Exception('rebuild failed')]);
      final agg = SnapshotAggregator(repo);

      agg.start();
      // Initial rebuild threw, but the error was caught — call count still incremented.
      expect(repo.rebuildCallCount, 1);

      agg.dispose();
    });

    test('multiple dispose calls are safe', () {
      final agg = SnapshotAggregator(_FakeAnalyticsRepo());
      agg.dispose();
      agg.dispose();
    });
  });
}
