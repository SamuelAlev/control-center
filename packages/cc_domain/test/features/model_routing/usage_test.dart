import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

void main() {
  group('UsageMath.usedFraction precedence', () {
    test('prefers explicit usedFraction', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(usedFraction: 0.42, used: 1, limit: 1000),
      );
      expect(UsageMath.usedFraction(limit), closeTo(0.42, 0.0001));
    });

    test('falls back to used/limit', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(used: 250, limit: 1000),
      );
      expect(UsageMath.usedFraction(limit), closeTo(0.25, 0.0001));
    });

    test('handles percent unit', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(used: 80, unit: UsageUnit.percent),
      );
      expect(UsageMath.usedFraction(limit), closeTo(0.80, 0.0001));
    });

    test('derives from remainingFraction', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(remainingFraction: 0.1),
      );
      expect(UsageMath.usedFraction(limit), closeTo(0.9, 0.0001));
    });

    test('preserves overage above 1.0 (over-limit window ranks worse)', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(used: 120, limit: 100),
      );
      expect(UsageMath.usedFraction(limit), closeTo(1.2, 0.0001));
      expect(UsageMath.isExhausted(limit), isTrue);
    });
  });

  group('UsageMath.isExhausted', () {
    test('explicit exhausted status', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(usedFraction: 0.1),
        status: UsageStatus.exhausted,
      );
      expect(UsageMath.isExhausted(limit), isTrue);
    });

    test('usedFraction >= 1', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(usedFraction: 1.0),
      );
      expect(UsageMath.isExhausted(limit), isTrue);
    });

    test('remaining <= 0', () {
      const limit = UsageLimit(
        id: 'l',
        label: 'l',
        scope: UsageScope(provider: 'p'),
        amount: UsageAmount(remaining: 0, limit: 100),
      );
      expect(UsageMath.isExhausted(limit), isTrue);
    });
  });

  test('earliestReset returns the soonest window reset', () {
    final now = DateTime.utc(2025, 12, 1);
    final limits = [
      UsageLimit(
        id: 'a',
        label: 'a',
        scope: const UsageScope(provider: 'p'),
        window: UsageWindow(
          id: 'a',
          label: 'a',
          resetsAt: now.add(const Duration(hours: 5)),
        ),
        amount: const UsageAmount(usedFraction: 0.2),
      ),
      UsageLimit(
        id: 'b',
        label: 'b',
        scope: const UsageScope(provider: 'p'),
        window: UsageWindow(
          id: 'b',
          label: 'b',
          resetsAt: now.add(const Duration(minutes: 40)),
        ),
        amount: const UsageAmount(usedFraction: 0.2),
      ),
    ];
    expect(
      UsageMath.earliestReset(limits),
      now.add(const Duration(minutes: 40)),
    );
  });

  group('UsageTracker.summarize', () {
    final now = DateTime.utc(2025, 12, 8);
    final since = now.subtract(const Duration(days: 7));

    final entries = [
      UsageCostHistoryEntry(
        recordedAt: now.subtract(const Duration(days: 1)),
        provider: 'anthropic',
        accountKey: 'a@x.com',
        costUsd: 4.0,
        modelId: 'claude-opus-4-5',
      ),
      UsageCostHistoryEntry(
        recordedAt: now.subtract(const Duration(days: 2)),
        provider: 'anthropic',
        accountKey: 'a@x.com',
        costUsd: 6.0,
        modelId: 'claude-opus-4-5',
      ),
      UsageCostHistoryEntry(
        recordedAt: now.subtract(const Duration(days: 3)),
        provider: 'openai',
        accountKey: 'b@x.com',
        costUsd: 2.4,
        modelId: 'gpt-5',
      ),
      // Outside the window — excluded.
      UsageCostHistoryEntry(
        recordedAt: now.subtract(const Duration(days: 30)),
        provider: 'anthropic',
        accountKey: 'a@x.com',
        costUsd: 100.0,
      ),
    ];

    test(
      'totals spend across the window and breaks down by provider/model',
      () {
        final summary = UsageTracker.summarize(entries, since: since, now: now);
        expect(summary.totalUsd, closeTo(12.4, 0.0001));
        expect(summary.requestCount, 3);
        expect(summary.byProvider['anthropic'], closeTo(10.0, 0.0001));
        expect(summary.byProvider['openai'], closeTo(2.4, 0.0001));
        expect(
          summary.byModel['anthropic/claude-opus-4-5'],
          closeTo(10.0, 0.0001),
        );
      },
    );

    test('surfaces the nearest quota reset from live reports', () {
      final reports = [
        UsageReport(
          provider: 'anthropic',
          fetchedAt: now,
          limits: [
            UsageLimit(
              id: '5h',
              label: '5 hour',
              scope: const UsageScope(provider: 'anthropic'),
              window: UsageWindow(
                id: '5h',
                label: '5 hour',
                resetsAt: now.add(const Duration(minutes: 40)),
              ),
              amount: const UsageAmount(usedFraction: 0.6),
            ),
          ],
        ),
      ];
      final summary = UsageTracker.summarize(
        entries,
        since: since,
        now: now,
        reports: reports,
      );
      expect(summary.nextResetAt, now.add(const Duration(minutes: 40)));
    });
  });
}
