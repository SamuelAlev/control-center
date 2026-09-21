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

/// Built-in providers keyed by id. OpenAI-compat remotes take an API key;
/// openai also supports browser OAuth; codex is Codex Responses (OAuth, optional
/// API key); cursor is OAuth (optional session token); kimi-code is OAuth-only.
/// Local/self-hosted endpoints are custom providers.
///
/// Anthropic is API-key-only (subscription via the `claude-code` adapter, not
/// Claude Code OAuth identity). Ids match models.dev where possible; aliases via
/// [HarnessProviderMeta.modelsDevProviderId]: `kimi-code` → `kimi-for-coding`,
/// `zai`/`zai-coding` → `zhipuai`.
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
  // ChatGPT Plus/Pro (and Team) via the Codex Responses backend. Same public
  // OAuth client as the Codex CLI / oh-my-pi; usage is `/wham/usage`, not a
  // CLI spawn. Catalog ids are OpenAI SKUs (`gpt-5.5`, …).
  'codex': HarnessProviderMeta(
    id: 'codex',
    displayName: 'Codex',
    authMethods: [HarnessAuthMethod.oauth, HarnessAuthMethod.apiKey],
    modelsDevProviderId: 'openai',
  ),
  // Cursor Ultra / Pro via the unofficial AgentService (HTTP/2 Connect).
  'cursor': HarnessProviderMeta(
    id: 'cursor',
    displayName: 'Cursor',
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
  // The z.ai open platform, billed per token against the account's
  // pay-as-you-go balance.
  'zai': HarnessProviderMeta(
    id: 'zai',
    displayName: 'z.ai',
    authMethods: [HarnessAuthMethod.apiKey],
    modelsDevProviderId: 'zhipuai',
  ),
  // The GLM Coding Plan: the SAME account key as `zai`, but a different host
  // that bills the subscription instead of the balance. z.ai serves the plan
  // only from `/api/coding/paas/v4`; the pay-as-you-go endpoint answers a
  // plan-only account with `429 {"code":"1113"}` ("Insufficient balance or no
  // resource package"), so the two lanes cannot share one entry. `/models`
  // is identical on both hosts and is therefore no help in telling them
  // apart — only the endpoint decides which wallet is charged.
  'zai-coding': HarnessProviderMeta(
    id: 'zai-coding',
    displayName: 'z.ai GLM Coding Plan',
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
  'codex',
  'cursor',
  'openrouter',
  'groq',
  'google',
  'deepseek',
  'mistral',
  'xai',
  'zai',
  'zai-coding',
  'moonshotai',
  'kimi-code',
];
