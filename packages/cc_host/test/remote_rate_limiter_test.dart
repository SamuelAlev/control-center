import 'package:cc_host/src/policy/remote_tool_policy.dart';
import 'package:cc_host/src/session/remote_rate_limiter.dart';
import 'package:test/test.dart';

/// Guards the untrusted-phone abuse defences: the per-session rate limiter and
/// the mutating-verb classification the dispatch path (`RemoteRpcSession
/// ._toolsCall`) consults before every tool call. The dispatch path already
/// calls `rateLimiter.tryAcquire(mutating: RemoteToolPolicy.isMutating(name))`
/// unconditionally for every allowed tool, so these unit invariants are what
/// stop a NEW op from silently bypassing the guard: a mutating verb must be
/// classified as such (tighter cap) and must be in `allowed` to be reachable.
void main() {
  group('RemoteRateLimiter', () {
    test('admits up to the total cap, then rejects', () {
      final t = DateTime(2026);
      final limiter = RemoteRateLimiter(
        window: const Duration(minutes: 1),
        maxCallsPerWindow: 3,
        maxMutationsPerWindow: 10,
        now: () => t,
      );
      expect(limiter.tryAcquire(mutating: false), isTrue);
      expect(limiter.tryAcquire(mutating: false), isTrue);
      expect(limiter.tryAcquire(mutating: false), isTrue);
      expect(limiter.tryAcquire(mutating: false), isFalse);
    });

    test('mutations hit a tighter sub-cap even when total cap has room', () {
      final t = DateTime(2026);
      final limiter = RemoteRateLimiter(
        window: const Duration(minutes: 1),
        maxCallsPerWindow: 100,
        maxMutationsPerWindow: 2,
        now: () => t,
      );
      expect(limiter.tryAcquire(mutating: true), isTrue);
      expect(limiter.tryAcquire(mutating: true), isTrue);
      // Third mutation blocked despite 97 total slots free.
      expect(limiter.tryAcquire(mutating: true), isFalse);
      // A read still gets through.
      expect(limiter.tryAcquire(mutating: false), isTrue);
    });

    test('a rejected call records nothing (does not consume a slot)', () {
      var t = DateTime(2026);
      final limiter = RemoteRateLimiter(
        window: const Duration(minutes: 1),
        maxCallsPerWindow: 1,
        maxMutationsPerWindow: 1,
        now: () => t,
      );
      expect(limiter.tryAcquire(mutating: false), isTrue);
      expect(limiter.tryAcquire(mutating: false), isFalse);
      // Slot frees as the window slides; the earlier rejection didn't count.
      t = t.add(const Duration(minutes: 1, seconds: 1));
      expect(limiter.tryAcquire(mutating: false), isTrue);
    });

    test('window slides: old calls are evicted', () {
      var t = DateTime(2026);
      final limiter = RemoteRateLimiter(
        window: const Duration(seconds: 10),
        maxCallsPerWindow: 1,
        maxMutationsPerWindow: 1,
        now: () => t,
      );
      expect(limiter.tryAcquire(mutating: false), isTrue);
      expect(limiter.tryAcquire(mutating: false), isFalse);
      t = t.add(const Duration(seconds: 11));
      expect(limiter.tryAcquire(mutating: false), isTrue);
    });
  });

  group('RemoteToolPolicy classification integrity', () {
    test('every mutating verb is also in the allowed set (reachable)', () {
      for (final verb in RemoteToolPolicy.mutating) {
        expect(
          RemoteToolPolicy.allowed,
          contains(verb),
          reason: '$verb is mutating but not in allowed — unreachable',
        );
        expect(RemoteToolPolicy.isMutating(verb), isTrue);
        expect(RemoteToolPolicy.isAllowed(verb), isTrue);
      }
    });

    test('read-only and mutating sets are disjoint', () {
      final overlap = RemoteToolPolicy.readOnly.intersection(
        RemoteToolPolicy.mutating,
      );
      expect(
        overlap,
        isEmpty,
        reason: 'a verb classified both read-only and mutating: $overlap',
      );
    });

    test('allowed is exactly readOnly ∪ mutating', () {
      expect(RemoteToolPolicy.allowed, {
        ...RemoteToolPolicy.readOnly,
        ...RemoteToolPolicy.mutating,
      });
    });

    test('a tool not on the allow-list is denied and not mutating', () {
      // Sample of the high-privilege tools the policy MUST keep off the phone.
      for (final dangerous in const [
        'kill_agent',
        'hire_agent',
        'fire_agent',
        'create_workspace',
        'publish_review_to_github',
        'consult_agent',
        'start_ai_review',
      ]) {
        expect(
          RemoteToolPolicy.isAllowed(dangerous),
          isFalse,
          reason: '$dangerous must never be remote-invokable',
        );
        expect(RemoteToolPolicy.isMutating(dangerous), isFalse);
      }
    });
  });
}
