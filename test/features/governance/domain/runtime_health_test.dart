import 'package:cc_domain/features/governance/domain/value_objects/runtime_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12, 0, 0);

  group('deriveRuntimeHealth', () {
    test('null last-seen is offline (never phoned home)', () {
      expect(
        deriveRuntimeHealth(lastSeenAt: null, now: now),
        RuntimeHealth.offline,
      );
    });

    test('a fresh heartbeat is online', () {
      expect(
        deriveRuntimeHealth(
          lastSeenAt: now.subtract(const Duration(seconds: 20)),
          now: now,
        ),
        RuntimeHealth.online,
      );
    });

    test('no heartbeat for 5 min is recently_lost (acceptance)', () {
      expect(
        deriveRuntimeHealth(
          lastSeenAt: now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        RuntimeHealth.recentlyLost,
      );
    });

    test('between online window and 5 min is recently_lost', () {
      expect(
        deriveRuntimeHealth(
          lastSeenAt: now.subtract(const Duration(minutes: 3)),
          now: now,
        ),
        RuntimeHealth.recentlyLost,
      );
    });

    test('beyond 5 min but under 6 days is offline', () {
      expect(
        deriveRuntimeHealth(
          lastSeenAt: now.subtract(const Duration(hours: 2)),
          now: now,
        ),
        RuntimeHealth.offline,
      );
    });

    test('stale 6+ days is about_to_gc', () {
      expect(
        deriveRuntimeHealth(
          lastSeenAt: now.subtract(const Duration(days: 6, hours: 1)),
          now: now,
        ),
        RuntimeHealth.aboutToGc,
      );
    });
  });

  group('isReadyForGc', () {
    test('null last-seen is never GC-ready', () {
      expect(isReadyForGc(lastSeenAt: null, now: now), isFalse);
    });

    test('6 days stale is not yet GC-ready', () {
      expect(
        isReadyForGc(
          lastSeenAt: now.subtract(const Duration(days: 6)),
          now: now,
        ),
        isFalse,
      );
    });

    test('7+ days stale is GC-ready', () {
      expect(
        isReadyForGc(
          lastSeenAt: now.subtract(const Duration(days: 7, hours: 1)),
          now: now,
        ),
        isTrue,
      );
    });
  });
}
