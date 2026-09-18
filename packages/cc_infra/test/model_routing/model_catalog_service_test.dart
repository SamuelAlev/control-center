import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_infra/src/model_routing/in_memory_models_dev_source.dart';
import 'package:cc_infra/src/model_routing/model_catalog_service.dart';
import 'package:test/test.dart';

Map<String, dynamic> _fixture() => {
  'anthropic': {
    'id': 'anthropic',
    'name': 'Anthropic',
    'env': ['ANTHROPIC_API_KEY'],
    'models': {
      'claude-opus-4-5': {
        'id': 'claude-opus-4-5',
        'name': 'Claude Opus 4.5',
        'limit': {'context': 200000, 'output': 64000},
        'cost': {'input': 5, 'output': 25},
      },
    },
  },
  'openai': {
    'id': 'openai',
    'name': 'OpenAI',
    'env': ['OPENAI_API_KEY'],
    'models': {
      'gpt-5': {
        'id': 'gpt-5',
        'name': 'GPT-5',
        'limit': {'context': 128000, 'output': 16384},
      },
    },
  },
};

void main() {
  group('ModelCatalogService', () {
    test('finalizes enablement + policy over the loaded catalog', () async {
      final service = ModelCatalogService(
        source: InMemoryModelsDevSource(_fixture()),
        presentEnvKeys: () => {'ANTHROPIC_API_KEY'},
      );

      // Anthropic enabled via env; OpenAI disabled (no key).
      final catalog = await service.catalog();
      expect(catalog.providerGet('anthropic')!.isEnabled, isTrue);
      expect(catalog.providerGet('openai')!.isEnabled, isFalse);

      // Policy denies anthropic → removed entirely.
      final denied = await service.catalog(
        policy: ProviderPolicyEngine.fromStatements(const [
          PolicyStatement.denyProvider('anthropic'),
        ]),
      );
      expect(denied.providerGet('anthropic'), isNull);
    });
  });
}
