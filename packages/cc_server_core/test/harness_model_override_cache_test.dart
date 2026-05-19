import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

/// An in-memory credential store carrying per-provider model overrides.
class _Store implements ProviderCredentialStore, CustomProviderLister {
  final Map<String, List<ProviderCredential>> credentials = {};

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      credentials[providerId]?.firstOrNull;

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async =>
      credentials[providerId] ?? const [];

  @override
  Future<List<ProviderCredential>> customProviders() async => [
    for (final creds in credentials.values)
      for (final c in creds)
        if (c.isCustomProvider) c,
  ];

  @override
  Future<void> save(ProviderCredential credential) async {
    credentials.putIfAbsent(credential.providerId, () => [])
      ..clear()
      ..add(credential);
  }

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {
    credentials.remove(providerId);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}

/// A two-provider models.dev fixture: anthropic with one model (context 200k,
/// max output 8192, text+image in / text out).
Map<String, dynamic> _fixture() => {
  'anthropic': {
    'id': 'anthropic',
    'name': 'Anthropic',
    'env': ['ANTHROPIC_API_KEY'],
    'models': {
      'claude-opus': {
        'id': 'claude-opus',
        'name': 'Claude Opus',
        'tool_call': true,
        'modalities': {
          'input': ['text', 'image'],
          'output': ['text'],
        },
        'limit': {'context': 200000, 'output': 8192},
        'cost': {'input': 5, 'output': 25},
      },
    },
  },
};

void main() {
  late _Store store;
  late HarnessModelOverrideCache cache;
  late ModelCatalog catalog;

  ModelInfo? base(String qualifiedId) => catalog.resolve(qualifiedId);

  setUp(() async {
    store = _Store();
    cache = HarnessModelOverrideCache(credentials: store);
    catalog = ModelCatalog.fromModelsDev(_fixture());
    await cache.refresh();
  });

  group('resolve', () {
    test('no override → the catalog answer passes through untouched', () {
      final resolved = cache.resolve(base, 'anthropic/claude-opus');
      expect(resolved!.limits.context, 200000);
      expect(resolved.limits.maxOutput, 8192);
      expect(resolved.inputModalities, contains(ModelModality.image));
      expect(cache.resolve(base, 'anthropic/unknown'), isNull);
    });

    test('override wins field by field, inheriting the rest', () async {
      store.credentials['anthropic'] = [
        const ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk',
          modelOverrides: {
            'claude-opus': ProviderModelOverride(
              contextWindow: 1000000,
              inputModalities: ['text'],
            ),
          },
        ),
      ];
      await cache.refreshProvider('anthropic');

      final resolved = cache.resolve(base, 'anthropic/claude-opus')!;
      // Overridden fields win…
      expect(resolved.limits.context, 1000000);
      expect(resolved.inputModalities, [ModelModality.text]);
      // …unset fields inherit the catalog values.
      expect(resolved.limits.maxOutput, 8192);
      expect(resolved.outputModalities, [ModelModality.text]);
      expect(resolved.cost!.input, 5);
    });

    test('unknown model with an override resolves from the override alone', () async {
      // Custom-provider models are never in the models.dev catalog; the
      // override is their only metadata (cost stays unknown).
      store.credentials['custom-llm'] = [
        const ProviderCredential(
          providerId: 'custom-llm',
          method: HarnessAuthMethod.none,
          dialect: CustomProviderDialect.openai,
          baseUrl: 'http://localhost:8080/v1',
          modelOverrides: {
            'llama-3': ProviderModelOverride(
              contextWindow: 131072,
              manual: true,
            ),
          },
        ),
      ];
      await cache.refresh();

      final resolved = cache.resolve(base, 'custom-llm/llama-3')!;
      expect(resolved.name, 'llama-3');
      expect(resolved.limits.context, 131072);
      expect(resolved.cost, isNull);
      expect(resolved.isTextCapable, isTrue);
    });

    test('setEntry updates the cache without a store round-trip', () {
      cache.setEntry(
        'anthropic',
        'claude-opus',
        const ProviderModelOverride(maxOutputTokens: 4096),
      );
      expect(
        cache.resolve(base, 'anthropic/claude-opus')!.limits.maxOutput,
        4096,
      );
      cache.setEntry('anthropic', 'claude-opus', null);
      expect(
        cache.resolve(base, 'anthropic/claude-opus')!.limits.maxOutput,
        8192,
      );
    });

    test('overrides merge across a rotation, first stored row winning', () async {
      store.credentials['anthropic'] = [
        const ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-1',
          modelOverrides: {
            'claude-opus': ProviderModelOverride(contextWindow: 500000),
          },
        ),
        const ProviderCredential(
          providerId: 'anthropic',
          method: HarnessAuthMethod.apiKey,
          apiKey: 'sk-2',
          modelOverrides: {
            'claude-opus': ProviderModelOverride(contextWindow: 999999),
          },
        ),
      ];
      await cache.refreshProvider('anthropic');
      expect(
        cache.resolve(base, 'anthropic/claude-opus')!.limits.context,
        500000,
      );
    });

    test('removeProvider drops its overrides', () async {
      store.credentials['custom-llm'] = [
        const ProviderCredential(
          providerId: 'custom-llm',
          method: HarnessAuthMethod.none,
          dialect: CustomProviderDialect.openai,
          modelOverrides: {'m': ProviderModelOverride(manual: true)},
        ),
      ];
      await cache.refresh();
      expect(cache.resolve(base, 'custom-llm/m'), isNotNull);
      cache.removeProvider('custom-llm');
      expect(cache.resolve(base, 'custom-llm/m'), isNull);
    });
  });
}
