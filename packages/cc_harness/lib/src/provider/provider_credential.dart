import 'package:cc_harness/src/provider/provider_generation_defaults.dart';

/// How a provider credential authenticates.
enum HarnessAuthMethod {
  /// A user-entered API key.
  apiKey,

  /// An OAuth access/refresh token pair (device-code flow).
  oauth,

  /// No authentication (public / local custom endpoints).
  none,
}

/// The wire dialect a user-defined custom provider speaks.
enum CustomProviderDialect {
  /// OpenAI-compatible chat completions (`/chat/completions`, `/models`) —
  /// Ollama, LM Studio, vLLM, most self-hosted gateways.
  openai,

  /// Anthropic-compatible messages (`/v1/messages`, `/v1/models`).
  anthropic;

  /// The wire name used in persisted credentials and the `providers.*` ops.
  String get wire => name;

  /// Parses a wire name; null for unknown/absent values.
  static CustomProviderDialect? fromWire(String? raw) {
    for (final value in CustomProviderDialect.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return null;
  }
}

/// Why a provider is (or isn't) available — surfaced in the UI so the user
/// knows what to do to enable it.
enum HarnessProviderEnabled {
  /// No credential and no env var.
  disabled,

  /// Enabled via an environment variable (e.g. `ANTHROPIC_API_KEY`).
  env,

  /// Enabled via a stored API-key account.
  account,

  /// Enabled via a stored OAuth account (browser login).
  oauth,

  /// A local provider reachable with no credential (e.g. Ollama / LM Studio).
  local,

  /// Enabled via a user-configured custom endpoint.
  custom;

  /// The wire name used by the `providers.*` RPC ops.
  String get wire => name;

  /// Parses a wire name back to an enum value, defaulting to [disabled].
  static HarnessProviderEnabled fromWire(String? raw) {
    for (final value in HarnessProviderEnabled.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return HarnessProviderEnabled.disabled;
  }
}

/// A stored credential for an LLM provider. Multiple credentials per provider
/// are supported (personal key, team OAuth, free-tier key).
///
/// A **custom provider** (any OpenAI- or Anthropic-compatible endpoint the
/// user adds) is defined by a single credential entry carrying its [dialect],
/// [displayName] and [baseUrl] — with an optional API key ([method] is
/// [HarnessAuthMethod.none] for public/local endpoints).
class ProviderCredential {
  /// Creates a [ProviderCredential].
  const ProviderCredential({
    required this.providerId,
    required this.method,
    this.apiKey,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.accountLabel,
    this.baseUrl,
    this.email,
    this.accountId,
    this.disabledCause,
    this.isActive = true,
    this.dialect,
    this.displayName,
    this.generation = const ProviderGenerationDefaults(),
  });

  /// Rebuilds a credential from its [toJson] map.
  factory ProviderCredential.fromJson(Map<String, dynamic> json) {
    final expiresMs = (json['expiresAt'] as num?)?.toInt();
    return ProviderCredential(
      providerId: json['providerId'] as String? ?? '',
      method: HarnessAuthMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => HarnessAuthMethod.apiKey,
      ),
      apiKey: json['apiKey'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresAt: expiresMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiresMs),
      accountLabel: json['accountLabel'] as String?,
      baseUrl: json['baseUrl'] as String?,
      email: json['email'] as String?,
      accountId: json['accountId'] as String?,
      disabledCause: json['disabledCause'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      dialect: CustomProviderDialect.fromWire(json['dialect'] as String?),
      displayName: json['displayName'] as String?,
      generation: ProviderGenerationDefaults.fromJson(
        json['generation'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Provider key (e.g. `anthropic`, `openai`, `ollama`).
  final String providerId;

  /// Auth method.
  final HarnessAuthMethod method;

  /// API key, when [method] is [HarnessAuthMethod.apiKey].
  final String? apiKey;

  /// OAuth access token, when [method] is [HarnessAuthMethod.oauth].
  final String? accessToken;

  /// OAuth refresh token, when applicable.
  final String? refreshToken;

  /// Access-token expiry, when applicable.
  final DateTime? expiresAt;

  /// Human-readable account label ("Personal", "Team", "Free tier").
  final String? accountLabel;

  /// Custom base URL for self-hosted / OpenAI-compatible endpoints.
  final String? baseUrl;

  /// OAuth account email, when known (used as the account identity / label).
  final String? email;

  /// OAuth account / organization id, when known (used for dedup).
  final String? accountId;

  /// Non-null when the credential was soft-disabled after an auth failure
  /// (carries the failure cause, e.g. `invalid_grant`).
  final String? disabledCause;

  /// Whether this is the active credential for its provider.
  final bool isActive;

  /// The wire dialect, when this credential defines a **custom provider**
  /// (null for built-in providers).
  final CustomProviderDialect? dialect;

  /// Human-readable name, when this credential defines a custom provider.
  final String? displayName;

  /// The sampling recipe and output ceiling to use for runs on this provider.
  /// Empty by default, which means "send nothing and keep the harness default".
  final ProviderGenerationDefaults generation;

  /// Whether this credential defines a user-added custom provider.
  bool get isCustomProvider => dialect != null;

  /// A stable identity key for dedup (email → accountId → accountLabel).
  String? get identityKey => email ?? accountId ?? accountLabel;

  /// A stable address for this credential within its provider — used by the
  /// settings UI and the `providers.*` ops to list and remove individual
  /// keys/accounts. OAuth credentials address by identity; API keys by a short
  /// FNV-1a hash of the secret (the raw secret never crosses RPC); none-auth
  /// by identity or `default`. Derived from persisted fields, so it survives
  /// restarts and is identical on every client.
  String get credentialId => switch (method) {
    HarnessAuthMethod.apiKey => 'key:${_fnv1a32(apiKey ?? '')}',
    HarnessAuthMethod.oauth => 'oauth:${identityKey ?? 'default'}',
    HarnessAuthMethod.none => 'none:${identityKey ?? 'default'}',
  };

  /// A masked tail of the secret for display (`…wxyz`), or null when there is
  /// no secret or it is too short to expose any of safely.
  String? get secretHint {
    final s = secret;
    if (s == null || s.length <= 6) {
      return null;
    }
    return '…${s.substring(s.length - 4)}';
  }

  /// FNV-1a 32-bit — a platform-stable, web-safe hash (all arithmetic stays
  /// under 2^53, so dart2js number semantics cannot skew it). Used as an
  /// address, not for security: the hashed secret is high-entropy.
  static String _fnv1a32(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  /// The secret to send (API key or access token), or null for none-auth.
  String? get secret => switch (method) {
    HarnessAuthMethod.apiKey => apiKey,
    HarnessAuthMethod.oauth => accessToken,
    HarnessAuthMethod.none => null,
  };

  /// Returns a copy with the given overrides.
  ProviderCredential copyWith({
    String? apiKey,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? accountLabel,
    String? baseUrl,
    String? email,
    String? accountId,
    String? disabledCause,
    bool? isActive,
    CustomProviderDialect? dialect,
    String? displayName,
    ProviderGenerationDefaults? generation,
  }) => ProviderCredential(
    providerId: providerId,
    method: method,
    apiKey: apiKey ?? this.apiKey,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    accountLabel: accountLabel ?? this.accountLabel,
    baseUrl: baseUrl ?? this.baseUrl,
    email: email ?? this.email,
    accountId: accountId ?? this.accountId,
    disabledCause: disabledCause ?? this.disabledCause,
    isActive: isActive ?? this.isActive,
    dialect: dialect ?? this.dialect,
    displayName: displayName ?? this.displayName,
    generation: generation ?? this.generation,
  );

  /// Serializes to a JSON-ready map (epoch-ms for [expiresAt]).
  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'method': method.name,
    if (apiKey != null) 'apiKey': apiKey,
    if (accessToken != null) 'accessToken': accessToken,
    if (refreshToken != null) 'refreshToken': refreshToken,
    if (expiresAt != null) 'expiresAt': expiresAt!.millisecondsSinceEpoch,
    if (accountLabel != null) 'accountLabel': accountLabel,
    if (baseUrl != null) 'baseUrl': baseUrl,
    if (email != null) 'email': email,
    if (accountId != null) 'accountId': accountId,
    if (disabledCause != null) 'disabledCause': disabledCause,
    'isActive': isActive,
    if (dialect != null) 'dialect': dialect!.wire,
    if (displayName != null) 'displayName': displayName,
    if (generation.isNotEmpty) 'generation': generation.toJson(),
  };
}

/// Stores and resolves LLM provider credentials.
///
/// The desktop app backs this with the OS keychain; the headless server backs
/// it with environment variables. The harness asks the store for the active
/// credential of a provider when building an `LlmProviderPort`.
abstract interface class ProviderCredentialStore {
  /// Returns the active credential for [providerId], or null when none is set.
  Future<ProviderCredential?> activeCredential(String providerId);

  /// Returns all stored credentials for [providerId].
  Future<List<ProviderCredential>> credentialsFor(String providerId);

  /// Persists [credential] (adding or updating).
  Future<void> save(ProviderCredential credential);

  /// Removes the credential identified by [providerId] + [accountLabel] or
  /// [credentialId]. With neither, removes every credential of the provider.
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  });
}

/// Implemented by credential stores that can enumerate user-defined custom
/// providers — credentials carrying a [ProviderCredential.dialect]. Kept as a
/// separate capability interface so read-only stores (env) and test fakes
/// don't have to implement it; callers feature-detect with `is`.
abstract interface class CustomProviderLister {
  /// The stored custom-provider definitions, in insertion order.
  Future<List<ProviderCredential>> customProviders();
}
