import 'package:cc_harness/context.dart';
import 'package:test/test.dart';

void main() {
  group('CompactionEconomics', () {
    test('nothing to reclaim is never a rewrite', () {
      final d = const CompactionEconomics().evaluate(reclaimedTokens: 0);
      expect(d.shouldRewrite, isFalse);
      expect(d, same(HarnessRewriteDecision.nothing));
    });

    test('a deep reclaim over many calls pays back', () {
      final d = const CompactionEconomics(
        assumedRemainingCalls: 40,
      ).evaluate(reclaimedTokens: 20000, rebuildTokens: 5000);
      expect(d.shouldRewrite, isTrue);
      expect(d.expectedSaving, greaterThan(d.expectedCost));
    });

    test('a shallow reclaim over few calls does not', () {
      final d = const CompactionEconomics(
        assumedRemainingCalls: 4,
      ).evaluate(reclaimedTokens: 500, rebuildTokens: 40000);
      expect(d.shouldRewrite, isFalse);
      expect(d.reason, contains('cost'));
    });

    test('force overrides the verdict', () {
      final d = const CompactionEconomics().evaluate(
        reclaimedTokens: 1,
        rebuildTokens: 999999,
        force: true,
      );
      expect(d.shouldRewrite, isTrue);
      expect(d.reason, contains('forced'));
    });

    test('a free cache makes a rewrite cheaper', () {
      final paid = const CompactionEconomics(
        assumedRemainingCalls: 6,
      ).evaluate(reclaimedTokens: 4000, rebuildTokens: 20000);
      final free = const CompactionEconomics(
        assumedRemainingCalls: 6,
        cache: ProviderCacheEconomics.freeCache,
      ).evaluate(reclaimedTokens: 4000, rebuildTokens: 20000);
      expect(paid.shouldRewrite, isFalse);
      expect(
        free.expectedCost,
        lessThanOrEqualTo(paid.expectedCost),
        reason: 'no write premium means less rebuild cost',
      );
    });

    test('provider families resolve to a price model', () {
      expect(
        ProviderCacheEconomics.forProvider('anthropic').cacheReadPrice,
        0.1,
      );
      expect(ProviderCacheEconomics.forProvider('openai').cacheReadPrice, 0.25);
      expect(
        ProviderCacheEconomics.forProvider(null),
        ProviderCacheEconomics.defaults,
      );
    });
  });
}
