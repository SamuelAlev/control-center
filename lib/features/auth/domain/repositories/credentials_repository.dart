import 'package:control_center/features/auth/domain/entities/api_credentials.dart';

/// Credentials repository.
abstract class CredentialsRepository {
  /// Load credentials.
  Future<ApiCredentials> loadCredentials();
  /// Save credentials.
  Future<void> saveCredentials(ApiCredentials credentials);
  /// Clear credentials.
  Future<void> clearCredentials();
  /// Set git hub token.
  Future<void> setGitHubToken(String token);
  /// Set the remote ticketing provider API key.
  Future<void> setTicketingApiKey(String key);
  /// Set the chosen ticketing provider id.
  Future<void> setTicketingProvider(String providerId);
}

