import 'package:cc_harness/src/provider/provider_credential.dart';
import 'package:cc_harness/src/provider/provider_generation_defaults.dart';

/// One stored credential of a provider, as exposed by `providers.list` —
/// a key or OAuth account the provider can rotate across. Never carries the
/// secret itself: [hint] is the masked tail used to tell keys apart.
class HarnessCredentialSummary {
  /// Creates a [HarnessCredentialSummary].
  const HarnessCredentialSummary({
    required this.credentialId,
    required this.method,
    required this.isActive,
    required this.removable,
    this.label,
    this.hint,
  });

  /// Rebuilds from a `providers.list` wire map.
  factory HarnessCredentialSummary.fromJson(Map<String, dynamic> json) =>
      HarnessCredentialSummary(
        credentialId: json['credential_id'] as String? ?? '',
        method: HarnessAuthMethod.values.firstWhere(
          (v) => v.name == json['method'],
          orElse: () => HarnessAuthMethod.apiKey,
        ),
        isActive: json['active'] as bool? ?? false,
        removable: json['removable'] as bool? ?? false,
        label: json['label'] as String?,
        hint: json['hint'] as String?,
      );

  /// [ProviderCredential.credentialId] — the stable per-credential address
  /// `providers.removeCredential` takes.
  final String credentialId;

  /// How this credential authenticates.
  final HarnessAuthMethod method;

  /// Whether runs start on this credential (the others are rotation fallback).
  final bool isActive;

  /// Whether the user can remove it over RPC (env-var credentials are
  /// read-only — they disappear when the variable is unset, not from the UI).
  final bool removable;

  /// The user/account label: OAuth email, account label or `env:VAR` name.
  final String? label;

  /// Masked secret tail (`…wxyz`) for telling unlabeled keys apart.
  final String? hint;

  /// Serializes to the `providers.list` wire shape.
  Map<String, dynamic> toJson() => {
    'credential_id': credentialId,
    'method': method.name,
    'active': isActive,
    'removable': removable,
    if (label != null) 'label': label,
    if (hint != null) 'hint': hint,
  };
}

/// A provider the built-in harness can run, plus its live connection state —
/// the payload of the `providers.list` RPC op that drives the settings UI.
class HarnessProviderInfo {
  /// Creates a [HarnessProviderInfo].
  const HarnessProviderInfo({
    required this.id,
    required this.displayName,
    required this.authMethods,
    required this.enabled,
    required this.hasCredential,
    this.accountLabel,
    this.baseUrl,
    this.isCustom = false,
    this.dialect,
    this.generation = const ProviderGenerationDefaults(),
    this.credentials = const [],
  });

  /// Rebuilds from a `providers.list` wire map.
  factory HarnessProviderInfo.fromJson(
    Map<String, dynamic> json,
  ) => HarnessProviderInfo(
    id: json['id'] as String? ?? '',
    displayName: json['display_name'] as String? ?? '',
    authMethods: [
      for (final m in (json['auth_methods'] as List?) ?? const [])
        HarnessAuthMethod.values.firstWhere(
          (v) => v.name == m,
          orElse: () => HarnessAuthMethod.apiKey,
        ),
    ],
    enabled: HarnessProviderEnabled.fromWire(json['enabled_via'] as String?),
    hasCredential: json['has_credential'] as bool? ?? false,
    accountLabel: json['account_label'] as String?,
    baseUrl: json['base_url'] as String?,
    isCustom: json['custom'] as bool? ?? false,
    dialect: CustomProviderDialect.fromWire(json['dialect'] as String?),
    generation: ProviderGenerationDefaults.fromJson(
      json['generation'] as Map<String, dynamic>?,
    ),
    credentials: [
      for (final c in (json['credentials'] as List?) ?? const [])
        HarnessCredentialSummary.fromJson((c as Map).cast<String, dynamic>()),
    ],
  );

  /// Provider id (e.g. `anthropic`, or `custom-<slug>` for custom providers).
  final String id;

  /// Human-readable name.
  final String displayName;

  /// Accepted auth methods, in preference order.
  final List<HarnessAuthMethod> authMethods;

  /// Why the provider is (or isn't) available.
  final HarnessProviderEnabled enabled;

  /// Whether a credential is stored for this provider (vs. env only).
  final bool hasCredential;

  /// The active account label (email for OAuth, env var name, or key hint).
  final String? accountLabel;

  /// Configured base URL (custom providers always carry one).
  final String? baseUrl;

  /// Whether this is a user-added custom provider (removable, editable
  /// base URL, optional API key).
  final bool isCustom;

  /// The wire dialect of a custom provider; null for built-ins.
  final CustomProviderDialect? dialect;

  /// The provider's configured sampling recipe and output ceiling. Empty means
  /// the endpoint's own defaults are in force.
  final ProviderGenerationDefaults generation;

  /// Every stored credential of the provider (keys and OAuth accounts), in
  /// rotation order — runs start on the active one and advance down this list
  /// when a credential is exhausted. Empty for custom providers (whose single
  /// credential IS the provider definition).
  final List<HarnessCredentialSummary> credentials;

  /// Whether the provider is usable right now.
  bool get connected => enabled != HarnessProviderEnabled.disabled;

  /// Whether the provider offers a browser OAuth login.
  bool get supportsOAuth => authMethods.contains(HarnessAuthMethod.oauth);

  /// Whether the provider accepts an API key.
  bool get supportsApiKey => authMethods.contains(HarnessAuthMethod.apiKey);

  /// Serializes to the `providers.list` wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'auth_methods': [for (final m in authMethods) m.name],
    'enabled_via': enabled.wire,
    'has_credential': hasCredential,
    if (accountLabel != null) 'account_label': accountLabel,
    if (baseUrl != null) 'base_url': baseUrl,
    if (isCustom) 'custom': true,
    if (dialect != null) 'dialect': dialect!.wire,
    if (generation.isNotEmpty) 'generation': generation.toJson(),
    if (credentials.isNotEmpty)
      'credentials': [for (final c in credentials) c.toJson()],
  };
}

/// A selectable model for the built-in adapter — the payload of the
/// `providers.listModels` RPC op. [id] is the qualified `provider/model` id
/// stored on the agent; pricing/context are joined from the provider's live
/// endpoint or the models.dev catalog.
class HarnessModelInfo {
  /// Creates a [HarnessModelInfo].
  const HarnessModelInfo({
    required this.id,
    required this.providerId,
    this.displayName,
    this.inputCostPerMTokens,
    this.outputCostPerMTokens,
    this.contextWindow,
    this.maxOutputTokens,
    this.inputModalities = const [],
    this.outputModalities = const [],
    this.hasOverride = false,
    this.manual = false,
  });

  /// Rebuilds from a `providers.listModels` wire map.
  factory HarnessModelInfo.fromJson(Map<String, dynamic> json) =>
      HarnessModelInfo(
        id: json['id'] as String? ?? '',
        providerId: json['provider_id'] as String? ?? '',
        displayName: json['display_name'] as String?,
        inputCostPerMTokens: (json['input_cost'] as num?)?.toDouble(),
        outputCostPerMTokens: (json['output_cost'] as num?)?.toDouble(),
        contextWindow: (json['context_window'] as num?)?.toInt(),
        maxOutputTokens: (json['max_output_tokens'] as num?)?.toInt(),
        inputModalities: [
          for (final v in (json['input_modalities'] as List?) ?? const [])
            if (v is String) v,
        ],
        outputModalities: [
          for (final v in (json['output_modalities'] as List?) ?? const [])
            if (v is String) v,
        ],
        hasOverride: json['has_override'] as bool? ?? false,
        manual: json['manual'] as bool? ?? false,
      );

  /// Qualified model id (`provider/model`).
  final String id;

  /// Provider id this model belongs to.
  final String providerId;

  /// Friendly name.
  final String? displayName;

  /// Input price per 1M tokens, when known.
  final double? inputCostPerMTokens;

  /// Output price per 1M tokens, when known.
  final double? outputCostPerMTokens;

  /// Context window in tokens, when known.
  final int? contextWindow;

  /// Maximum output tokens per turn, when an override states one (otherwise
  /// the client enriches from the models.dev catalog).
  final int? maxOutputTokens;

  /// Accepted input modalities (models.dev tokens), when an override states
  /// them; empty means "enrich from the catalog".
  final List<String> inputModalities;

  /// Produced output modalities, when an override states them.
  final List<String> outputModalities;

  /// Whether a stored model override shaped this entry (the settings
  /// UI marks it "edited" and offers a reset).
  final bool hasOverride;

  /// Whether the user registered this model by hand — the endpoint did not
  /// report it. Manual models are removable from the settings UI.
  final bool manual;

  /// The provider-native (bare) model id, without the `provider/` prefix.
  String get bareId =>
      id.startsWith('$providerId/') ? id.substring(providerId.length + 1) : id;

  /// Serializes to the `providers.listModels` wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'provider_id': providerId,
    if (displayName != null) 'display_name': displayName,
    if (inputCostPerMTokens != null) 'input_cost': inputCostPerMTokens,
    if (outputCostPerMTokens != null) 'output_cost': outputCostPerMTokens,
    if (contextWindow != null) 'context_window': contextWindow,
    if (maxOutputTokens != null) 'max_output_tokens': maxOutputTokens,
    if (inputModalities.isNotEmpty) 'input_modalities': inputModalities,
    if (outputModalities.isNotEmpty) 'output_modalities': outputModalities,
    if (hasOverride) 'has_override': true,
    if (manual) 'manual': true,
  };
}

/// The result of starting a browser OAuth login (`providers.startOAuth`).
class HarnessOAuthStart {
  /// Creates a [HarnessOAuthStart].
  const HarnessOAuthStart({
    required this.flowId,
    required this.authUrl,
    this.supportsManualPaste = true,
    this.userCode,
  });

  /// Rebuilds from the RPC wire map.
  factory HarnessOAuthStart.fromJson(Map<String, dynamic> json) =>
      HarnessOAuthStart(
        flowId: json['flow_id'] as String? ?? '',
        authUrl: json['auth_url'] as String? ?? '',
        supportsManualPaste: json['manual_paste'] as bool? ?? true,
        userCode: json['user_code'] as String?,
      );

  /// Opaque flow id used to poll / complete / cancel.
  final String flowId;

  /// Authorization URL the client opens in a browser / new tab.
  final String authUrl;

  /// Whether a pasted code can complete the flow (web / remote fallback).
  final bool supportsManualPaste;

  /// The code the user confirms in the browser, for device-code logins
  /// (RFC 8628). Null for redirect-based flows. [authUrl] already carries it as
  /// a query parameter, but the page asks the user to verify it by eye — that
  /// check is the flow's only defence against authorizing someone else's login,
  /// so the code has to be visible in the app, not just in the link.
  final String? userCode;

  /// Whether this is a device-code login: the user reads a code out of the app
  /// rather than being redirected back to it.
  bool get isDeviceCode => userCode != null;
}

/// The state of an in-progress OAuth login.
enum HarnessOAuthState {
  /// Awaiting the user's browser authorization.
  pending,

  /// Tokens exchanged and stored.
  completed,

  /// The flow failed or was cancelled.
  error;

  /// Parses a wire name, defaulting to [pending].
  static HarnessOAuthState fromWire(String? raw) =>
      HarnessOAuthState.values.firstWhere(
        (v) => v.name == raw,
        orElse: () => HarnessOAuthState.pending,
      );
}

/// A poll result for an OAuth login (`providers.oauthStatus`).
class HarnessOAuthStatus {
  /// Creates a [HarnessOAuthStatus].
  const HarnessOAuthStatus({required this.state, this.account, this.error});

  /// Rebuilds from the RPC wire map.
  factory HarnessOAuthStatus.fromJson(Map<String, dynamic> json) =>
      HarnessOAuthStatus(
        state: HarnessOAuthState.fromWire(json['status'] as String?),
        account: json['account'] as String?,
        error: json['error'] as String?,
      );

  /// Current flow state.
  final HarnessOAuthState state;

  /// The connected account (email), once completed.
  final String? account;

  /// Failure message, when [state] is [HarnessOAuthState.error].
  final String? error;
}
