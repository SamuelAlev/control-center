import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/harness_provider_factory.dart';
import 'package:cc_harness_runtime/src/oauth/kimi_oauth.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/openai_provider.dart';
import 'package:test/test.dart';

void main() {
  const factory = HarnessProviderFactory();

  test('parseModel splits provider/model and defaults to anthropic', () {
    expect(
      factory.parseModel('anthropic/claude-opus-4-8').providerId,
      'anthropic',
    );
    expect(
      factory.parseModel('anthropic/claude-opus-4-8').model,
      'claude-opus-4-8',
    );
    expect(factory.parseModel('gpt-4o').providerId, 'anthropic');
    expect(factory.parseModel('openai/gpt-4o').providerId, 'openai');
    expect(factory.parseModel(null).providerId, 'anthropic');
  });

  test('builds every catalog provider (all runnable)', () {
    for (final id in harnessSupportedProviderIds) {
      final meta = harnessProviderMetas[id]!;
      final provider = factory.create(
        providerId: id,
        credential: ProviderCredential(
          providerId: id,
          method: meta.supportsApiKey
              ? HarnessAuthMethod.apiKey
              : HarnessAuthMethod.oauth,
          apiKey: meta.supportsApiKey ? 'k' : null,
          accessToken: meta.supportsApiKey ? null : 'tok',
        ),
      );
      expect(provider, isNotNull, reason: id);
    }
  });

  test('anthropic OAuth credential builds an Anthropic provider', () {
    final provider = factory.create(
      providerId: 'anthropic',
      credential: const ProviderCredential(
        providerId: 'anthropic',
        method: HarnessAuthMethod.oauth,
        accessToken: 'oauth-token',
      ),
    );
    expect(provider, isA<AnthropicProvider>());
    expect(provider.displayName, 'Anthropic');
  });

  test('openai-compatible providers reuse OpenAiProvider with their name', () {
    expect(factory.create(providerId: 'groq').displayName, 'Groq');
    expect(factory.create(providerId: 'deepseek'), isA<OpenAiProvider>());
  });

  test('moonshotai is the metered open platform, keyed by an API key', () {
    final provider = factory.create(
      providerId: 'moonshotai',
      credential: const ProviderCredential(
        providerId: 'moonshotai',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-k',
      ),
    );
    expect(provider, isA<OpenAiProvider>());
    expect(provider.displayName, 'Moonshot (Kimi API)');
    expect(provider.defaultModel, 'kimi-k3');
    // The id matches models.dev so the catalog can price the model.
    expect(factory.parseModel('moonshotai/kimi-k3').providerId, 'moonshotai');
  });

  group('kimi-code', () {
    const oauth = ProviderCredential(
      providerId: 'kimi-code',
      method: HarnessAuthMethod.oauth,
      accessToken: 'plan-token',
      baseUrl: KimiOAuth.apiBaseUrl,
      accountId: 'device-abc',
    );

    test('runs the plan host on the OAuth access token', () {
      final provider = factory.create(
        providerId: 'kimi-code',
        credential: oauth,
      );
      expect(provider, isA<OpenAiProvider>());
      expect(provider.displayName, 'Kimi Code');
      expect(provider.defaultModel, 'kimi-for-coding');
    });

    test('replays the device identity the token was issued to', () {
      // Kimi binds the token to the device that requested it, so the API call
      // has to send back the same device id the login did.
      final headers = KimiOAuth.headersFor('device-abc');
      expect(headers['X-Msh-Device-Id'], 'device-abc');
      expect(headers['X-Msh-Platform'], 'kimi_cli');
    });

    test('device headers stay printable ASCII', () {
      // A hostname with an accent or an emoji would otherwise fail at the
      // transport layer, taking every Kimi request with it.
      final headers = KimiOAuth.headersFor('dev-é-🙂-id');
      for (final value in headers.values) {
        expect(
          RegExp(r'^[\x20-\x7E]*$').hasMatch(value),
          isTrue,
          reason: value,
        );
      }
    });

    test('an explicit model wins over the plan default', () {
      expect(
        factory
            .create(providerId: 'kimi-code', model: 'k3', credential: oauth)
            .defaultModel,
        'k3',
      );
    });
  });

  test('custom openai-dialect credential builds an OpenAiProvider', () {
    final provider = factory.create(
      providerId: 'custom-ollama',
      credential: const ProviderCredential(
        providerId: 'custom-ollama',
        method: HarnessAuthMethod.none,
        baseUrl: 'http://localhost:11434/v1',
        dialect: CustomProviderDialect.openai,
        displayName: 'Ollama',
      ),
    );
    expect(provider, isA<OpenAiProvider>());
    expect(provider.displayName, 'Ollama');
  });

  test('custom anthropic-dialect credential builds an AnthropicProvider', () {
    final provider = factory.create(
      providerId: 'custom-proxy',
      credential: const ProviderCredential(
        providerId: 'custom-proxy',
        method: HarnessAuthMethod.apiKey,
        apiKey: 'sk-priv',
        baseUrl: 'https://llm.internal.example',
        dialect: CustomProviderDialect.anthropic,
        displayName: 'Internal proxy',
      ),
    );
    expect(provider, isA<AnthropicProvider>());
  });

  test('custom credential without a base URL still throws', () {
    expect(
      () => factory.create(
        providerId: 'custom-broken',
        credential: const ProviderCredential(
          providerId: 'custom-broken',
          method: HarnessAuthMethod.none,
          dialect: CustomProviderDialect.openai,
        ),
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('unknown provider throws', () {
    expect(
      () => factory.create(providerId: 'nope'),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
