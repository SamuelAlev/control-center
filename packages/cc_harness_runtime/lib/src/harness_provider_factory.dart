import 'package:cc_harness/provider.dart';
import 'package:cc_harness_runtime/src/oauth/kimi_oauth.dart';
import 'package:cc_harness_runtime/src/providers/anthropic_provider.dart';
import 'package:cc_harness_runtime/src/providers/openai_provider.dart';

/// A provider id plus its (optional) model name, parsed from a qualified model
/// string like `anthropic/claude-opus-4-8`.
class ParsedModel {
  /// Creates a [ParsedModel].
  const ParsedModel(this.providerId, this.model);

  /// Provider id (e.g. `anthropic`, `openai`, `custom-<slug>`).
  final String providerId;

  /// Model name, or null to use the provider default.
  final String? model;
}

/// Builds an [LlmProviderPort] for a provider id + model + credential.
///
/// New providers plug in here; the agent loop stays provider-agnostic:
/// Anthropic (native, API key or OAuth), OpenAI (native, API key or OAuth),
/// the OpenAI-compatible family (OpenRouter, Groq, Google Gemini compat,
/// DeepSeek, Mistral, xAI, z.ai, Kimi), plus user-defined **custom
/// providers** — any OpenAI- or Anthropic-compatible endpoint whose credential
/// carries a [ProviderCredential.dialect] and base URL (Ollama, LM Studio,
/// vLLM, private deployments, …), with an optional API key.
class HarnessProviderFactory {
  /// Creates a [HarnessProviderFactory].
  const HarnessProviderFactory();

  /// Parses a qualified model id (`provider/model`) into its parts. When no
  /// provider prefix is present, the whole string is treated as the model and
  /// the provider defaults to `anthropic`.
  ParsedModel parseModel(
    String? modelId, {
    String defaultProvider = 'anthropic',
  }) {
    if (modelId == null || modelId.isEmpty) {
      return ParsedModel(defaultProvider, null);
    }
    final slash = modelId.indexOf('/');
    if (slash == -1) {
      return ParsedModel(defaultProvider, modelId);
    }
    final provider = modelId.substring(0, slash);
    final model = modelId.substring(slash + 1);
    return ParsedModel(provider, model.isEmpty ? null : model);
  }

  /// Builds a provider for [providerId] using [credential] (its auth method,
  /// secret and optional base-URL override). A null credential builds an
  /// unauthenticated provider (valid only for local providers). Throws
  /// [UnsupportedError] for an unknown provider id.
  ///
  /// [tokenResolver] makes the bearer late-bound: an OAuth access token expires
  /// while the run that captured it is still going (a Kimi Code token lives ~15
  /// minutes), so the provider asks for the token per request instead of
  /// holding the one that was current at build time. Omit it for API keys.
  LlmProviderPort create({
    required String providerId,
    String? model,
    ProviderCredential? credential,
    ProviderTokenResolver? tokenResolver,
  }) {
    final isOAuth = credential?.method == HarnessAuthMethod.oauth;
    final apiKey = credential?.method == HarnessAuthMethod.apiKey
        ? credential?.apiKey
        : null;
    final oauthToken = isOAuth ? credential?.accessToken : null;
    final baseUrl = credential?.baseUrl;

    switch (providerId) {
      case 'anthropic':
        return AnthropicProvider(
          apiKey: apiKey,
          oauthAccessToken: oauthToken,
          tokenResolver: isOAuth ? tokenResolver : null,
          baseUrl: baseUrl ?? 'https://api.anthropic.com',
          defaultModel: model ?? 'claude-opus-4-8',
        );
      case 'openai':
        return OpenAiProvider(
          apiKey: apiKey ?? oauthToken,
          tokenResolver: isOAuth ? tokenResolver : null,
          baseUrl: baseUrl ?? 'https://api.openai.com/v1',
          defaultModel: model ?? 'gpt-4o',
          supportsReasoningEffort: true,
          supportsPromptCacheKey: true,
          extraHeaders: {
            if (isOAuth && credential?.accountId != null)
              'chatgpt-account-id': credential!.accountId!,
          },
        );
      case 'openrouter':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://openrouter.ai/api/v1',
          defaultModel: model ?? 'openai/gpt-4o',
          providerName: 'OpenRouter',
          supportsReasoningEffort: true,
          supportsPromptCacheKey: true,
        );
      case 'groq':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://api.groq.com/openai/v1',
          defaultModel: model ?? 'llama-3.3-70b-versatile',
          providerName: 'Groq',
        );
      case 'google':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl:
              baseUrl ??
              'https://generativelanguage.googleapis.com/v1beta/openai',
          defaultModel: model ?? 'gemini-3.5-flash',
          providerName: 'Google Gemini',
        );
      case 'deepseek':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://api.deepseek.com/v1',
          defaultModel: model ?? 'deepseek-chat',
          providerName: 'DeepSeek',
          extractThinkTags: true,
        );
      case 'mistral':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://api.mistral.ai/v1',
          defaultModel: model ?? 'mistral-large-latest',
          providerName: 'Mistral',
        );
      case 'xai':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://api.x.ai/v1',
          defaultModel: model ?? 'grok-2-latest',
          providerName: 'xAI',
          supportsReasoningEffort: true,
        );
      case 'zai':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://api.z.ai/api/paas/v4',
          defaultModel: model ?? 'glm-5.2',
          providerName: 'z.ai',
          extractThinkTags: true,
        );
      // The Moonshot open platform, billed per token against an API key.
      case 'moonshotai':
        return OpenAiProvider(
          apiKey: apiKey,
          baseUrl: baseUrl ?? 'https://api.moonshot.ai/v1',
          defaultModel: model ?? 'kimi-k3',
          providerName: 'Moonshot (Kimi API)',
          extractThinkTags: true,
        );
      // The Kimi Code plan. OAuth-only: the bearer is a device-grant access
      // token and Kimi ties that token to the device that requested it, so the
      // same `X-Msh-*` identity headers the login sent must ride on every API
      // call too. Serves plan-only ids (`kimi-for-coding`, `k3`) on its own
      // host and the credential's base URL is written by the OAuth flow.
      case 'kimi-code':
        return OpenAiProvider(
          apiKey: oauthToken ?? apiKey,
          tokenResolver: isOAuth ? tokenResolver : null,
          baseUrl: baseUrl ?? KimiOAuth.apiBaseUrl,
          defaultModel: model ?? 'kimi-for-coding',
          providerName: 'Kimi Code',
          extractThinkTags: true,
          extraHeaders: credential?.accountId == null
              ? const {}
              : KimiOAuth.headersFor(credential!.accountId!),
        );
      default:
        // Custom providers: the credential IS the definition — dialect +
        // base URL + optional key. No hard-coded id list to extend.
        final dialect = credential?.dialect;
        if (dialect != null && baseUrl != null && baseUrl.isNotEmpty) {
          switch (dialect) {
            case CustomProviderDialect.anthropic:
              return AnthropicProvider(
                apiKey: apiKey,
                baseUrl: baseUrl,
                defaultModel: model ?? '',
              );
            case CustomProviderDialect.openai:
              return OpenAiProvider(
                apiKey: apiKey,
                baseUrl: baseUrl,
                defaultModel: model ?? '',
                providerName: credential?.displayName ?? providerId,
                extractThinkTags: true,
              );
          }
        }
        throw UnsupportedError('Unknown harness provider: $providerId');
    }
  }
}
