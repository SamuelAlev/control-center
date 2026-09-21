import 'dart:io';

import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';

/// Env-backed [CredentialsRepository] for headless `cc_server` (no keychain).
///
/// Broker only calls [loadCredentials]; mutators throw. Same env names as the
/// rest of the server: `GITHUB_TOKEN`/`GH_TOKEN`; ticketing first-match among
/// `LINEAR_API_KEY`, `JIRA_API_TOKEN`, `CLICKUP_API_TOKEN` (one vendor only).
/// LLM keys live in the harness credential store, not here.
class EnvCredentialsRepository implements CredentialsRepository {
  /// Creates an env-backed credentials repository. [environment] defaults to
  /// the process environment; tests may inject a fixed map.
  EnvCredentialsRepository({Map<String, String>? environment})
    : _env = environment ?? Platform.environment;

  final Map<String, String> _env;

  /// The ticketing vendors this can source a key for, in resolution order.
  static const _ticketingKeys = <String, String>{
    'linear': 'LINEAR_API_KEY',
    'jira': 'JIRA_API_TOKEN',
    'clickup': 'CLICKUP_API_TOKEN',
  };

  @override
  Future<ApiCredentials> loadCredentials() async {
    final githubToken = _env['GITHUB_TOKEN'] ?? _env['GH_TOKEN'] ?? '';
    for (final entry in _ticketingKeys.entries) {
      final key = _env[entry.value] ?? '';
      if (key.isNotEmpty) {
        return ApiCredentials(
          githubToken: githubToken,
          ticketingApiKey: key,
          ticketingProviderId: entry.key,
        );
      }
    }
    return ApiCredentials(githubToken: githubToken);
  }

  @override
  Future<void> saveCredentials(ApiCredentials credentials) async =>
      throw UnsupportedError(
        'EnvCredentialsRepository is read-only — provision the headless server '
        'via environment variables (GITHUB_TOKEN, …).',
      );

  @override
  Future<void> clearCredentials() async =>
      throw UnsupportedError('EnvCredentialsRepository is read-only.');

  @override
  Future<void> setGitHubToken(String token) async =>
      throw UnsupportedError('EnvCredentialsRepository is read-only.');

  @override
  Future<void> setTicketingApiKey(String key) async =>
      throw UnsupportedError('EnvCredentialsRepository is read-only.');

  @override
  Future<void> setTicketingProvider(String providerId) async =>
      throw UnsupportedError('EnvCredentialsRepository is read-only.');
}
