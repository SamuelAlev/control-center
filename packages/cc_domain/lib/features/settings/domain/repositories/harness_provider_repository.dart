import 'package:cc_harness/provider.dart';

/// Client-facing access to the server-owned harness provider brain: which
/// providers exist and are connected, their live model lists and API-key /
/// OAuth credential management.
///
/// The server owns all state (credentials, OAuth flows, token refresh); this
/// interface is the thin RPC surface every client (desktop/web/remote) uses.
abstract interface class HarnessProviderRepository {
  /// Lists every harness provider — built-in and user-added custom — with its
  /// live connection state.
  Future<List<HarnessProviderInfo>> listProviders();

  /// Lists selectable models, served **live** by each connected provider's own
  /// endpoint. Optionally restricted to [providerId].
  Future<List<HarnessModelInfo>> listModels({String? providerId});

  /// Stores an API key for [providerId] (optionally with a custom [baseUrl] for
  /// self-hosted endpoints). For a custom provider an empty [apiKey] updates
  /// only the base URL, keeping any stored key.
  Future<void> saveApiKey({
    required String providerId,
    required String apiKey,
    String? baseUrl,
    String? accountLabel,
  });

  /// Removes a stored credential for [providerId] — the single credential
  /// addressed by [credentialId] (see [HarnessProviderInfo.credentials]), the
  /// account named by [accountLabel], or every credential of the provider when
  /// neither is given. For a custom provider this drops only the key — the
  /// provider itself survives until [removeCustomProvider].
  Future<void> removeCredential({
    required String providerId,
    String? accountLabel,
    String? credentialId,
  });

  /// Registers a custom provider — any OpenAI- or Anthropic-compatible
  /// endpoint (local or remote), with an optional [apiKey] for private
  /// deployments. Returns the generated provider id (`custom-<slug>`).
  Future<String> addCustomProvider({
    required String displayName,
    required CustomProviderDialect dialect,
    required String baseUrl,
    String? apiKey,
  });

  /// Deletes a custom provider — its definition and any stored key.
  Future<void> removeCustomProvider(String providerId);

  /// Sets the sampling recipe and output ceiling for [providerId]. A null field
  /// clears it back to the endpoint's own default.
  ///
  /// Models publish their own output ceilings and required sampling recipes, so
  /// one hard-coded number cannot serve a frontier API and a local quant alike.
  Future<void> saveGenerationDefaults({
    required String providerId,
    int? maxTokens,
    double? temperature,
    double? topP,
    int? topK,
  });

  /// Starts a browser OAuth login for [providerId]; the client opens the
  /// returned URL and polls [oauthStatus].
  Future<HarnessOAuthStart> startOAuth(String providerId);

  /// Polls the state of an OAuth login started with [startOAuth].
  Future<HarnessOAuthStatus> oauthStatus(String flowId);

  /// Completes an OAuth login with a manually-pasted code (web / remote path).
  Future<void> completeOAuth({required String flowId, required String code});

  /// Cancels an in-progress OAuth login.
  Future<void> cancelOAuth(String flowId);
}
