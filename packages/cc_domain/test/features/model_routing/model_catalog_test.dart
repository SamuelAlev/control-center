import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:test/test.dart';

/// A small models.dev-shaped fixture: two providers, a few models.
Map<String, dynamic> _fixture() => {
  'anthropic': {
    'id': 'anthropic',
    'name': 'Anthropic',
    'env': ['ANTHROPIC_API_KEY'],
    'doc': 'https://docs.anthropic.com',
    'models': {
      'claude-opus-4-5': {
        'id': 'claude-opus-4-5',
        'name': 'Claude Opus 4.5',
        'family': 'claude-opus',
        'reasoning': true,
        'reasoning_options': [
          {
            'type': 'effort',
            'values': ['low', 'medium', 'high'],
          },
        ],
        'tool_call': true,
        'temperature': true,
        'modalities': {
          'input': ['text', 'image', 'pdf'],
          'output': ['text'],
        },
        'limit': {'context': 200000, 'output': 64000},
        'cost': {
          'input': 5,
          'output': 25,
          'cache_read': 0.5,
          'cache_write': 6.25,
        },
        'release_date': '2025-11-24',
      },
      'claude-haiku-4-5': {
        'id': 'claude-haiku-4-5',
        'name': 'Claude Haiku 4.5',
        'family': 'claude-haiku',
        'reasoning': false,
        'tool_call': true,
        'modalities': {
          'input': ['text', 'image'],
          'output': ['text'],
        },
        'limit': {'context': 200000, 'output': 64000},
        'cost': {'input': 1, 'output': 5},
        'release_date': '2025-10-01',
      },
      'claude-2-legacy': {
        'id': 'claude-2-legacy',
        'name': 'Claude 2 (legacy)',
        'reasoning': false,
        'tool_call': false,
        'status': 'deprecated',
        'modalities': {
          'input': ['text'],
          'output': ['text'],
        },
        'limit': {'context': 100000, 'output': 4096},
        'cost': {'input': 8, 'output': 24},
        'release_date': '2023-07-01',
      },
    },
  },
  'openai': {
    'id': 'openai',
    'name': 'OpenAI',
    'env': ['OPENAI_API_KEY'],
    'models': {
      'gpt-5-nano': {
        'id': 'gpt-5-nano',
        'name': 'GPT-5 nano',
        'reasoning': false,
        'tool_call': true,
        'modalities': {
          'input': ['text', 'image'],
          'output': ['text'],
        },
        'limit': {'context': 400000, 'output': 128000},
        'cost': {'input': 0.05, 'output': 0.4},
        'release_date': '2025-08-01',
      },
      'gpt-5': {
        'id': 'gpt-5',
        'name': 'GPT-5',
        'reasoning': true,
        'tool_call': true,
        'modalities': {
          'input': ['text', 'image'],
          'output': ['text'],
        },
        'limit': {'context': 400000, 'output': 128000},
        'cost': {'input': 1.25, 'output': 10},
        'release_date': '2025-08-07',
      },
    },
  },
};

void main() {
  final clock = DateTime.utc(2025, 12, 1);

  group('ModelsDevParser', () {
    test('parses providers, models, cost, limits, modalities, thinking', () {
      final providers = ModelsDevParser.parse(_fixture());
      expect(providers.keys, containsAll(['anthropic', 'openai']));

      final opus = providers['anthropic']!.models['claude-opus-4-5']!;
      expect(opus.name, 'Claude Opus 4.5');
      expect(opus.family, 'claude-opus');
      expect(opus.reasoning, isTrue);
      expect(opus.supportsTools, isTrue);
      expect(opus.supportsImageInput, isTrue);
      expect(opus.inputModalities, contains(ModelModality.pdf));
      expect(opus.limits.context, 200000);
      expect(opus.cost!.input, 5);
      expect(opus.cost!.cacheWrite, 6.25);
      expect(opus.thinking!.efforts, [
        ReasoningEffort.low,
        ReasoningEffort.medium,
        ReasoningEffort.high,
      ]);
      expect(opus.releasedAt, DateTime.parse('2025-11-24'));
    });

    test('skips malformed entries instead of throwing', () {
      final providers = ModelsDevParser.parse({
        'broken': 'not a map',
        'ok': {
          'id': 'ok',
          'name': 'OK',
          'models': {
            'm': {'id': 'm', 'name': 'M'},
            'bad': 'nope',
          },
        },
      });
      expect(providers.keys, ['ok']);
      expect(providers['ok']!.models.keys, ['m']);
    });
  });

  group('ModelCatalog queries', () {
    final catalog = ModelCatalog.fromModelsDev(_fixture());

    test('providerGet / providerAll', () {
      expect(catalog.providerCount, 2);
      expect(catalog.providerGet('anthropic')!.name, 'Anthropic');
      expect(catalog.providerGet('nope'), isNull);
    });

    test('modelGet / resolve / wireId', () {
      expect(
        catalog.modelGet('anthropic', 'claude-opus-4-5')!.name,
        'Claude Opus 4.5',
      );
      expect(catalog.resolve('openai/gpt-5')!.id, 'gpt-5');
      expect(catalog.resolve('openai/gpt-5')!.wireId, 'gpt-5');
    });

    test(
      'resolve retries kimi-code under the models.dev kimi-for-coding id',
      () {
        final catalog = ModelCatalog.fromModelsDev({
          'kimi-for-coding': {
            'id': 'kimi-for-coding',
            'name': 'Kimi For Coding',
            'env': <String>[],
            'models': {
              'k3': {
                'id': 'k3',
                'name': 'Kimi K3',
                'modalities': {
                  'input': ['text', 'image', 'video'],
                  'output': ['text'],
                },
                'limit': {'context': 1048576, 'output': 131072},
              },
            },
          },
        });
        // Direct lookup under our harness id misses; the alias must recover
        // modalities, not just the row — otherwise the editor stays text-only.
        expect(catalog.modelGet('kimi-code', 'k3'), isNull);
        final resolved = catalog.resolve('kimi-code/k3');
        expect(resolved, isNotNull);
        expect(resolved!.id, 'k3');
        expect(resolved.limits.context, 1048576);
        expect(resolved.limits.maxOutput, 131072);
        expect(resolved.inputModalities, [
          ModelModality.text,
          ModelModality.image,
          ModelModality.video,
        ]);
      },
    );

    test('resolve retries zai under the models.dev zhipuai id', () {
      final catalog = ModelCatalog.fromModelsDev({
        'zhipuai': {
          'id': 'zhipuai',
          'name': 'Zhipu AI',
          'env': ['ZHIPU_API_KEY'],
          'models': {
            'glm-5.2': {
              'id': 'glm-5.2',
              'name': 'GLM-5.2',
              'modalities': {
                'input': ['text'],
                'output': ['text'],
              },
              'limit': {'context': 1000000, 'output': 131072},
            },
          },
        },
      });
      expect(catalog.modelGet('zai', 'glm-5.2'), isNull);
      expect(catalog.resolve('zai/glm-5.2')?.id, 'glm-5.2');
    });

    test('modelAll is sorted newest-released first', () {
      final all = catalog.modelAll();
      // Opus (2025-11-24) is the newest in the fixture.
      expect(all.first.id, 'claude-opus-4-5');
      // Deprecated legacy (2023) sorts last.
      expect(all.last.id, 'claude-2-legacy');
    });
  });

  group('finalize: enablement + policy', () {
    test('only providers with a present env key are enabled', () {
      final catalog = ModelCatalog.fromModelsDev(_fixture()).finalize(
        enablement: const ProviderEnablementChecker(
          presentEnvKeys: {'ANTHROPIC_API_KEY'},
        ).resolve,
      );
      final anthropic = catalog.providerGet('anthropic')!;
      expect(anthropic.isEnabled, isTrue);
      expect(anthropic.enablement, isA<ProviderEnabledViaEnv>());
      expect(
        (anthropic.enablement as ProviderEnabledViaEnv).name,
        'ANTHROPIC_API_KEY',
      );

      final openai = catalog.providerGet('openai')!;
      expect(openai.isEnabled, isFalse);
      expect(openai.enablement, isA<ProviderDisabled>());
      expect((openai.enablement as ProviderDisabled).missingEnv, [
        'OPENAI_API_KEY',
      ]);

      // Only enabled providers' models are available.
      final available = catalog.modelAvailable();
      expect(available.every((m) => m.providerId == 'anthropic'), isTrue);
      // Deprecated model is excluded from available.
      expect(available.any((m) => m.id == 'claude-2-legacy'), isFalse);
    });

    test('account login enables via account provenance', () {
      final catalog = ModelCatalog.fromModelsDev(_fixture()).finalize(
        enablement: const ProviderEnablementChecker(
          accountProviders: {'anthropic': 'anthropic-oauth'},
        ).resolve,
      );
      final anthropic = catalog.providerGet('anthropic')!;
      expect(anthropic.enablement, isA<ProviderEnabledViaAccount>());
    });

    test('policy deny removes a provider entirely (unselectable)', () {
      final policy = ProviderPolicyEngine.fromStatements(const [
        PolicyStatement.denyProvider('openai'),
      ]);
      final catalog = ModelCatalog.fromModelsDev(_fixture()).finalize(
        enablement: const ProviderEnablementChecker(
          presentEnvKeys: {'ANTHROPIC_API_KEY', 'OPENAI_API_KEY'},
        ).resolve,
        policy: policy,
      );
      expect(catalog.providerGet('openai'), isNull);
      expect(catalog.providerGet('anthropic'), isNotNull);
    });
  });

  group('modelDefault / modelSmall', () {
    final catalog = ModelCatalog.fromModelsDev(_fixture()).finalize(
      enablement: const ProviderEnablementChecker(
        presentEnvKeys: {'ANTHROPIC_API_KEY', 'OPENAI_API_KEY'},
      ).resolve,
    );

    test('default is the newest-released available model', () {
      expect(catalog.modelDefault()!.id, 'claude-opus-4-5');
    });

    test('pinned default is honored when available', () {
      final pinned = catalog.withDefault(ModelRef.parse('openai/gpt-5'));
      expect(pinned.modelDefault()!.id, 'gpt-5');
    });

    test('small model = cheapest recent text-capable (prefers nano/haiku)', () {
      // gpt-5-nano is both the cheapest AND a "nano" named-small model.
      final small = catalog.modelSmall(now: clock);
      expect(small!.id, 'gpt-5-nano');
    });

    test('small model scoped to a provider', () {
      final small = catalog.modelSmall(providerId: 'anthropic', now: clock);
      expect(small!.id, 'claude-haiku-4-5'); // haiku beats opus on cost
    });
  });

  group('ModelRef.parse', () {
    test('splits provider/model, preserving slashes in the model id', () {
      final ref = ModelRef.parse('openrouter/anthropic/claude-3');
      expect(ref.providerId, 'openrouter');
      expect(ref.modelId, 'anthropic/claude-3');
    });

    test('parses a variant suffix', () {
      final ref = ModelRef.parse('anthropic/claude-opus-4-5#high');
      expect(ref.providerId, 'anthropic');
      expect(ref.modelId, 'claude-opus-4-5');
      expect(ref.variant, 'high');
    });

    test('no slash → empty provider', () {
      final ref = ModelRef.parse('gpt-5');
      expect(ref.providerId, '');
      expect(ref.modelId, 'gpt-5');
    });
  });

  group('ThinkingConfig.resolve', () {
    const config = ThinkingConfig(
      efforts: [ReasoningEffort.low, ReasoningEffort.high],
      defaultLevel: ReasoningEffort.low,
    );

    test('returns the exact effort when supported', () {
      expect(config.resolve(ReasoningEffort.high), ReasoningEffort.high);
    });

    test('snaps to nearest when unsupported', () {
      // medium is between low and high; nearest by ordinal is low.
      expect(config.resolve(ReasoningEffort.medium), ReasoningEffort.low);
      // xhigh is closest to high.
      expect(config.resolve(ReasoningEffort.xhigh), ReasoningEffort.high);
    });

    test('null → default', () {
      expect(config.resolve(null), ReasoningEffort.low);
    });
  });

}
