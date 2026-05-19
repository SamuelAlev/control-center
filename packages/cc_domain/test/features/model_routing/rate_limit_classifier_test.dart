import 'dart:math';

import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimitClassifier.reasonFor', () {
    test('quota exhausted', () {
      expect(
        RateLimitClassifier.reasonFor(
          status: 429,
          message: 'Your quota will reset at midnight',
        ),
        RateLimitReason.quotaExhausted,
      );
      expect(
        RateLimitClassifier.reasonFor(message: 'insufficient_quota'),
        RateLimitReason.quotaExhausted,
      );
      expect(
        RateLimitClassifier.reasonFor(message: 'account rate limit exceeded'),
        RateLimitReason.quotaExhausted,
      );
    });

    test('model capacity / overload', () {
      expect(
        RateLimitClassifier.reasonFor(message: 'The model is overloaded'),
        RateLimitReason.modelCapacity,
      );
      expect(
        RateLimitClassifier.reasonFor(status: 529),
        RateLimitReason.modelCapacity,
      );
    });

    test('per-minute rate limit', () {
      expect(
        RateLimitClassifier.reasonFor(
          status: 429,
          message: 'Rate limit: 50 requests per minute',
        ),
        RateLimitReason.rateLimitExceeded,
      );
      expect(
        RateLimitClassifier.reasonFor(status: 429),
        RateLimitReason.rateLimitExceeded,
      );
    });

    test('server error', () {
      expect(
        RateLimitClassifier.reasonFor(status: 500, message: 'Internal error'),
        RateLimitReason.serverError,
      );
    });

    test('unknown when nothing matches', () {
      expect(
        RateLimitClassifier.reasonFor(message: 'something weird'),
        RateLimitReason.unknown,
      );
    });

    test('capacity wins over a generic "quota" mention (cascade order)', () {
      // A body naming both overload AND quota classifies as capacity (wait),
      // not quota (rotate) — capacity is checked before generic quota.
      expect(
        RateLimitClassifier.reasonFor(
          message: 'model overloaded; quota refreshes later',
        ),
        RateLimitReason.modelCapacity,
      );
    });

    test('generic "quota" alone is still quota (lowest-priority branch)', () {
      expect(
        RateLimitClassifier.reasonFor(message: 'quota'),
        RateLimitReason.quotaExhausted,
      );
    });
  });

  group('RateLimitClassifier.classify → strategy', () {
    test('quota → 30min + rotate', () {
      final c = RateLimitClassifier.classify(message: 'quota will reset');
      expect(c.reason, RateLimitReason.quotaExhausted);
      expect(c.baseBackoff, const Duration(minutes: 30));
      expect(c.shouldRotate, isTrue);
    });

    test('per-minute → 30s, stay', () {
      final c = RateLimitClassifier.classify(
        status: 429,
        message: 'too many requests per minute',
      );
      expect(c.baseBackoff, const Duration(seconds: 30));
      expect(c.shouldRotate, isFalse);
    });

    test('capacity → 45s + up to 30s jitter, stay', () {
      final c = RateLimitClassifier.classify(message: 'overloaded');
      expect(c.baseBackoff, const Duration(seconds: 45));
      expect(c.maxJitter, const Duration(seconds: 30));
      expect(c.shouldRotate, isFalse);
      // Effective backoff stays within [45s, 75s].
      final eff = c.effectiveBackoff(Random(1));
      expect(eff.inMilliseconds, greaterThanOrEqualTo(45000));
      expect(eff.inMilliseconds, lessThanOrEqualTo(75000));
    });

    test('server → 20s, stay', () {
      final c = RateLimitClassifier.classify(status: 503, message: '');
      // 503 classifies as capacity, not server — assert the genuine 5xx path.
      final s = RateLimitClassifier.classify(status: 500);
      expect(s.baseBackoff, const Duration(seconds: 20));
      expect(c.reason, RateLimitReason.modelCapacity);
    });
  });

  group('isUsageLimitOutcome', () {
    test('explicit usage-limit message', () {
      expect(
        RateLimitClassifier.isUsageLimitOutcome(message: 'usage limit reached'),
        isTrue,
      );
    });

    test('bare 429 with opaque body is treated as a usage limit', () {
      expect(RateLimitClassifier.isUsageLimitOutcome(status: 429), isTrue);
    });

    test(
      '429 with only HTTP framing ("Error 429") is opaque → usage limit',
      () {
        expect(
          RateLimitClassifier.isUsageLimitOutcome(
            status: 429,
            message: 'HTTP Error 429',
          ),
          isTrue,
        );
      },
    );

    test('429 explicitly per-minute is NOT a usage limit', () {
      expect(
        RateLimitClassifier.isUsageLimitOutcome(
          status: 429,
          message: 'rate limit: too many requests per minute',
        ),
        isFalse,
      );
    });
  });
}
