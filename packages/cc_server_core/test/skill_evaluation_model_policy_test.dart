import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart' show HarnessAuthMethod;
import 'package:cc_server_core/src/evals/skill_evaluation_model_policy.dart';
import 'package:test/test.dart';

Map<String, dynamic> _modelsDevTerra() => {
  'openai': {
    'id': 'openai',
    'env': ['OPENAI_API_KEY'],
    'models': {
      'gpt-5.6-terra': {
        'id': 'gpt-5.6-terra',
        'tool_call': true,
        'limit': {'context': 1050000, 'input': 922000, 'output': 128000},
        'cost': {
          'input': 2,
          'output': 12,
          'cache_read': 0.2,
          'cache_write': 2.5,
          'tiers': [
            {
              'tier': {'type': 'context', 'size': 272000},
              'input': 4,
              'output': 18,
              'cache_read': 0.4,
              'cache_write': 5,
            },
          ],
          'context_over_200k': {
            'input': 4,
            'output': 18,
            'cache_read': 0.4,
            'cache_write': 5,
          },
        },
      },
    },
  },
};

void main() {
  final catalog = ModelCatalog.fromModelsDev(
    _modelsDevTerra(),
  ).finalize(enablement: (_) => const ProviderDisabled());
  final codex = catalog.resolve('codex/gpt-5.6-terra');

  test(
    'authenticated live Codex id inherits OpenAI metadata, not API-key enablement',
    () {
      expect(codex, isNotNull);
      expect(codex!.enabled, isFalse); // OpenAI API key is deliberately absent.
      final pin = admitSkillEvaluationModel(
        providerId: 'codex',
        modelId: 'gpt-5.6-terra',
        model: codex,
        budgetMicros: 10970800,
        credentialMethod: HarnessAuthMethod.apiKey,
      );
      expect(pin['providerId'], 'codex');
      expect(pin['modelId'], 'gpt-5.6-terra');
      expect(pin['inputPrice'], 2.0);
      expect(pin['outputPrice'], 12.0);
      expect(pin['pricingPolicyVersion'], 3);
      expect(pin['maxCallMicros'], 10970800);
      expect(pin['budgetEnforcement'], 'reserved_call');
      final observed = skillEvaluationModelCostFromPin(pin);
      expect(observed.estimate(inputTokens: 1000, outputTokens: 100), 0.0032);
      expect(observed.estimate(inputTokens: 220000), 0.44);
      expect(observed.estimate(inputTokens: 272001), 1.088004);
      expect(
        () => skillEvaluationModelCostFromPin(
          {...pin}..remove('pricingPolicyVersion'),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('USD 1 Codex OAuth is a post-call usage stopping threshold', () {
    final pin = admitSkillEvaluationModel(
      providerId: 'codex',
      modelId: 'gpt-5.6-terra',
      model: codex,
      budgetMicros: 1000000,
      credentialMethod: HarnessAuthMethod.oauth,
    );
    expect(pin['budgetEnforcement'], 'stop_after_call');
    expect(pin['maxCallMicros'], isNull);
    expect(pin['inputPrice'], 2.0);
    expect(
      skillEvaluationModelCostFromPin(
        pin,
      ).estimate(inputTokens: 1000, outputTokens: 100),
      0.0032,
    );
  });

  test('Terra API-key calls cannot promise USD 1 without hard reservation', () {
    expect(
      () => admitSkillEvaluationModel(
        providerId: 'codex',
        modelId: 'gpt-5.6-terra',
        model: codex,
        budgetMicros: 1000000,
        credentialMethod: HarnessAuthMethod.apiKey,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test(
    'USD 1 admits a fully priced low-cost model within documented ceilings',
    () {
      const priced = ModelInfo(
        providerId: 'openai',
        id: 'budget-model',
        name: 'Budget model',
        supportsTools: true,
        limits: ModelLimits(context: 100000, maxOutput: 8192),
        cost: ModelCost(input: 0.2, output: 1.2),
      );
      final pin = admitSkillEvaluationModel(
        providerId: 'openai',
        modelId: 'budget-model',
        model: priced,
        budgetMicros: 1000000,
        credentialMethod: HarnessAuthMethod.apiKey,
      );
      expect(pin['maxCallMicros'], 29831);
      expect(pin['maxCallMicros'], lessThan(1000000));
    },
  );

  test(
    'missing metadata and capabilities reject, but authenticated enablement is independent',
    () {
      expect(
        () => admitSkillEvaluationModel(
          providerId: 'codex',
          modelId: 'unknown',
          model: null,
          budgetMicros: 1000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'missing catalog entry',
            contains('codex/unknown has no catalog metadata'),
          ),
        ),
      );
      // After the caller verifies a stored OpenAI account, the env-only catalog
      // flag cannot negate that credential either.
      expect(
        admitSkillEvaluationModel(
          providerId: 'openai',
          modelId: 'gpt-5.6-terra',
          model: catalog.resolve('openai/gpt-5.6-terra'),
          budgetMicros: 100000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        )['providerId'],
        'openai',
      );
      const noLimits = ModelInfo(
        providerId: 'codex',
        id: 'no-limits',
        name: 'No limits',
        supportsTools: true,
        cost: ModelCost(input: 1, output: 2),
      );
      expect(
        () => admitSkillEvaluationModel(
          providerId: 'codex',
          modelId: 'no-limits',
          model: noLimits,
          budgetMicros: 1000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'missing limits',
            contains('token limits'),
          ),
        ),
      );
      const noTools = ModelInfo(
        providerId: 'codex',
        id: 'no-tools',
        name: 'No tools',
        limits: ModelLimits(context: 1000, maxOutput: 1000),
        cost: ModelCost(input: 1, output: 2),
      );
      expect(
        () => admitSkillEvaluationModel(
          providerId: 'codex',
          modelId: 'no-tools',
          model: noTools,
          budgetMicros: 1000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'no tools',
            contains('tool-call support'),
          ),
        ),
      );
      const unknown = ModelInfo(
        providerId: 'codex',
        id: 'private',
        name: 'Private',
        supportsTools: true,
        limits: ModelLimits(context: 1000, maxOutput: 1000),
      );
      expect(
        () => admitSkillEvaluationModel(
          providerId: 'codex',
          modelId: 'private',
          model: unknown,
          budgetMicros: 100000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'unknown prices',
            contains('unknown or incomplete'),
          ),
        ),
      );
      final incomplete = ModelCatalog.fromModelsDev({
        'openai': {
          'models': {
            'incomplete': {
              'tool_call': true,
              'limit': {'context': 1000, 'output': 1000},
              'cost': {
                'input': 1,
                'output': 2,
                'tiers': [
                  {
                    'tier': {'type': 'context', 'size': 500},
                  },
                ],
              },
            },
          },
        },
      }).resolve('codex/incomplete');
      expect(
        () => admitSkillEvaluationModel(
          providerId: 'codex',
          modelId: 'incomplete',
          model: incomplete,
          budgetMicros: 1000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'incomplete tier',
            contains('incomplete published pricing'),
          ),
        ),
      );
    },
  );

  test(
    'foreign model identity cannot inherit prices under an arbitrary alias',
    () {
      expect(
        () => admitSkillEvaluationModel(
          providerId: 'deepseek',
          modelId: 'gpt-5.6-terra',
          model: codex,
          budgetMicros: 100000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'wrong metadata source',
            contains('resolved to'),
          ),
        ),
      );
      expect(
        () => admitSkillEvaluationModel(
          providerId: 'codex',
          modelId: 'codex/gpt-5.6-terra',
          model: codex,
          budgetMicros: 100000000,
          credentialMethod: HarnessAuthMethod.apiKey,
        ),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.message,
            'double-qualified model',
            contains('not the selected model'),
          ),
        ),
      );
      expect(
        ModelRef.parse('openrouter/meta-llama/Llama-3.3').modelId,
        'meta-llama/Llama-3.3',
      );
    },
  );
}
