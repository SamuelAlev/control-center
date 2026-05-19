import 'package:cc_domain/features/governance/domain/services/budget_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Mid-month reference: 2026-06-15 (June has 30 days → 15 days remaining).
  final now = DateTime(2026, 6, 15, 12);

  List<SpendPoint> dailyRun(int days, int centsPerDay) => [
    for (var d = 0; d < days; d++)
      SpendPoint(
        at: now.subtract(Duration(days: d)),
        costCents: centsPerDay,
      ),
  ];

  group('forecastBudget', () {
    test('projects month-end from the last 7 days of burn', () {
      // $1/day for the 15 days elapsed this month.
      final forecast = forecastBudget(
        spend: dailyRun(15, 100),
        now: now,
        budgetCents: 5000, // $50 ceiling
      );

      // Spent so far: 15 days * 100c = 1500c.
      expect(forecast.spentCents, 1500);
      // Burn: last 7 days * 100c / 7 = 100c/day.
      expect(forecast.dailyBurnCents, 100);
      // Projected: 1500 + 100 * 15 days remaining = 3000c.
      expect(forecast.projectedMonthEndCents, 3000);
      expect(forecast.willExceed, isFalse);
    });

    test('flags an at-ceiling scope: willExceed with exhaustion == now', () {
      final forecast = forecastBudget(
        spend: [
          SpendPoint(at: _n, costCents: 1500), // June-1 lump
          ...[
            for (var d = 0; d < 7; d++)
              SpendPoint(at: now.subtract(Duration(days: d)), costCents: 500),
          ],
        ],
        now: now,
        budgetCents: 5000,
      );

      // spent = 1500 + 7*500 = 5000 (== ceiling).
      expect(forecast.spentCents, 5000);
      // Burn 500c/day → projects well past the ceiling.
      expect(forecast.willExceed, isTrue);
      // Headroom is 0 → exhaustion is "now" (already at ceiling).
      expect(forecast.projectedExhaustion, now);
    });

    test(
      'projects a FUTURE exhaustion date when burn will cross the ceiling',
      () {
        // spent = 1000 (June-1) + 7*200 = 2400; budget 5000 → headroom 2600.
        // burn = 1400/7 = 200c/day → exhaust in 2600/200 = 13 days (≈ June 28).
        final forecast = forecastBudget(
          spend: [
            SpendPoint(at: _n, costCents: 1000),
            ...[
              for (var d = 0; d < 7; d++)
                SpendPoint(at: now.subtract(Duration(days: d)), costCents: 200),
            ],
          ],
          now: now,
          budgetCents: 5000,
        );

        expect(forecast.spentCents, 2400);
        expect(forecast.dailyBurnCents, 200);
        // projected = 2400 + 200*15 = 5400 > 5000.
        expect(forecast.projectedMonthEndCents, 5400);
        expect(forecast.willExceed, isTrue);
        expect(forecast.projectedExhaustion, isNotNull);
        expect(forecast.projectedExhaustion!.isAfter(now), isTrue);
        // 13 days out → June 28 (± a day for rounding).
        expect(forecast.projectedExhaustion!.day, inInclusiveRange(27, 29));
      },
    );

    test('unlimited budget (0) never exceeds and has no exhaustion date', () {
      final forecast = forecastBudget(
        spend: dailyRun(15, 1000),
        now: now,
        budgetCents: 0,
      );
      expect(forecast.willExceed, isFalse);
      expect(forecast.projectedExhaustion, isNull);
      expect(forecast.projectedMonthEndCents, greaterThan(0));
    });

    test('no spend → zero burn, zero projection, no exhaustion', () {
      final forecast = forecastBudget(
        spend: const [],
        now: now,
        budgetCents: 5000,
      );
      expect(forecast.spentCents, 0);
      expect(forecast.dailyBurnCents, 0);
      expect(forecast.projectedMonthEndCents, 0);
      expect(forecast.willExceed, isFalse);
      expect(forecast.projectedExhaustion, isNull);
    });

    test('excludes last-month spend from the month-to-date total', () {
      final forecast = forecastBudget(
        spend: [
          // Late-May spend — before the June 1 month start.
          SpendPoint(at: DateTime(2026, 5, 28), costCents: 9999),
          // June spend.
          SpendPoint(at: DateTime(2026, 6, 10), costCents: 300),
        ],
        now: now,
        budgetCents: 5000,
      );
      expect(forecast.spentCents, 300, reason: 'May spend must not count');
    });

    test('on the last day of the month, nothing more is projected', () {
      final lastDay = DateTime(2026, 6, 30, 12);
      final forecast = forecastBudget(
        spend: [SpendPoint(at: DateTime(2026, 6, 10), costCents: 1200)],
        now: lastDay,
        budgetCents: 5000,
      );
      // 0 days remaining → projection == spent so far.
      expect(forecast.projectedMonthEndCents, forecast.spentCents);
    });
  });
}

/// A June-1 timestamp used as a "month-start lump" in some cases.
final _n = DateTime(2026, 6, 1);
