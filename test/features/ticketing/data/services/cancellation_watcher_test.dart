
import 'package:control_center/features/ticketing/data/services/cancellation_watcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CancellationWatcher', () {
    test('fires onCancel when shouldCancel returns true', () async {
      var cancelled = false;
      final watcher = CancellationWatcher(
        pollInterval: const Duration(milliseconds: 30),
      );

      watcher.start(
        shouldCancel: () async => true,
        onCancel: () => cancelled = true,
      );

      expect(cancelled, isFalse);
      await Future.delayed(const Duration(milliseconds: 60));
      expect(cancelled, isTrue);
    });

    test('does not fire when shouldCancel returns false', () async {
      var cancelled = false;
      final watcher = CancellationWatcher(
        pollInterval: const Duration(milliseconds: 30),
      );

      watcher.start(
        shouldCancel: () async => false,
        onCancel: () => cancelled = true,
      );

      await Future.delayed(const Duration(milliseconds: 120));
      expect(cancelled, isFalse);
    });

    test('shouldCancel is called periodically', () async {
      var callCount = 0;
      final watcher = CancellationWatcher(
        pollInterval: const Duration(milliseconds: 30),
      );

      watcher.start(
        shouldCancel: () async {
          callCount++;
          return false;
        },
        onCancel: () {},
      );

      await Future.delayed(const Duration(milliseconds: 80));
      expect(callCount, greaterThanOrEqualTo(2));
      watcher.stop();
    });

    test('stops polling on cancel', () async {
      var callCount = 0;
      var cancelled = false;
      final watcher = CancellationWatcher(
        pollInterval: const Duration(milliseconds: 30),
      );

      watcher.start(
        shouldCancel: () async {
          callCount++;
          return callCount >= 2;
        },
        onCancel: () => cancelled = true,
      );

      await Future.delayed(const Duration(milliseconds: 80));
      expect(cancelled, isTrue);
      final countAfterCancel = callCount;
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, countAfterCancel);
    });

    test('stop prevents further polling', () async {
      var callCount = 0;
      final watcher = CancellationWatcher(
        pollInterval: const Duration(milliseconds: 30),
      );

      watcher.start(
        shouldCancel: () async {
          callCount++;
          return false;
        },
        onCancel: () {},
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, greaterThanOrEqualTo(1));
      final countBeforeStop = callCount;
      watcher.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(callCount, countBeforeStop);
    });

    test('shouldCancel async errors do not propagate', () async {
      var cancelled = false;
      var callCount = 0;
      final watcher = CancellationWatcher(
        pollInterval: const Duration(milliseconds: 30),
      );

      watcher.start(
        shouldCancel: () async {
          callCount++;
          if (callCount == 1) {
            throw Exception('poll error');
          }
          return callCount >= 3;
        },
        onCancel: () => cancelled = true,
      );

      await Future.delayed(const Duration(milliseconds: 80));
      expect(callCount, greaterThanOrEqualTo(2));
      expect(cancelled, isFalse);

      await Future.delayed(const Duration(milliseconds: 60));
      expect(cancelled, isTrue);
    });

    test('stop is safe to call when not started', () {
      final watcher = CancellationWatcher();
      watcher.stop();
    });

    test('default poll interval is 5 seconds', () {
      final watcher = CancellationWatcher();
      expect(watcher.pollInterval, const Duration(seconds: 5));
    });
  });
}
