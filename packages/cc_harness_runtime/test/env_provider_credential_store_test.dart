import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/env_provider_credential_store.dart';
import 'package:test/test.dart';

/// Exercises [EnvProviderCredentialStore] — the read-only store that resolves
/// provider API keys from environment variables. Covers: the
/// first-present-wins key lookup, the unknown-provider null and the
/// read-only save/remove unsupported errors.
void main() {
  group('EnvProviderCredentialStore — activeCredential', () {
    test('providers without a recognised env var resolve to null', () async {
      final store = EnvProviderCredentialStore(environment: const {});
      expect(await store.activeCredential('ollama'), isNull);
      expect(await store.activeCredential('anthropic'), isNull);
    });

    test(
      'returns an apiKey credential from the first present env var',
      () async {
        final store = EnvProviderCredentialStore(
          environment: const {'ANTHROPIC_API_KEY': 'sk-ant-xxx'},
        );
        final cred = await store.activeCredential('anthropic');
        expect(cred, isNotNull);
        expect(cred!.method, HarnessAuthMethod.apiKey);
        expect(cred.secret, 'sk-ant-xxx');
        expect(cred.accountLabel, 'env:ANTHROPIC_API_KEY');
      },
    );

    test('Moonshot reads MOONSHOT_API_KEY', () async {
      final store = EnvProviderCredentialStore(
        environment: const {'MOONSHOT_API_KEY': 'sk-moon'},
      );
      final cred = await store.activeCredential('moonshotai');
      expect(cred!.secret, 'sk-moon');
      expect(cred.accountLabel, 'env:MOONSHOT_API_KEY');
    });

    test('the two z.ai lanes read separate env vars', () async {
      // The same account key can be pasted into either, but a plan-only key on
      // ZAI_API_KEY reaches the pay-as-you-go host and 1113s — so provisioning
      // one lane must never switch the other on.
      final store = EnvProviderCredentialStore(
        environment: const {'ZAI_CODING_API_KEY': 'sk-plan'},
      );
      final coding = await store.activeCredential('zai-coding');
      expect(coding!.secret, 'sk-plan');
      expect(coding.accountLabel, 'env:ZAI_CODING_API_KEY');
      expect(await store.activeCredential('zai'), isNull);
    });

    test('Kimi Code has no env var — the plan issues no API key', () async {
      // It is reachable only through the OAuth device login, so there must be
      // nothing an env var could switch on.
      expect(
        EnvProviderCredentialStore.envKeys.containsKey('kimi-code'),
        isFalse,
      );
      final store = EnvProviderCredentialStore(
        environment: const {
          'KIMI_API_KEY': 'nope',
          'KIMI_CODE_API_KEY': 'nope',
        },
      );
      expect(await store.activeCredential('kimi-code'), isNull);
    });

    test(
      'honors the documented priority order (GEMINI before GOOGLE)',
      () async {
        final store = EnvProviderCredentialStore(
          environment: const {'GEMINI_API_KEY': 'gem', 'GOOGLE_API_KEY': 'goo'},
        );
        final cred = await store.activeCredential('google');
        expect(cred!.secret, 'gem');
        expect(cred.accountLabel, 'env:GEMINI_API_KEY');
      },
    );

    test(
      'falls back to the secondary key when the primary is absent',
      () async {
        final store = EnvProviderCredentialStore(
          environment: const {'GOOGLE_API_KEY': 'goo'},
        );
        final cred = await store.activeCredential('google');
        expect(cred!.secret, 'goo');
      },
    );

    test('an empty env var value is ignored', () async {
      final store = EnvProviderCredentialStore(
        environment: const {'OPENAI_API_KEY': ''},
      );
      expect(await store.activeCredential('openai'), isNull);
    });

    test('an unknown provider id returns null', () async {
      final store = EnvProviderCredentialStore(
        environment: const {'WHATEVER': 'x'},
      );
      expect(await store.activeCredential('mystery'), isNull);
    });
  });

  group('EnvProviderCredentialStore — credentialsFor', () {
    test('returns a single-element list for an enabled provider', () async {
      final store = EnvProviderCredentialStore(
        environment: const {'GROQ_API_KEY': 'gq'},
      );
      final list = await store.credentialsFor('groq');
      expect(list, hasLength(1));
      expect(list.single.secret, 'gq');
    });

    test('enumerates every set env var for multi-key rotation', () async {
      // A headless server provisioned with both Google keys rotates across
      // them exactly like stored multi-key setups.
      final store = EnvProviderCredentialStore(
        environment: const {'GEMINI_API_KEY': 'gem', 'GOOGLE_API_KEY': 'gog'},
      );
      final list = await store.credentialsFor('google');
      expect(list.map((c) => c.secret), ['gem', 'gog']);
      expect(list.map((c) => c.accountLabel), [
        'env:GEMINI_API_KEY',
        'env:GOOGLE_API_KEY',
      ]);
    });

    test('returns an empty list when no key is present', () async {
      final store = EnvProviderCredentialStore(environment: const {});
      expect(await store.credentialsFor('mistral'), isEmpty);
    });
  });

  group('EnvProviderCredentialStore — read-only writes', () {
    test('save throws UnsupportedError', () {
      final store = EnvProviderCredentialStore(environment: const {});
      expect(
        () => store.save(
          const ProviderCredential(
            providerId: 'anthropic',
            method: HarnessAuthMethod.apiKey,
            apiKey: 'x',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('remove throws UnsupportedError', () {
      final store = EnvProviderCredentialStore(environment: const {});
      expect(() => store.remove('anthropic'), throwsA(isA<UnsupportedError>()));
    });
  });
}
