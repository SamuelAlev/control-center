import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';

/// Resolves a provider's [ProviderEnablement] from host signals: which env vars
/// are set and which providers have a logged-in account (the `provider`
/// enablement provenance). Pure — the host passes in the present env keys /
/// account services; this never reads `Platform.environment` itself.
class ProviderEnablementChecker {
  /// Creates a checker.
  ///
  /// [presentEnvKeys] are env var names that are set (and non-empty).
  /// [accountProviders] maps providerId → auth-service name for logged-in
  /// accounts (e.g. `{'anthropic': 'anthropic-oauth'}`). [customProviders]
  /// maps providerId → opaque custom-auth data.
  const ProviderEnablementChecker({
    this.presentEnvKeys = const {},
    this.accountProviders = const {},
    this.customProviders = const {},
  });

  /// Env var names that are set.
  final Set<String> presentEnvKeys;

  /// Providers with a logged-in account → the auth-service name.
  final Map<String, String> accountProviders;

  /// Providers enabled via a custom mechanism → opaque data.
  final Map<String, Map<String, dynamic>> customProviders;

  /// Resolves the enablement for [provider].
  ProviderEnablement resolve(ModelProvider provider) {
    // An account/login wins (it implies usable credentials and may rank).
    final service = accountProviders[provider.id];
    if (service != null) {
      return ProviderEnabledViaAccount(service);
    }
    // Then any of the provider's env keys being set.
    for (final key in provider.envKeys) {
      if (presentEnvKeys.contains(key)) {
        return ProviderEnabledViaEnv(key);
      }
    }
    final custom = customProviders[provider.id];
    if (custom != null) {
      return ProviderEnabledViaCustom(custom);
    }
    return ProviderDisabled(missingEnv: provider.envKeys);
  }
}
