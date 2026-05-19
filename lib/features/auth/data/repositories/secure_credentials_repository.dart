import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/features/auth/domain/entities/api_credentials.dart';
import 'package:control_center/features/auth/domain/repositories/credentials_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure credentials repository. Secrets (tokens / API keys) live in the
/// platform secure store; the non-secret ticketing provider choice lives in
/// `SharedPreferences`.
class SecureCredentialsRepository implements CredentialsRepository {
  /// Creates a new [Secure credentials repository].
  SecureCredentialsRepository(this._storage, this._prefs);

  final FlutterSecureStorage _storage;
  final SharedPreferences _prefs;

  @override
  Future<ApiCredentials> loadCredentials() async {
    final githubToken = await _storage.read(key: githubTokenKey) ?? '';
    final ticketingApiKey = await _storage.read(key: ticketingApiKeyKey) ?? '';
    final providerId = _prefs.getString(ticketingProviderKey) ?? 'local';
    return ApiCredentials(
      githubToken: githubToken,
      ticketingApiKey: ticketingApiKey,
      ticketingProviderId: providerId,
    );
  }

  @override
  Future<void> saveCredentials(ApiCredentials credentials) async {
    if (credentials.githubToken.isNotEmpty) {
      await _storage.write(key: githubTokenKey, value: credentials.githubToken);
    }
    if (credentials.ticketingApiKey.isNotEmpty) {
      await _storage.write(
        key: ticketingApiKeyKey,
        value: credentials.ticketingApiKey,
      );
    }
    await _prefs.setString(ticketingProviderKey, credentials.ticketingProviderId);
  }

  @override
  Future<void> clearCredentials() async {
    await _storage.delete(key: githubTokenKey);
    await _storage.delete(key: ticketingApiKeyKey);
    await _prefs.remove(ticketingProviderKey);
  }

  @override
  Future<void> setGitHubToken(String token) async {
    if (token.isEmpty) {
      await _storage.delete(key: githubTokenKey);
    } else {
      await _storage.write(key: githubTokenKey, value: token);
    }
  }

  @override
  Future<void> setTicketingApiKey(String key) async {
    if (key.isEmpty) {
      await _storage.delete(key: ticketingApiKeyKey);
    } else {
      await _storage.write(key: ticketingApiKeyKey, value: key);
    }
  }

  @override
  Future<void> setTicketingProvider(String providerId) =>
      _prefs.setString(ticketingProviderKey, providerId);
}
