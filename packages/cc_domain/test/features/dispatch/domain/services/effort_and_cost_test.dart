import 'package:cc_domain/features/dispatch/domain/services/harness_cost_calculator.dart';
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

void main() {
  group('effort mapping', () {
    test('anthropic effort maps minimal→low and clamps to xhigh', () {
      expect(anthropicEffort(ReasoningEffort.minimal), 'low');
      expect(anthropicEffort(ReasoningEffort.low), 'low');
      expect(anthropicEffort(ReasoningEffort.medium), 'medium');
      expect(anthropicEffort(ReasoningEffort.high), 'high');
      expect(anthropicEffort(ReasoningEffort.xhigh), 'xhigh');
    });

    test('openai effort collapses xhigh→high', () {
      expect(openAiEffort(ReasoningEffort.minimal), 'minimal');
      expect(openAiEffort(ReasoningEffort.xhigh), 'high');
    });
  });

  group('HarnessCostCalculator', () {
    test('prices input/output/cache tokens and rounds to cents', () {
      // $3/1M input, $15/1M output, $0.30/1M cache read, $3.75/1M cache write.
      const cost = ModelCost(
        input: 3,
        output: 15,
        cacheRead: 0.30,
        cacheWrite: 3.75,
      );
      final calc = HarnessCostCalculator((pid, m) => cost);
      final rc = calc.cost(
        providerId: 'anthropic',
        modelId: 'claude-opus-4-8',
        usage: const LlmUsage(
          inputTokens: 1000000,
          outputTokens: 1000000,
          cacheReadTokens: 1000000,
          cacheWriteTokens: 1000000,
        ),
      );
      // (3 + 15 + 0.30 + 3.75) USD = 22.05 → 2205 cents.
      expect(rc.estimatedCostCents, 2205);
      expect(rc.inputTokens, 1000000);
      expect(rc.cachedReadTokens, 1000000);
    });

    test('unpriced model yields zero cost but keeps token breakdown', () {
      final calc = HarnessCostCalculator((pid, m) => null);
      final rc = calc.cost(
        providerId: 'x',
        modelId: 'y',
        usage: const LlmUsage(inputTokens: 500, outputTokens: 200),
      );
      expect(rc.estimatedCostCents, 0);
      expect(rc.inputTokens, 500);
      expect(rc.outputTokens, 200);
    });
  });
}
