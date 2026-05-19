import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

/// Per-provider generation defaults.
///
/// The property that matters most is that an unconfigured provider is
/// indistinguishable from before this existed: [ProviderGenerationDefaults.isEmpty]
/// must hold for a default instance and nothing may then be sent on the wire.
void main() {
  group('construction', () {
    test('a default instance is empty', () {
      const d = ProviderGenerationDefaults();
      expect(d.isEmpty, isTrue);
      expect(d.isNotEmpty, isFalse);
      expect(d.toJson(), isEmpty);
    });

    test('any single field makes it non-empty', () {
      expect(
        const ProviderGenerationDefaults(maxTokens: 2048).isNotEmpty,
        isTrue,
      );
      expect(
        const ProviderGenerationDefaults(temperature: 0.6).isNotEmpty,
        isTrue,
      );
      expect(const ProviderGenerationDefaults(topP: 0.95).isNotEmpty, isTrue);
      expect(const ProviderGenerationDefaults(topK: 20).isNotEmpty, isTrue);
    });
  });

  group('fromJson tolerance', () {
    test('round-trips a full recipe', () {
      const original = ProviderGenerationDefaults(
        maxTokens: 2048,
        temperature: 0.6,
        topP: 0.95,
        topK: 20,
      );
      expect(ProviderGenerationDefaults.fromJson(original.toJson()), original);
    });

    test('null json yields an empty instance', () {
      expect(ProviderGenerationDefaults.fromJson(null).isEmpty, isTrue);
    });

    test('out-of-range values are dropped, not thrown', () {
      // A hand-edited config file must never make a provider unusable.
      final d = ProviderGenerationDefaults.fromJson(const {
        'maxTokens': 0,
        'temperature': 9.5,
        'topP': 0,
        'topK': -3,
      });
      expect(d.isEmpty, isTrue);
    });

    test('a valid field survives alongside an invalid one', () {
      final d = ProviderGenerationDefaults.fromJson(const {
        'maxTokens': 2048,
        'topP': 12,
      });
      expect(d.maxTokens, 2048);
      expect(d.topP, isNull);
    });

    test('integer-typed doubles are accepted', () {
      final d = ProviderGenerationDefaults.fromJson(const {
        'temperature': 1,
        'topP': 1,
      });
      expect(d.temperature, 1.0);
      expect(d.topP, 1.0);
    });
  });

  group('copyWith', () {
    const base = ProviderGenerationDefaults(maxTokens: 2048, topP: 0.95);

    test('overrides only what is passed', () {
      final next = base.copyWith(maxTokens: 4096);
      expect(next.maxTokens, 4096);
      expect(next.topP, 0.95);
    });

    test('a clear flag unsets a field', () {
      // Needed because a null argument means "leave unchanged".
      expect(base.copyWith(clearTopP: true).topP, isNull);
      expect(base.copyWith(clearTopP: true).maxTokens, 2048);
    });
  });

  group('ProviderCredential integration', () {
    test('defaults to empty and is omitted from json', () {
      const cred = ProviderCredential(
        providerId: 'p',
        method: HarnessAuthMethod.none,
      );
      expect(cred.generation.isEmpty, isTrue);
      expect(cred.toJson().containsKey('generation'), isFalse);
    });

    test('survives a json round trip', () {
      const cred = ProviderCredential(
        providerId: 'custom-mtplx',
        method: HarnessAuthMethod.none,
        baseUrl: 'http://127.0.0.1:8011/v1',
        dialect: CustomProviderDialect.openai,
        generation: ProviderGenerationDefaults(
          maxTokens: 2048,
          temperature: 0.6,
          topP: 0.95,
          topK: 20,
        ),
      );
      final restored = ProviderCredential.fromJson(cred.toJson());
      expect(restored.generation, cred.generation);
      expect(restored.baseUrl, cred.baseUrl);
    });

    test('copyWith carries it', () {
      const cred = ProviderCredential(
        providerId: 'p',
        method: HarnessAuthMethod.none,
      );
      final next = cred.copyWith(
        generation: const ProviderGenerationDefaults(maxTokens: 512),
      );
      expect(next.generation.maxTokens, 512);
    });
  });

  group('HarnessProviderInfo integration', () {
    test('survives the providers.list wire round trip', () {
      const info = HarnessProviderInfo(
        id: 'custom-mtplx',
        displayName: 'MTPLX',
        authMethods: [HarnessAuthMethod.apiKey],
        enabled: HarnessProviderEnabled.custom,
        hasCredential: false,
        isCustom: true,
        dialect: CustomProviderDialect.openai,
        generation: ProviderGenerationDefaults(maxTokens: 2048, topK: 20),
      );
      final restored = HarnessProviderInfo.fromJson(info.toJson());
      expect(restored.generation.maxTokens, 2048);
      expect(restored.generation.topK, 20);
      expect(restored.generation.temperature, isNull);
    });

    test('an unconfigured provider carries no generation key', () {
      const info = HarnessProviderInfo(
        id: 'anthropic',
        displayName: 'Anthropic',
        authMethods: [HarnessAuthMethod.apiKey],
        enabled: HarnessProviderEnabled.account,
        hasCredential: true,
      );
      expect(info.toJson().containsKey('generation'), isFalse);
      expect(
        HarnessProviderInfo.fromJson(info.toJson()).generation.isEmpty,
        isTrue,
      );
    });
  });

  test('the harness fallback ceiling is the documented default', () {
    // Referenced by dispatch when a provider configures no ceiling; pinned so
    // the two do not drift apart silently.
    expect(defaultHarnessMaxTokens, 8192);
    expect(const LlmCompleteConfig().maxTokens, defaultHarnessMaxTokens);
  });
}
