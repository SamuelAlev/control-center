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
/// Recognised variables (all optional):
///  - `GITHUB_TOKEN` / `GH_TOKEN` — the agent's GitHub token,
///  - `CC_TICKETING_API_KEY` — remote ticketing API key,
///  - `CC_TICKETING_PROVIDER` — ticketing provider id (defaults to `local`).
class EnvCredentialsRepository implements CredentialsRepository {
  /// Creates an env-backed credentials repository. [environment] defaults to
  /// the process environment; tests may inject a fixed map.
  EnvCredentialsRepository({Map<String, String>? environment})
      : _env = environment ?? Platform.environment;

  final Map<String, String> _env;

  @override
  Future<ApiCredentials> loadCredentials() async {
    final githubToken = _env['GITHUB_TOKEN'] ?? _env['GH_TOKEN'] ?? '';
    return ApiCredentials(
      githubToken: githubToken,
      ticketingApiKey: _env['CC_TICKETING_API_KEY'] ?? '',
      ticketingProviderId: _env['CC_TICKETING_PROVIDER'] ?? 'local',
    );
  }

  @override
  Future<void> saveCredentials(ApiCredentials credentials) async =>
      throw UnsupportedError(
        'EnvCredentialsRepository is read-only — provision the headless server '
        'via environment variables (GITHUB_TOKEN, …).',
      );

  @override
  Future<void> clearCredentials() async => throw UnsupportedError(
        'EnvCredentialsRepository is read-only.',
      );

  @override
  Future<void> setGitHubToken(String token) async => throw UnsupportedError(
        'EnvCredentialsRepository is read-only.',
      );

  @override
  Future<void> setTicketingApiKey(String key) async => throw UnsupportedError(
        'EnvCredentialsRepository is read-only.',
      );

  @override
  Future<void> setTicketingProvider(String providerId) async =>
      throw UnsupportedError('EnvCredentialsRepository is read-only.');
}
