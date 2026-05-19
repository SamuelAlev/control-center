import 'package:cc_domain/features/ticketing/domain/services/idempotency_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdempotencyKey', () {
    test('value is pipe-separated tuple', timeout: const Timeout.factor(2), () {
      const key = IdempotencyKey(
          ticketId: 't1', agentId: 'a1', source: 'manual');
      expect(key.value, 't1|a1|manual');
    });

    test('equality based on value', timeout: const Timeout.factor(2), () {
      const a = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      const b = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(a, equals(b));
    });

    test('inequality when fields differ', timeout: const Timeout.factor(2), () {
      const base = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(
          base,
          isNot(equals(const IdempotencyKey(
              ticketId: 't2', agentId: 'a1', source: 's'))));
      expect(
          base,
          isNot(equals(const IdempotencyKey(
              ticketId: 't1', agentId: 'a2', source: 's'))));
      expect(
          base,
          isNot(equals(const IdempotencyKey(
              ticketId: 't1', agentId: 'a1', source: 'x'))));
    });

    test('hashCode consistent with equality',
        timeout: const Timeout.factor(2), () {
      const a = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      const b = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(a.hashCode, b.hashCode);
    });

    test('hashCode differs when fields differ',
        timeout: const Timeout.factor(2), () {
      const a = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      const b = IdempotencyKey(ticketId: 't2', agentId: 'a1', source: 's');
      const c = IdempotencyKey(ticketId: 't1', agentId: 'a2', source: 's');
      const d = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 'x');
      expect(a.hashCode, isNot(b.hashCode));
      expect(a.hashCode, isNot(c.hashCode));
      expect(a.hashCode, isNot(d.hashCode));
    });

    test('toString includes value', timeout: const Timeout.factor(2), () {
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(key.toString(), contains('t1|a1|s'));
    });

    test('identical instances are equal', timeout: const Timeout.factor(2), () {
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(key, equals(key));
      expect(key == key, isTrue);
    });

    test('not equal to different type', timeout: const Timeout.factor(2), () {
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(key == Object(), isFalse);
    });
  });

  group('DispatchDedupGuard', () {
    test('isDuplicate returns false for unseen key',
        timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard();
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(guard.isDuplicate(key), isFalse);
    });

    test('isDuplicate returns true after recording',
        timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard();
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      guard.record(key);
      expect(guard.isDuplicate(key), isTrue);
    });

    test('different keys are independent',
        timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard();
      const key1 = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      const key2 = IdempotencyKey(ticketId: 't2', agentId: 'a1', source: 's');
      guard.record(key1);
      expect(guard.isDuplicate(key1), isTrue);
      expect(guard.isDuplicate(key2), isFalse);
    });

    test('clear removes the record', timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard();
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      guard.record(key);
      expect(guard.isDuplicate(key), isTrue);
      guard.clear(key);
      expect(guard.isDuplicate(key), isFalse);
    });

    test('clear of unrecorded key is a no-op',
        timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard();
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      guard.clear(key);
      expect(guard.isDuplicate(key), isFalse);
    });

    test('expired entries are not duplicates',
        timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard(window: Duration.zero);
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      guard.record(key);
      // With zero-duration window, the entry is immediately expired
      expect(guard.isDuplicate(key), isFalse);
    });

    test('purge removes expired entries', timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard(window: Duration.zero);
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      guard.record(key);
      guard.purge();
      // After purge, the internal map should be empty — record again works
      guard.record(key);
      expect(guard.isDuplicate(key),
          isFalse); // zero window = immediately expired
    });

    test('non-expired entries survive purge',
        timeout: const Timeout.factor(2), () {
      final guard =
          DispatchDedupGuard(window: const Duration(hours: 1));
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      guard.record(key);
      guard.purge();
      expect(guard.isDuplicate(key), isTrue);
    });

    test('multiple keys: some purged, some survive', timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard(window: const Duration(hours: 1));
      const freshKey = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      const anotherKey = IdempotencyKey(ticketId: 't2', agentId: 'a2', source: 'x');
      guard.record(freshKey);
      guard.record(anotherKey);
      // Both are fresh, purge keeps both
      guard.purge();
      expect(guard.isDuplicate(freshKey), isTrue);
      expect(guard.isDuplicate(anotherKey), isTrue);
    });

    test('recording same key twice is idempotent',
        timeout: const Timeout.factor(2), () {
      final guard =
          DispatchDedupGuard(window: const Duration(hours: 1));
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      guard.record(key);
      guard.record(key);
      expect(guard.isDuplicate(key), isTrue);
    });

    test('purge on empty map is a no-op', timeout: const Timeout.factor(2), () {
      final guard = DispatchDedupGuard();
      guard.purge();
      const key = IdempotencyKey(ticketId: 't1', agentId: 'a1', source: 's');
      expect(guard.isDuplicate(key), isFalse);
    });

    test('does not confuse keys with unrelated string values',
        timeout: const Timeout.factor(2), () {
      final guard =
          DispatchDedupGuard(window: const Duration(hours: 1));
      const key1 = IdempotencyKey(
          ticketId: 't1', agentId: 'a1', source: 'manual');
      const key2 = IdempotencyKey(
          ticketId: 't1', agentId: 'a1', source: 'auto');
      guard.record(key1);
      expect(guard.isDuplicate(key1), isTrue);
      expect(guard.isDuplicate(key2), isFalse);
    });
  });
}
