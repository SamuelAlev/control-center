import 'dart:io';

import 'package:cc_harness/provider.dart';

/// Reads LLM provider credentials from environment variables.
///
/// Used by the headless server, which is provisioned via env. Each provider has
/// a set of recognized env var names; the first one present wins. Writes are
/// unsupported (the environment is read-only here).
class EnvProviderCredentialStore implements ProviderCredentialStore {
  /// Creates an [EnvProviderCredentialStore] reading from [environment]
  /// (defaults to the process environment).
  EnvProviderCredentialStore({Map<String, String>? environment})
    : _env = environment ?? Platform.environment;

  final Map<String, String> _env;

  /// Recognized env var names per provider id, in priority order.
  static final Map<String, List<String>> envKeys = Map.unmodifiable({
    for (final meta in harnessProviderMetas.values)
      if (meta.envKeys.isNotEmpty) meta.id: meta.envKeys,
  });

  @override
  Future<ProviderCredential?> activeCredential(String providerId) async {
    for (final key in envKeys[providerId] ?? const <String>[]) {
      final value = _env[key];
      if (value != null && value.isNotEmpty) {
        return ProviderCredential(
          providerId: providerId,
          method: HarnessAuthMethod.apiKey,
          apiKey: value,
          accountLabel: 'env:$key',
        );
      }
    }
    return null;
  }

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async {
    // One credential per SET env var, in priority order — a headless server
    // provisioned with several keys (e.g. `GEMINI_API_KEY` + `GOOGLE_API_KEY`)
    // gets the same rotation as stored multi-key setups.
    return [
      for (final key in envKeys[providerId] ?? const <String>[])
        if ((_env[key] ?? '').isNotEmpty)
          ProviderCredential(
            providerId: providerId,
            method: HarnessAuthMethod.apiKey,
            apiKey: _env[key],
            accountLabel: 'env:$key',
          ),
    ];
  }

  @override
  Future<void> save(ProviderCredential credential) async {
    throw UnsupportedError(
      'EnvProviderCredentialStore is read-only; set the provider env var '
      'instead.',
    );
  }

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {
    throw UnsupportedError('EnvProviderCredentialStore is read-only.');
  }
}
