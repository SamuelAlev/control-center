import 'package:cc_domain/features/model_routing/domain/entities/usage.dart';
import 'package:test/test.dart';

/// Exercises usage-entity static helpers + the enum `fromRaw` parsers. These drive
/// the provider-quota UI (is a provider exhausted? how full is the window?).
void main() {
  group('UsageStatus.fromRaw', () {
    test('parses known values', () {
      expect(UsageStatus.fromRaw('ok'), UsageStatus.ok);
      expect(UsageStatus.fromRaw('warning'), UsageStatus.warning);
      expect(UsageStatus.fromRaw('exhausted'), UsageStatus.exhausted);
    });

    test('returns null for unknown', () {
      expect(UsageStatus.fromRaw('bogus'), isNull);
      expect(UsageStatus.fromRaw(null), isNull);
    });
  });

  group('UsageUnit.fromRaw', () {
    test('parses known units', () {
      expect(UsageUnit.fromRaw('percent'), UsageUnit.percent);
      expect(UsageUnit.fromRaw('tokens'), UsageUnit.tokens);
      expect(UsageUnit.fromRaw('requests'), UsageUnit.requests);
      expect(UsageUnit.fromRaw('usd'), UsageUnit.usd);
    });

    test('defaults to unknown', () {
      expect(UsageUnit.fromRaw('nope'), UsageUnit.unknown);
      expect(UsageUnit.fromRaw(null), UsageUnit.unknown);
    });
  });

  group('UsageMath.usedFraction', () {
    test('uses an explicit usedFraction when present', () {
      final f = UsageMath.usedFraction(
        const UsageLimit(
          id: 'l',
          label: 'L',
          scope: UsageScope(provider: 'p'),
          amount: UsageAmount(usedFraction: 0.5),
        ),
      );
      expect(f, 0.5);
    });

    test('computes used/limit', () {
      final f = UsageMath.usedFraction(
        const UsageLimit(
          id: 'l',
          label: 'L',
          scope: UsageScope(provider: 'p'),
          amount: UsageAmount(used: 25, limit: 100),
        ),
      );
      expect(f, 0.25);
    });

    test('computes percent unit', () {
      final f = UsageMath.usedFraction(
        const UsageLimit(
          id: 'l',
          label: 'L',
          scope: UsageScope(provider: 'p'),
          amount: UsageAmount(used: 80, unit: UsageUnit.percent),
        ),
      );
      expect(f, closeTo(0.8, 0.001));
    });

    test('derives from remainingFraction', () {
      final f = UsageMath.usedFraction(
        const UsageLimit(
          id: 'l',
          label: 'L',
          scope: UsageScope(provider: 'p'),
          amount: UsageAmount(remainingFraction: 0.7),
        ),
      );
      expect(f, closeTo(0.3, 0.001));
    });

    test('clamps a negative derived fraction to 0', () {
      final f = UsageMath.usedFraction(
        const UsageLimit(
          id: 'l',
          label: 'L',
          scope: UsageScope(provider: 'p'),
          amount: UsageAmount(remainingFraction: 1.5),
        ),
      );
      expect(f, 0.0);
    });

    test('returns null when no usable fields', () {
      final f = UsageMath.usedFraction(
        const UsageLimit(
          id: 'l',
          label: 'L',
          scope: UsageScope(provider: 'p'),
          amount: UsageAmount(),
        ),
      );
      expect(f, isNull);
    });
  });

  group('UsageMath.isExhausted', () {
    UsageLimit limit(UsageAmount amount, {UsageStatus? status}) => UsageLimit(
      id: 'l',
      label: 'L',
      scope: const UsageScope(provider: 'p'),
      amount: amount,
      status: status,
    );

    test('true when status is exhausted', () {
      expect(
        UsageMath.isExhausted(
          limit(const UsageAmount(), status: UsageStatus.exhausted),
        ),
        isTrue,
      );
    });

    test('true when remaining <= 0', () {
      expect(
        UsageMath.isExhausted(limit(const UsageAmount(remaining: 0))),
        isTrue,
      );
    });

    test('true when used >= limit', () {
      expect(
        UsageMath.isExhausted(limit(const UsageAmount(used: 100, limit: 100))),
        isTrue,
      );
    });

    test('true when fraction >= 1.0', () {
      expect(
        UsageMath.isExhausted(limit(const UsageAmount(usedFraction: 1.0))),
        isTrue,
      );
    });

    test('false when under the limit', () {
      expect(
        UsageMath.isExhausted(limit(const UsageAmount(used: 10, limit: 100))),
        isFalse,
      );
    });
  });

  group('UsageMath.anyExhausted', () {
    test('true when any limit is exhausted', () {
      expect(
        UsageMath.anyExhausted([
          const UsageLimit(
            id: 'a',
            label: 'A',
            scope: UsageScope(provider: 'p'),
            amount: UsageAmount(used: 1, limit: 100),
          ),
          const UsageLimit(
            id: 'b',
            label: 'B',
            scope: UsageScope(provider: 'p'),
            amount: UsageAmount(),
            status: UsageStatus.exhausted,
          ),
        ]),
        isTrue,
      );
    });

    test('false when none exhausted', () {
      expect(
        UsageMath.anyExhausted([
          const UsageLimit(
            id: 'a',
            label: 'A',
            scope: UsageScope(provider: 'p'),
            amount: UsageAmount(used: 1, limit: 100),
          ),
        ]),
        isFalse,
      );
    });
  });

  group('UsageMath.earliestReset', () {
    test('returns the soonest resetsAt', () {
      final early = DateTime(2026, 1, 1);
      final late = DateTime(2026, 1, 2);
      expect(
        UsageMath.earliestReset([
          UsageLimit(
            id: 'a',
            label: 'A',
            scope: const UsageScope(provider: 'p'),
            amount: const UsageAmount(),
            window: UsageWindow(id: '5h', label: '5h', resetsAt: late),
          ),
          UsageLimit(
            id: 'b',
            label: 'B',
            scope: const UsageScope(provider: 'p'),
            amount: const UsageAmount(),
            window: UsageWindow(id: '7d', label: '7d', resetsAt: early),
          ),
        ]),
        early,
      );
    });

    test('null when no limits have a reset', () {
      expect(
        UsageMath.earliestReset([
          const UsageLimit(
            id: 'a',
            label: 'A',
            scope: UsageScope(provider: 'p'),
            amount: UsageAmount(),
          ),
        ]),
        isNull,
      );
    });
  });

  group('value equality + hashCode', () {
    test('UsageStatus.id is the name', () {
      expect(UsageStatus.ok.id, 'ok');
      expect(UsageStatus.warning.id, 'warning');
      expect(UsageStatus.exhausted.id, 'exhausted');
    });

    test('UsageWindow equality + hashCode', () {
      final t = DateTime(2026, 1, 1);
      final a = UsageWindow(
        id: '5h',
        label: '5h',
        durationMs: 100,
        resetsAt: t,
      );
      final b = UsageWindow(
        id: '5h',
        label: '5h',
        durationMs: 100,
        resetsAt: t,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const UsageWindow(id: '5h', label: '5h')));
    });

    test('UsageAmount equality + hashCode by all fields', () {
      const a = UsageAmount(
        used: 1,
        limit: 2,
        remaining: 3,
        usedFraction: 0.5,
        remainingFraction: 0.5,
        unit: UsageUnit.tokens,
      );
      const b = UsageAmount(
        used: 1,
        limit: 2,
        remaining: 3,
        usedFraction: 0.5,
        remainingFraction: 0.5,
        unit: UsageUnit.tokens,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const UsageAmount(used: 99)));
    });

    test('UsageScope equality + hashCode by all fields', () {
      const a = UsageScope(
        provider: 'p',
        accountId: 'a',
        projectId: 'pr',
        orgId: 'o',
        modelId: 'm',
        tier: 't',
        shared: true,
      );
      const b = UsageScope(
        provider: 'p',
        accountId: 'a',
        projectId: 'pr',
        orgId: 'o',
        modelId: 'm',
        tier: 't',
        shared: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const UsageScope(provider: 'other')));
    });

    test('UsageLimit equality + hashCode including notes', () {
      final t = DateTime(2026, 1, 1);
      final a = UsageLimit(
        id: 'l',
        label: 'L',
        scope: const UsageScope(provider: 'p'),
        amount: const UsageAmount(used: 1),
        window: UsageWindow(id: '5h', label: '5h', resetsAt: t),
        status: UsageStatus.warning,
        notes: const ['n1', 'n2'],
      );
      final b = UsageLimit(
        id: 'l',
        label: 'L',
        scope: const UsageScope(provider: 'p'),
        amount: const UsageAmount(used: 1),
        window: UsageWindow(id: '5h', label: '5h', resetsAt: t),
        status: UsageStatus.warning,
        notes: const ['n1', 'n2'],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      // notes order matters
      expect(
        a,
        isNot(
          const UsageLimit(
            id: 'l',
            label: 'L',
            scope: UsageScope(provider: 'p'),
            amount: UsageAmount(used: 1),
            notes: ['n2', 'n1'],
          ),
        ),
      );
    });
  });
}
