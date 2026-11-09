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
    this.envKeys = const [],
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

  /// Environment variables that supply an API key for this provider, in
  /// precedence order (the env credential store reads these). Empty for a
  /// provider no env var can enable — an OAuth-only plan issues no key.
  final List<String> envKeys;

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
    envKeys: ['ANTHROPIC_API_KEY'],
  ),
  'openai': HarnessProviderMeta(
    id: 'openai',
    displayName: 'OpenAI',
    authMethods: [HarnessAuthMethod.oauth, HarnessAuthMethod.apiKey],
    envKeys: ['OPENAI_API_KEY'],
  ),
  // ChatGPT Plus/Pro (and Team) via the Codex Responses backend. Same public
  // OAuth client as the Codex CLI / oh-my-pi; usage is `/wham/usage`, not a
  // CLI spawn. Catalog ids are OpenAI SKUs (`gpt-5.5`, …).
  'codex': HarnessProviderMeta(
    id: 'codex',
    displayName: 'Codex',
    authMethods: [HarnessAuthMethod.oauth, HarnessAuthMethod.apiKey],
    modelsDevProviderId: 'openai',
    // Metered Codex Responses only; the ChatGPT subscription is OAuth-only.
    envKeys: ['OPENAI_CODEX_API_KEY'],
  ),
  // Cursor Ultra / Pro via the unofficial AgentService (HTTP/2 Connect).
  'cursor': HarnessProviderMeta(
    id: 'cursor',
    displayName: 'Cursor',
    authMethods: [HarnessAuthMethod.oauth, HarnessAuthMethod.apiKey],
    // Optional session token for headless servers; prefer the OAuth login.
    envKeys: ['CURSOR_API_KEY'],
  ),
  'openrouter': HarnessProviderMeta(
    id: 'openrouter',
    displayName: 'OpenRouter',
    authMethods: [HarnessAuthMethod.apiKey],
    envKeys: ['OPENROUTER_API_KEY'],
  ),
  'google': HarnessProviderMeta(
    id: 'google',
    displayName: 'Google Gemini',
    authMethods: [HarnessAuthMethod.apiKey],
    envKeys: ['GEMINI_API_KEY', 'GOOGLE_API_KEY'],
  ),
  'deepseek': HarnessProviderMeta(
    id: 'deepseek',
    displayName: 'DeepSeek',
    authMethods: [HarnessAuthMethod.apiKey],
    envKeys: ['DEEPSEEK_API_KEY'],
  ),
  'mistral': HarnessProviderMeta(
    id: 'mistral',
    displayName: 'Mistral',
    authMethods: [HarnessAuthMethod.apiKey],
    envKeys: ['MISTRAL_API_KEY'],
  ),
  'xai': HarnessProviderMeta(
    id: 'xai',
    displayName: 'xAI',
    authMethods: [HarnessAuthMethod.apiKey],
    envKeys: ['XAI_API_KEY'],
  ),
  // The z.ai open platform, billed per token against the account's
  // pay-as-you-go balance.
  'zai': HarnessProviderMeta(
    id: 'zai',
    displayName: 'z.ai',
    authMethods: [HarnessAuthMethod.apiKey],
    modelsDevProviderId: 'zhipuai',
    envKeys: ['ZAI_API_KEY', 'ZHIPU_API_KEY'],
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
    // The same account key as `zai`, under its own var so a headless server
    // can enable the plan lane without the pay-as-you-go one (which a
    // plan-only account cannot call — it answers 1113).
    envKeys: ['ZAI_CODING_API_KEY'],
  ),
  // The Moonshot open platform, billed per token against a `MOONSHOT_API_KEY`.
  'moonshotai': HarnessProviderMeta(
    id: 'moonshotai',
    displayName: 'Moonshot (Kimi API)',
    authMethods: [HarnessAuthMethod.apiKey],
    envKeys: ['MOONSHOT_API_KEY'],
  ),
  // The Kimi Code plan: a different host, a different account and no API key
  // to paste — the plan is only reachable through the Kimi Code OAuth device
  // login, so this is the one built-in provider that is OAuth-only.
  // No env var: the Kimi Code plan issues no API key (OAuth only).
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
  'google',
  'deepseek',
  'mistral',
  'xai',
  'zai',
  'zai-coding',
  'moonshotai',
  'kimi-code',
];
