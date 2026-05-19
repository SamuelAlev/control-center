import 'package:cc_infra/src/tickets/idle_watchdog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdleWatchdog', () {
    test('fires onIdle after timeout with no activity', () async {
      var fired = false;
      final watchdog = IdleWatchdog(
        timeout: const Duration(milliseconds: 50),
        onIdle: () => fired = true,
      );

      watchdog.start();
      expect(fired, isFalse);

      await Future.delayed(const Duration(milliseconds: 80));
      expect(fired, isTrue);
    });

    test('does not fire onIdle before timeout', () async {
      var fired = false;
      final watchdog = IdleWatchdog(
        timeout: const Duration(milliseconds: 100),
        onIdle: () => fired = true,
      );

      watchdog.start();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(fired, isFalse);
    });

    test('reset delays firing', () async {
      var fireCount = 0;
      final watchdog = IdleWatchdog(
        timeout: const Duration(milliseconds: 50),
        onIdle: () => fireCount++,
      );

      watchdog.start();
      await Future.delayed(const Duration(milliseconds: 30));
      watchdog.reset();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(fireCount, 0);

      await Future.delayed(const Duration(milliseconds: 40));
      expect(fireCount, 1);
    });

    test('recordEvent resets the timer', () async {
      var fired = false;
      final watchdog = IdleWatchdog(
        timeout: const Duration(milliseconds: 50),
        onIdle: () => fired = true,
      );

      watchdog.start();
      await Future.delayed(const Duration(milliseconds: 30));
      watchdog.recordEvent();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(fired, isFalse);

      await Future.delayed(const Duration(milliseconds: 40));
      expect(fired, isTrue);
    });

    test('stop prevents firing', () async {
      var fired = false;
      final watchdog = IdleWatchdog(
        timeout: const Duration(milliseconds: 50),
        onIdle: () => fired = true,
      );

      watchdog.start();
      await Future.delayed(const Duration(milliseconds: 20));
      watchdog.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(fired, isFalse);
    });

    test('stop is safe to call when not started', () {
      final watchdog = IdleWatchdog(
        timeout: const Duration(seconds: 1),
        onIdle: () {},
      );
      watchdog.stop();
    });

    test('reset is safe to call when not started', () {
      final watchdog = IdleWatchdog(
        timeout: const Duration(seconds: 1),
        onIdle: () {},
      );
      watchdog.reset();
    });
  });
}
