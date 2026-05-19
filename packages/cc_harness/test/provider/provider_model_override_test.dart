import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderModelOverride', () {
    test('round-trips through JSON', () {
      const override = ProviderModelOverride(
        contextWindow: 262144,
        maxOutputTokens: 8192,
        inputModalities: ['text', 'image'],
        outputModalities: ['text'],
        manual: true,
      );
      final restored = ProviderModelOverride.fromJson(override.toJson());
      expect(restored, override);
    });

    test('empty override serializes to nothing and parses back empty', () {
      const override = ProviderModelOverride();
      expect(override.isEmpty, isTrue);
      expect(override.toJson(), isEmpty);
      expect(ProviderModelOverride.fromJson(const {}).isEmpty, isTrue);
      expect(ProviderModelOverride.fromJson(null).isEmpty, isTrue);
    });

    test('manual alone counts as content', () {
      // A hand-registered model with no metadata fields still exists as a
      // list entry — "empty" must not swallow it.
      const override = ProviderModelOverride(manual: true);
      expect(override.isEmpty, isFalse);
      expect(override.toJson(), {'manual': true});
    });

    test('fromJson drops out-of-range and unknown values', () {
      final restored = ProviderModelOverride.fromJson({
        'contextWindow': -5,
        'maxOutputTokens': 'lots',
        'inputModalities': ['text', 'hologram', 42],
        'outputModalities': ['text'],
      });
      expect(restored.contextWindow, isNull);
      expect(restored.maxOutputTokens, isNull);
      expect(restored.inputModalities, ['text']);
      expect(restored.outputModalities, ['text']);
    });

    test('toWireArgs uses the snake_case RPC keys', () {
      const override = ProviderModelOverride(
        contextWindow: 1000,
        inputModalities: ['text'],
        manual: true,
      );
      expect(override.toWireArgs(), {
        'context_window': 1000,
        'input_modalities': ['text'],
        'manual': true,
      });
    });
  });

  group('ProviderCredential model overrides', () {
    test('modelOverrides round-trip through JSON', () {
      const cred = ProviderCredential(
        providerId: 'custom-llm',
        method: HarnessAuthMethod.none,
        dialect: CustomProviderDialect.openai,
        displayName: 'My LLM',
        baseUrl: 'http://localhost:8080/v1',
        modelOverrides: {
          'llama-3': ProviderModelOverride(
            contextWindow: 131072,
            outputModalities: ['text'],
            manual: true,
          ),
        },
      );
      final restored = ProviderCredential.fromJson(cred.toJson());
      expect(restored.modelOverrides, cred.modelOverrides);
    });

    test('absent overrides parse to an empty map', () {
      final restored = ProviderCredential.fromJson({
        'providerId': 'openai',
        'method': 'apiKey',
      });
      expect(restored.modelOverrides, isEmpty);
    });

    test('copyWith replaces the override map', () {
      const cred = ProviderCredential(
        providerId: 'openai',
        method: HarnessAuthMethod.none,
        modelOverrides: {'gpt-x': ProviderModelOverride(contextWindow: 1000)},
      );
      final cleared = cred.copyWith(modelOverrides: const {});
      expect(cleared.modelOverrides, isEmpty);
      final added = cleared.copyWith(
        modelOverrides: const {
          'gpt-y': ProviderModelOverride(maxOutputTokens: 512),
        },
      );
      expect(added.modelOverrides.keys, ['gpt-y']);
    });
  });
}
