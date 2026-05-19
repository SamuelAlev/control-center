import 'package:cc_harness/src/provider/provider_credential.dart';

/// Static metadata for a built-in provider the harness can run.
///
/// This is the single source of truth for which providers the harness supports
/// out of the box, their display names and how they authenticate. The server
/// exposes it to clients via the `providers.*` RPC ops so the UI never
/// hard-codes a provider list. User-defined **custom** providers (any OpenAI-
/// or Anthropic-compatible endpoint) are not listed here — they live in the
/// credential store as [ProviderCredential]s carrying a
/// [ProviderCredential.dialect].
class HarnessProviderMeta {
  /// Creates a [HarnessProviderMeta].
  const HarnessProviderMeta({
    required this.id,
    required this.displayName,
    required this.authMethods,
    this.modelsDevProviderId,
  });

  /// Provider id (e.g. `anthropic`, `openai`).
  final String id;

  /// Human-readable name shown in the UI.
  final String displayName;

  /// Auth methods this provider accepts, in preference order.
  final List<HarnessAuthMethod> authMethods;

  /// The id models.dev uses for this provider, when it differs from [id].
  ///
  /// Catalog lookups (`provider/model`) use this so a plan we name differently
  /// still inherits context, output ceiling and modalities. Null means [id]
  /// is already the models.dev id.
  final String? modelsDevProviderId;

  /// Id to look up in the models.dev catalog.
  String get catalogProviderId => modelsDevProviderId ?? id;

  /// Whether the provider offers a browser OAuth login.
  bool get supportsOAuth => authMethods.contains(HarnessAuthMethod.oauth);

  /// Whether the provider accepts an API key.
  bool get supportsApiKey => authMethods.contains(HarnessAuthMethod.apiKey);
}

/// All built-in providers the harness can run, keyed by id.
///
/// Remote OpenAI-compatible providers (openrouter/groq/deepseek/mistral/xai/
/// zai/moonshotai/google-compat) take an API key; openai additionally supports
/// a browser OAuth login and kimi-code is OAuth-only. Local or self-hosted
/// endpoints (Ollama, LM Studio, vLLM, private deployments, …) are added as
/// custom providers instead.
///
/// **Anthropic is API-key-only, on purpose.** Running the harness on a Claude
/// Pro/Max subscription would mean logging in through Claude Code's own OAuth
/// client and sending Claude Code's identity with every request — presenting
/// this app as Claude Code, which its terms do not allow. The subscription is
/// reachable the legitimate way instead: the `claude-code` ADAPTER, which runs
/// the real CLI under its own login.
///
/// Ids match the models.dev provider id wherever one exists (`moonshotai`, not
/// `kimi`) so a qualified `provider/model` resolves against the catalog for
/// price, context and modalities. Two exceptions keep a harness-native id
/// (OAuth, usage, the credential store) and set
/// [HarnessProviderMeta.modelsDevProviderId]:
/// `kimi-code` → `kimi-for-coding`, `zai` → `zhipuai`. Without the alias the
/// editor falls back to text-only even when the catalog lists image/video.
const Map<String, HarnessProviderMeta> harnessProviderMetas = {
  'anthropic': HarnessProviderMeta(
    id: 'anthropic',
    displayName: 'Anthropic',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  'openai': HarnessProviderMeta(
    id: 'openai',
    displayName: 'OpenAI',
    authMethods: [HarnessAuthMethod.oauth, HarnessAuthMethod.apiKey],
  ),
  'openrouter': HarnessProviderMeta(
    id: 'openrouter',
    displayName: 'OpenRouter',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  'groq': HarnessProviderMeta(
    id: 'groq',
    displayName: 'Groq',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  'google': HarnessProviderMeta(
    id: 'google',
    displayName: 'Google Gemini',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  'deepseek': HarnessProviderMeta(
    id: 'deepseek',
    displayName: 'DeepSeek',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  'mistral': HarnessProviderMeta(
    id: 'mistral',
    displayName: 'Mistral',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  'xai': HarnessProviderMeta(
    id: 'xai',
    displayName: 'xAI',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  'zai': HarnessProviderMeta(
    id: 'zai',
    displayName: 'z.ai',
    authMethods: [HarnessAuthMethod.apiKey],
    modelsDevProviderId: 'zhipuai',
  ),
  // The Moonshot open platform, billed per token against a `MOONSHOT_API_KEY`.
  'moonshotai': HarnessProviderMeta(
    id: 'moonshotai',
    displayName: 'Moonshot (Kimi API)',
    authMethods: [HarnessAuthMethod.apiKey],
  ),
  // The Kimi Code plan: a different host, a different account and no API key
  // to paste — the plan is only reachable through the Kimi Code OAuth device
  // login, so this is the one built-in provider that is OAuth-only.
  'kimi-code': HarnessProviderMeta(
    id: 'kimi-code',
    displayName: 'Kimi Code',
    authMethods: [HarnessAuthMethod.oauth],
    modelsDevProviderId: 'kimi-for-coding',
  ),
};

/// Ids of every built-in provider the harness can run, in display order.
/// Custom provider ids (`custom-*`) come from the credential store on top.
const List<String> harnessSupportedProviderIds = [
  'anthropic',
  'openai',
  'openrouter',
  'groq',
  'google',
  'deepseek',
  'mistral',
  'xai',
  'zai',
  'moonshotai',
  'kimi-code',
];
