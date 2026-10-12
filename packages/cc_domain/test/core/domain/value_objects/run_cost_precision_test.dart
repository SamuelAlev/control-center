import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:test/test.dart';

/// Covers the precision-critical behaviour of [CostBasis], [RunCost] and
/// [RunUsage]: the basis merge table, wire parsing, sub-cent (micro-USD)
/// arithmetic surviving summation, and the invariants of `copyWith`.
void main() {
  // ---------------------------------------------------------------------------
  // CostBasis.merge
  // ---------------------------------------------------------------------------
  group('CostBasis.merge', () {
    // Protects: summing two figures of the same provenance keeps that
    // provenance instead of degrading it to `mixed`.
    test('equal bases stay themselves', () {
      expect(
        CostBasis.merge(CostBasis.estimated, CostBasis.estimated),
        CostBasis.estimated,
      );
      expect(
        CostBasis.merge(CostBasis.providerReported, CostBasis.providerReported),
        CostBasis.providerReported,
      );
      expect(
        CostBasis.merge(CostBasis.subscription, CostBasis.subscription),
        CostBasis.subscription,
      );
      expect(
        CostBasis.merge(CostBasis.mixed, CostBasis.mixed),
        CostBasis.mixed,
      );
    });

    test('estimated spend cannot be relabeled as reported or subscribed', () {
      const estimated = RunCost(costMicros: 3200);
      const reported = RunCost(
        estimatedCostCents: 2,
        costBasis: CostBasis.providerReported,
      );
      final combined = estimated + reported;
      expect(combined.preciseCostMicros, 23200);
      expect(combined.estimatedCostCents, 2);
      expect(combined.costBasis, CostBasis.mixed);
      expect((RunCost.zero + reported).costBasis, CostBasis.providerReported);
      expect((reported + RunCost.zero).costBasis, CostBasis.providerReported);

      const subscribed = RunUsage(
        costMicros: 3200,
        costBasis: CostBasis.subscription,
      );
      const legacyEstimated = RunUsage(estimatedCostCents: 2);
      final usage = subscribed + legacyEstimated;
      expect(usage.preciseCostMicros, 23200);
      expect(usage.estimatedCostCents, 2);
      expect(usage.costBasis, CostBasis.mixed);
      expect((RunUsage.zero + subscribed).costBasis, CostBasis.subscription);
    });

    test('unobserved spend remains unknown even when its amount is zero', () {
      const unknown = RunCost(costBasis: CostBasis.unknown);
      const known = RunCost(costMicros: 100, costBasis: CostBasis.subscription);
      for (final combined in [unknown + known, known + unknown]) {
        expect(combined.preciseCostMicros, 100);
        expect(combined.costBasis, CostBasis.unknown);
      }
      const missingUsage = RunUsage(costBasis: CostBasis.unknown);
      const reported = RunUsage(
        costMicros: 100,
        costBasis: CostBasis.providerReported,
      );
      expect((missingUsage + reported).costBasis, CostBasis.unknown);
      expect((reported + missingUsage).costBasis, CostBasis.unknown);
      expect(CostBasis.fromWire(unknown.costBasis.name), CostBasis.unknown);
    });

    // Protects: two genuinely different non-estimated bases must not promote
    // one to speak for the whole — the arithmetic is exact but the label is
    // not single-valued.
    test('providerReported plus subscription is mixed', () {
      expect(
        CostBasis.merge(CostBasis.providerReported, CostBasis.subscription),
        CostBasis.mixed,
      );
      expect(
        CostBasis.merge(CostBasis.subscription, CostBasis.providerReported),
        CostBasis.mixed,
      );
      expect(
        CostBasis.merge(CostBasis.providerReported, CostBasis.mixed),
        CostBasis.mixed,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // CostBasis.fromWire
  // ---------------------------------------------------------------------------
  group('CostBasis.fromWire', () {
    // Protects: an unreadable or absent spelling never claims a figure was
    // reported; it falls back to the most conservative basis.
    test('unknown and null spellings answer estimated', () {
      expect(CostBasis.fromWire(null), CostBasis.estimated);
      expect(CostBasis.fromWire('nonsense'), CostBasis.estimated);
      expect(CostBasis.fromWire('estimated'), CostBasis.estimated);
    });

    // Protects: both storage spellings of a provider-reported figure are read
    // back as the same basis (a round-trip cannot silently downgrade it).
    test('reads both providerReported and provider_reported', () {
      expect(
        CostBasis.fromWire('providerReported'),
        CostBasis.providerReported,
      );
      expect(
        CostBasis.fromWire('provider_reported'),
        CostBasis.providerReported,
      );
      expect(CostBasis.fromWire('subscription'), CostBasis.subscription);
      expect(CostBasis.fromWire('mixed'), CostBasis.mixed);
    });
  });

  // ---------------------------------------------------------------------------
  // RunCost sub-cent precision
  // ---------------------------------------------------------------------------
  group('RunCost sub-cent precision', () {
    // Protects: the exactness the harness fix exists for — many sub-cent calls
    // sum losslessly instead of rounding each to zero.
    test('micro-USD sums exactly and does not round to cents', () {
      final sum = const RunCost(costMicros: 7) + const RunCost(costMicros: 9);
      expect(sum.costMicros, 16);
      expect(sum.preciseCostMicros, 16);
      expect(sum.costUsd, 16 / 1000000);
    });

    // Protects: a long run of fractional calls accumulates exact micro-USD
    // rather than drifting to a whole-cent total of zero.
    test('one hundred three-micro calls total three hundred micros', () {
      var total = RunCost.zero;
      for (var i = 0; i < 100; i++) {
        total = total + const RunCost(costMicros: 3);
      }
      expect(total.costMicros, 300);
      expect(total.preciseCostMicros, 300);
    });

    // Protects: a cents-only historical row is widened, never divided, so its
    // precise figure is exact.
    test('a cents-only RunCost widens to precise micros', () {
      const centsOnly = RunCost(estimatedCostCents: 3);
      expect(centsOnly.costMicros, 0);
      expect(centsOnly.preciseCostMicros, 3 * 10000);
      expect(centsOnly.preciseCostMicros, 30000);
    });

    // Protects: when an exact figure exists it is authoritative over the
    // legacy cents projection.
    test('preciseCostMicros prefers micros when non-zero', () {
      const both = RunCost(estimatedCostCents: 999, costMicros: 7);
      expect(both.preciseCostMicros, 7);
      expect(both.costUsd, 7 / 1000000);
    });
  });

  // ---------------------------------------------------------------------------
  // RunCost basis merging
  // ---------------------------------------------------------------------------
  group('RunCost basis merges through +', () {
    // Protects: a total spanning an estimated call and a subscribed call is
    // labeled mixed, not misreported as either half.
    test('summing estimated and subscription yields mixed', () {
      const estimated = RunCost(costMicros: 5, costBasis: CostBasis.estimated);
      const subscription = RunCost(
        costMicros: 5,
        costBasis: CostBasis.subscription,
      );
      final sum = estimated + subscription;
      expect(sum.costBasis, CostBasis.mixed);
      expect(sum.costMicros, 10);
    });

    // Protects: summing like bases does not spuriously degrade to mixed.
    test('summing two estimated costs stays estimated', () {
      final sum =
          const RunCost(costMicros: 5, costBasis: CostBasis.estimated) +
          const RunCost(costMicros: 5, costBasis: CostBasis.estimated);
      expect(sum.costBasis, CostBasis.estimated);
      expect(sum.costMicros, 10);
    });
  });

  // ---------------------------------------------------------------------------
  // RunCost.copyWith
  // ---------------------------------------------------------------------------
  group('RunCost.copyWith', () {
    const base = RunCost(
      inputTokens: 1,
      outputTokens: 2,
      thoughtTokens: 3,
      cachedReadTokens: 4,
      cachedWriteTokens: 5,
      estimatedCostCents: 6,
      costMicros: 7,
      costBasis: CostBasis.providerReported,
      durationMs: 120,
      timeToFirstTokenMs: 45,
    );

    // Protects: overriding one axis leaves every other recorded figure intact.
    test('keeps every unset field', () {
      final patched = base.copyWith(costMicros: 42);
      expect(patched.costMicros, 42);
      expect(patched.estimatedCostCents, 6);
      expect(patched.inputTokens, 1);
      expect(patched.outputTokens, 2);
      expect(patched.thoughtTokens, 3);
      expect(patched.cachedReadTokens, 4);
      expect(patched.cachedWriteTokens, 5);
      expect(patched.costBasis, CostBasis.providerReported);
      expect(patched.durationMs, 120);
      expect(patched.timeToFirstTokenMs, 45);
    });

    // Protects: a copy with no overrides is the same value.
    test('no-argument copyWith is equal to the original', () {
      expect(base.copyWith(), base);
    });

    // Protects: a cost figure that was observed is never "unobserved" again —
    // passing null keeps the existing value.
    test('passing null keeps the existing figure', () {
      expect(base.copyWith(durationMs: null).durationMs, 120);
      expect(base.copyWith(timeToFirstTokenMs: null).timeToFirstTokenMs, 45);
      expect(base.copyWith(costMicros: null).costMicros, 7);
    });
  });

  // ---------------------------------------------------------------------------
  // RunUsage
  // ---------------------------------------------------------------------------
  group('RunUsage precision', () {
    // Protects: the adapter-level report merges the same exact way RunCost
    // does, so pre-aggregation never loses sub-cent cost or provenance.
    test('sums exact micro-USD cost and merges the basis', () {
      const a = RunUsage(inputTokens: 1, costMicros: 5);
      const b = RunUsage(
        inputTokens: 2,
        costMicros: 7,
        costBasis: CostBasis.subscription,
      );
      final sum = a + b;
      expect(sum.inputTokens, 3);
      expect(sum.totalTokens, 3);
      expect(sum.costMicros, 12);
      expect(sum.costBasis, CostBasis.mixed);
    });

    // Protects: converting a usage report to persisted cost carries the exact
    // figure, the basis and both latency axes.
    test('toCost forwards the precise cost, basis and latency axes', () {
      const usage = RunUsage(
        inputTokens: 4,
        costMicros: 9,
        costBasis: CostBasis.providerReported,
      );
      final cost = usage.toCost(durationMs: 120, timeToFirstTokenMs: 45);
      expect(cost.costMicros, 9);
      expect(cost.preciseCostMicros, 9);
      expect(cost.costBasis, CostBasis.providerReported);
      expect(cost.inputTokens, 4);
      expect(cost.durationMs, 120);
      expect(cost.timeToFirstTokenMs, 45);
    });
  });
}
