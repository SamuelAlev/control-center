import 'package:cc_domain/features/messaging/domain/services/peer_delegation_guards.dart';
import 'package:test/test.dart';

/// PRD 22 §3: the pure, deterministic delegation/peer-messaging guards. Every
/// guard refuses loudly with a named reason (never a silent no-op) and is
/// enforced at a chokepoint rather than by prompt instruction.
void main() {
  group('DelegationGuards.checkDepth', () {
    test('allows hops up to the default cap of 3', () {
      const guards = DelegationGuards();
      for (var depth = 0; depth <= 2; depth++) {
        expect(
          guards.checkDepth(depth).allowed,
          isTrue,
          reason: 'depth $depth (next ${depth + 1}) should be within the cap',
        );
      }
    });

    test('denies a hop that would exceed the cap (depth 4)', () {
      const guards = DelegationGuards();
      final result = guards.checkDepth(3);
      expect(result.allowed, isFalse);
      expect(result.refusal, isNotNull);
      expect(result.refusal, contains('depth'));
      expect(result.refusal, contains('cap'));
    });

    test('honours a custom maxDepth', () {
      const guards = DelegationGuards(maxDepth: 1);
      expect(guards.checkDepth(0).allowed, isTrue);
      final result = guards.checkDepth(1);
      expect(result.allowed, isFalse);
      expect(result.refusal, contains('cap'));
    });
  });

  group('DelegationGuards.checkCycle', () {
    test('allows a hop to an agent not already in the chain', () {
      const guards = DelegationGuards();
      expect(guards.checkCycle(['a', 'b'], 'c').allowed, isTrue);
    });

    test('denies a hop that closes a cycle and names the chain', () {
      const guards = DelegationGuards();
      final result = guards.checkCycle(['a', 'b'], 'a');
      expect(result.allowed, isFalse);
      expect(result.refusal, isNotNull);
      expect(result.refusal, contains('a → b → a'));
    });
  });

  group('DelegationGuards.checkAutonomyCeiling', () {
    test('allows a delegate at the same level as the delegator', () {
      const guards = DelegationGuards();
      final result = guards.checkAutonomyCeiling(
        AutonomyLevel.actWithApproval,
        AutonomyLevel.actWithApproval,
      );
      expect(result.allowed, isTrue);
    });

    test('denies a delegate above the delegator ceiling', () {
      const guards = DelegationGuards();
      final result = guards.checkAutonomyCeiling(
        AutonomyLevel.actWithApproval,
        AutonomyLevel.actFreely,
      );
      expect(result.allowed, isFalse);
      expect(result.refusal, isNotNull);
    });

    test('allows a delegate below the delegator ceiling', () {
      const guards = DelegationGuards();
      final result = guards.checkAutonomyCeiling(
        AutonomyLevel.actFreely,
        AutonomyLevel.proposeOnly,
      );
      expect(result.allowed, isTrue);
    });
  });

  group('AutonomyLevel.atMost', () {
    test('is true when within the ceiling and false when above', () {
      expect(
        AutonomyLevel.actWithApproval.atMost(AutonomyLevel.actFreely),
        isTrue,
      );
      expect(
        AutonomyLevel.actFreely.atMost(AutonomyLevel.actWithApproval),
        isFalse,
      );
    });
  });

  group('AutonomyLevel.fromWire', () {
    test('round-trips known wire values', () {
      for (final level in AutonomyLevel.values) {
        expect(AutonomyLevel.fromWire(level.wire), level);
      }
    });

    test('defaults to observeOnly for an unknown value', () {
      expect(AutonomyLevel.fromWire('nonsense'), AutonomyLevel.proposeOnly);
      expect(AutonomyLevel.fromWire(''), AutonomyLevel.proposeOnly);
    });
  });

  group('DelegationGuards.checkBudgetEnvelope', () {
    test('allows a positive remaining envelope', () {
      const guards = DelegationGuards();
      expect(guards.checkBudgetEnvelope(1).allowed, isTrue);
    });

    test('denies an exhausted envelope', () {
      const guards = DelegationGuards();
      expect(guards.checkBudgetEnvelope(0).allowed, isFalse);
    });

    test('denies a negative envelope', () {
      const guards = DelegationGuards();
      final result = guards.checkBudgetEnvelope(-5);
      expect(result.allowed, isFalse);
      expect(result.refusal, isNotNull);
    });
  });

  group('DelegationGuards.evaluate', () {
    test('returns the depth denial first when depth and cycle both fail', () {
      const guards = DelegationGuards();
      final result = guards.evaluate(
        chainAgentIds: ['a', 'b', 'c', 'target'],
        chainDepth: 3,
        targetAgentId: 'a',
        delegatorAutonomy: AutonomyLevel.actFreely,
        requestedAutonomy: AutonomyLevel.actFreely,
        remainingBudgetCents: 100,
      );
      expect(result.allowed, isFalse);
      expect(result.refusal, contains('depth'));
    });

    test('returns the autonomy denial when depth and cycle pass', () {
      const guards = DelegationGuards();
      final result = guards.evaluate(
        chainAgentIds: ['a', 'b'],
        chainDepth: 1,
        targetAgentId: 'c',
        delegatorAutonomy: AutonomyLevel.actWithApproval,
        requestedAutonomy: AutonomyLevel.actFreely,
        remainingBudgetCents: 100,
      );
      expect(result.allowed, isFalse);
      expect(result.refusal, contains('ceiling'));
    });

    test('allows an all-pass request', () {
      const guards = DelegationGuards();
      final result = guards.evaluate(
        chainAgentIds: ['a', 'b'],
        chainDepth: 1,
        targetAgentId: 'c',
        delegatorAutonomy: AutonomyLevel.actFreely,
        requestedAutonomy: AutonomyLevel.actWithApproval,
        remainingBudgetCents: 100,
      );
      expect(result.allowed, isTrue);
      expect(result.refusal, isNull);
    });
  });

  group('PairRateLimiter', () {
    test('allows up to maxPerWindow attempts in one window, then refuses', () {
      final limiter = PairRateLimiter(
        maxPerWindow: 3,
        window: const Duration(minutes: 1),
      );
      final t = DateTime(2026);
      expect(limiter.tryAcquire('a', 'b', t), isTrue);
      expect(limiter.tryAcquire('a', 'b', t), isTrue);
      expect(limiter.tryAcquire('a', 'b', t), isTrue);
      expect(limiter.tryAcquire('a', 'b', t), isFalse);
    });

    test('allows again once the window has slid', () {
      final limiter = PairRateLimiter(
        maxPerWindow: 3,
        window: const Duration(minutes: 1),
      );
      final t = DateTime(2026);
      for (var i = 0; i < 3; i++) {
        expect(limiter.tryAcquire('a', 'b', t), isTrue);
      }
      expect(limiter.tryAcquire('a', 'b', t), isFalse);
      expect(
        limiter.tryAcquire('a', 'b', t.add(const Duration(seconds: 61))),
        isTrue,
      );
    });

    test('limits each ordered pair independently', () {
      final limiter = PairRateLimiter(
        maxPerWindow: 3,
        window: const Duration(minutes: 1),
      );
      final t = DateTime(2026);
      for (var i = 0; i < 3; i++) {
        expect(limiter.tryAcquire('a', 'b', t), isTrue);
      }
      expect(limiter.tryAcquire('a', 'b', t), isFalse);
      expect(limiter.tryAcquire('b', 'a', t), isTrue);
    });
  });
}
