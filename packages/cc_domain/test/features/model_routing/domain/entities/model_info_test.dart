import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

/// Exercises [ModelRef.parse], the [ModelStatus]/[ModelModality] parsers, and
/// the `qualifiedId`/`toString` forms — the model-id grammar the harness and
/// dispatch resolve through.
void main() {
  group('ModelRef.parse', () {
    test('parses provider/model', () {
      final r = ModelRef.parse('anthropic/claude-opus-4-5');
      expect(r.providerId, 'anthropic');
      expect(r.modelId, 'claude-opus-4-5');
      expect(r.variant, isNull);
    });

    test('parses a variant suffix (#)', () {
      final r = ModelRef.parse('anthropic/claude-opus-4-5#reasoning');
      expect(r.providerId, 'anthropic');
      expect(r.modelId, 'claude-opus-4-5');
      expect(r.variant, 'reasoning');
    });

    test('model id may contain slashes', () {
      final r = ModelRef.parse('openai/o3/deep');
      expect(r.providerId, 'openai');
      expect(r.modelId, 'o3/deep');
    });

    test('no slash → empty provider, whole string is the model id', () {
      final r = ModelRef.parse('local-model');
      expect(r.providerId, '');
      expect(r.modelId, 'local-model');
    });

    test('qualifiedId omits the provider when empty', () {
      expect(ModelRef.parse('local').qualifiedId, 'local');
      expect(
        ModelRef.parse('anthropic/claude').qualifiedId,
        'anthropic/claude',
      );
    });

    test('toString includes the variant when present', () {
      expect(
        ModelRef.parse('anthropic/claude#v1').toString(),
        'anthropic/claude#v1',
      );
      expect(ModelRef.parse('anthropic/claude').toString(), 'anthropic/claude');
    });

    test('equality and hashCode', () {
      expect(ModelRef.parse('a/b'), ModelRef.parse('a/b'));
      expect(
        ModelRef.parse('a/b#v1').hashCode,
        ModelRef.parse('a/b#v1').hashCode,
      );
      expect(ModelRef.parse('a/b'), isNot(ModelRef.parse('a/b#v1')));
    });
  });

  group('ModelStatus.fromRaw', () {
    test('parses known statuses', () {
      expect(ModelStatus.fromRaw('alpha'), ModelStatus.alpha);
      expect(ModelStatus.fromRaw('beta'), ModelStatus.beta);
      expect(ModelStatus.fromRaw('deprecated'), ModelStatus.deprecated);
    });

    test('defaults to active for unknown/null', () {
      expect(ModelStatus.fromRaw('bogus'), ModelStatus.active);
      expect(ModelStatus.fromRaw(null), ModelStatus.active);
    });
  });

  group('ModelModality.fromRaw', () {
    test('parses known modalities', () {
      expect(ModelModality.fromRaw('text'), ModelModality.text);
      expect(ModelModality.fromRaw('image'), ModelModality.image);
      expect(ModelModality.fromRaw('audio'), ModelModality.audio);
      expect(ModelModality.fromRaw('video'), ModelModality.video);
      expect(ModelModality.fromRaw('pdf'), ModelModality.pdf);
    });

    test('returns null for unknown', () {
      expect(ModelModality.fromRaw('hologram'), isNull);
    });
  });

  group('ModelCost', () {
    test('blended + isKnown', () {
      const c = ModelCost(input: 3, output: 5);
      expect(c.blended, 8);
      expect(c.isKnown, isTrue);
      expect(const ModelCost().isKnown, isFalse);
    });

    test('estimate sums all token rates', () {
      const c = ModelCost(
        input: 1,
        output: 2,
        cacheRead: 0.5,
        cacheWrite: 0.25,
      );
      // (100*1 + 50*2 + 10*0.5 + 4*0.25)/1e6
      expect(
        c.estimate(
          inputTokens: 100,
          outputTokens: 50,
          cacheReadTokens: 10,
          cacheWriteTokens: 4,
        ),
        closeTo((100 + 100 + 5 + 1) / 1000000, 1e-12),
      );
    });

    test('equality + hashCode by all fields', () {
      const a = ModelCost(input: 1, output: 2, cacheRead: 3, cacheWrite: 4);
      const b = ModelCost(input: 1, output: 2, cacheRead: 3, cacheWrite: 4);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ModelCost(input: 9)));
    });
  });

  group('ModelLimits', () {
    test('equality + hashCode', () {
      const a = ModelLimits(context: 100, maxInput: 50, maxOutput: 25);
      const b = ModelLimits(context: 100, maxInput: 50, maxOutput: 25);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ModelLimits(context: 101)));
    });
  });

  group('ThinkingConfig', () {
    test('isReasoning reflects efforts', () {
      expect(const ThinkingConfig().isReasoning, isFalse);
      expect(
        const ThinkingConfig(efforts: [ReasoningEffort.low]).isReasoning,
        isTrue,
      );
    });

    test('resolve: empty efforts → null', () {
      expect(const ThinkingConfig().resolve(ReasoningEffort.high), isNull);
    });

    test('resolve: null requested → defaultLevel then first', () {
      expect(
        const ThinkingConfig(
          efforts: [ReasoningEffort.low, ReasoningEffort.high],
          defaultLevel: ReasoningEffort.high,
        ).resolve(null),
        ReasoningEffort.high,
      );
      expect(
        const ThinkingConfig(efforts: [ReasoningEffort.low]).resolve(null),
        ReasoningEffort.low,
      );
    });

    test('resolve: supported requested → returned as-is', () {
      expect(
        const ThinkingConfig(
          efforts: [ReasoningEffort.low, ReasoningEffort.high],
        ).resolve(ReasoningEffort.high),
        ReasoningEffort.high,
      );
    });

    test('resolve: unsupported requested → nearest by ordinal', () {
      // requested xhigh (index 4); efforts are low(1)+medium(2) → nearest medium.
      expect(
        const ThinkingConfig(
          efforts: [ReasoningEffort.low, ReasoningEffort.medium],
        ).resolve(ReasoningEffort.xhigh),
        ReasoningEffort.medium,
      );
    });

    test('equality + hashCode by all fields', () {
      const a = ThinkingConfig(
        efforts: [ReasoningEffort.low, ReasoningEffort.high],
        defaultLevel: ReasoningEffort.high,
        effortRouting: {ReasoningEffort.high: 'big-model'},
        effortBudgets: {ReasoningEffort.high: 4096},
        requiresEffort: true,
      );
      const b = ThinkingConfig(
        efforts: [ReasoningEffort.low, ReasoningEffort.high],
        defaultLevel: ReasoningEffort.high,
        effortRouting: {ReasoningEffort.high: 'big-model'},
        effortBudgets: {ReasoningEffort.high: 4096},
        requiresEffort: true,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ThinkingConfig(requiresEffort: false)));
    });
  });

  group('ModelVariant', () {
    test('equality + hashCode by id/label/headers/body', () {
      const a = ModelVariant(
        id: 'high',
        label: 'High',
        headers: {'x': 'y'},
        body: {'k': 'v'},
      );
      const b = ModelVariant(
        id: 'high',
        label: 'High',
        headers: {'x': 'y'},
        body: {'k': 'v'},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ModelVariant(id: 'low')));
    });
  });

  group('ModelInfo', () {
    ModelInfo build() => const ModelInfo(
      id: 'opus',
      providerId: 'anthropic',
      name: 'Claude Opus',
      requestModelId: 'opus-v1',
      family: 'claude-opus',
      reasoning: true,
      supportsTools: true,
      supportsTemperature: true,
      inputModalities: [ModelModality.text, ModelModality.image],
      outputModalities: [ModelModality.text],
      cost: ModelCost(input: 1, output: 2),
      limits: ModelLimits(context: 200000, maxOutput: 8192),
      status: ModelStatus.active,
      enabled: true,
      contextPromotionTarget: 'opus-long',
      priority: 5,
      thinking: ThinkingConfig(efforts: [ReasoningEffort.low]),
      variants: [ModelVariant(id: 'high')],
    );

    test('qualifiedId + wireId + isTextCapable + supportsImageInput', () {
      final m = build();
      expect(m.qualifiedId, 'anthropic/opus');
      expect(m.wireId, 'opus-v1');
      expect(m.isTextCapable, isTrue);
      expect(m.supportsImageInput, isTrue);
      // wireId falls back to id when requestModelId is null.
      expect(const ModelInfo(id: 'x', providerId: 'p', name: 'n').wireId, 'x');
      // text-only-by-default model has no image input.
      expect(
        const ModelInfo(id: 'x', providerId: 'p', name: 'n').supportsImageInput,
        isFalse,
      );
    });

    test('variant lookup by id', () {
      expect(build().variant('high'), isNotNull);
      expect(build().variant('high')?.label, isNull);
      expect(build().variant('missing'), isNull);
    });

    test('equality + hashCode by (providerId, id) only', () {
      final a = build();
      final b = build().copyWith(enabled: false, status: ModelStatus.beta);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const ModelInfo(id: 'other', providerId: 'anthropic', name: 'n')),
      );
    });

    test('copyWith overrides only the requested fields', () {
      final m = build().copyWith(
        enabled: false,
        status: ModelStatus.deprecated,
        thinking: null,
        variants: const [ModelVariant(id: 'low')],
        contextPromotionTarget: 'other',
        priority: 1,
      );
      expect(m.enabled, isFalse);
      expect(m.status, ModelStatus.deprecated);
      // thinking: null is preserved (copyWith treats null as "no change").
      expect(m.thinking?.efforts, [ReasoningEffort.low]);
      expect(m.variants.single.id, 'low');
      expect(m.contextPromotionTarget, 'other');
      expect(m.priority, 1);
      // Untouched fields survive.
      expect(m.id, 'opus');
      expect(m.providerId, 'anthropic');
    });

    test('toString', () {
      expect(build().toString(), 'ModelInfo(anthropic/opus)');
    });
  });
}
