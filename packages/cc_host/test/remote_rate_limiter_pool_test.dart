import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

void main() {
  group('RemoteRateLimiterPool', () {
    test('sessions of the same user share ONE budget', () {
      var now = DateTime(2026, 1, 1);
      final pool = RemoteRateLimiterPool(
        build: () => RemoteRateLimiter(
          maxCallsPerWindow: 6,
          maxMutationsPerWindow: 3,
          now: () => now,
        ),
      );

      // Three devices, one member: mutations draw from the same window.
      final desktop = pool.forUser('mia');
      final web = pool.forUser('mia');
      final phone = pool.forUser('mia');
      expect(identical(desktop, web), isTrue);
      expect(identical(web, phone), isTrue);

      expect(desktop.tryAcquire(mutating: true), isTrue);
      expect(web.tryAcquire(mutating: true), isTrue);
      expect(phone.tryAcquire(mutating: true), isTrue);
      // The budget is spent — a fourth mutation is refused on ANY device.
      expect(desktop.tryAcquire(mutating: true), isFalse);
      expect(phone.tryAcquire(mutating: true), isFalse);

      // The window slides: after it passes, the budget refills.
      now = now.add(const Duration(minutes: 2));
      expect(web.tryAcquire(mutating: true), isTrue);
    });

    test('different users never share a budget', () {
      final pool = RemoteRateLimiterPool(
        build: () =>
            RemoteRateLimiter(maxCallsPerWindow: 1, maxMutationsPerWindow: 1),
      );
      expect(pool.forUser('mia').tryAcquire(mutating: true), isTrue);
      // Mia is exhausted; Noor is untouched.
      expect(pool.forUser('mia').tryAcquire(mutating: true), isFalse);
      expect(pool.forUser('noor').tryAcquire(mutating: true), isTrue);
    });

    test('evict drops a user\'s limiter so a fresh one is built', () {
      final pool = RemoteRateLimiterPool(
        build: () =>
            RemoteRateLimiter(maxCallsPerWindow: 1, maxMutationsPerWindow: 1),
      );
      final before = pool.forUser('mia');
      expect(before.tryAcquire(mutating: false), isTrue);
      pool.evict('mia');
      final after = pool.forUser('mia');
      expect(identical(before, after), isFalse);
      expect(after.tryAcquire(mutating: false), isTrue);
    });
  });
}
