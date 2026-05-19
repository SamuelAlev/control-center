import 'dart:io';

import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/repositories/credentials_repository.dart';

/// A pure-Dart [CredentialsRepository] backed by process environment variables.
///
/// The desktop reads credentials from the OS keychain via secure storage (a
/// Flutter plugin); the headless `cc_server` has no keychain, so it sources the
/// agent's GitHub token (and optional ticketing key/provider) from its own
/// environment. The credential broker only ever calls [loadCredentials] to mint
/// per-run scoped tokens, so the mutators throw — a headless server is
/// provisioned via env, not by writing back.
///
/// Recognised variables (all optional), and they are the SAME names the rest
/// of the server reads — there is no `CC_TICKETING_*` pair any more, because a
/// vendor-neutral duplicate of `LINEAR_API_KEY` is a second place to configure
/// one thing:
///  - `GITHUB_TOKEN` / `GH_TOKEN` — the agent's GitHub token,
///  - `LINEAR_API_KEY`, `JIRA_API_TOKEN`, `CLICKUP_API_TOKEN` — the ticketing
///    key, resolved in that order.
///
/// The order matters only when a host configures two vendors at once, which is
/// not a supported setup: an agent gets ONE `TICKETING_API_KEY`, so the first
/// configured vendor is the one it can talk to.
///
/// LLM provider keys (including z.ai) are NOT read here — they live in the
/// harness provider credential store (`EnvProviderCredentialStore` reads
/// `ZAI_API_KEY` / `ZHIPU_API_KEY` for the headless case).
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
