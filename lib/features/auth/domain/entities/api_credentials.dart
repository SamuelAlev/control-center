import 'package:control_center/features/auth/domain/value_objects/token.dart';

/// Holds the user's API credentials for external services.
class ApiCredentials {
  /// Creates [ApiCredentials] with optional [githubToken] and ticketing config.
  const ApiCredentials({
    this.githubToken = '',
    this.ticketingApiKey = '',
    this.ticketingProviderId = 'local',
  });

  /// GitHub personal access token or CLI-derived token.
  final String githubToken;

  /// API key for the configured remote ticketing provider (empty for local).
  final String ticketingApiKey;

  /// The chosen ticketing provider id (`local` | `linear` | `jira` | `clickup`).
  final String ticketingProviderId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiCredentials &&
          runtimeType == other.runtimeType &&
          githubToken == other.githubToken &&
          ticketingApiKey == other.ticketingApiKey &&
          ticketingProviderId == other.ticketingProviderId;

  @override
  int get hashCode =>
      Object.hash(githubToken, ticketingApiKey, ticketingProviderId);

  @override
  String toString() =>
      'ApiCredentials(githubToken: ${Token(githubToken)}, '
      'ticketingApiKey: ${Token(ticketingApiKey)}, '
      'ticketingProviderId: $ticketingProviderId)';

  /// Copy with.
  ApiCredentials copyWith({
    String? githubToken,
    String? ticketingApiKey,
    String? ticketingProviderId,
  }) {
    return ApiCredentials(
      githubToken: githubToken ?? this.githubToken,
      ticketingApiKey: ticketingApiKey ?? this.ticketingApiKey,
      ticketingProviderId: ticketingProviderId ?? this.ticketingProviderId,
    );
  }
}

/// Convenience getters on [ApiCredentials].
extension ApiCredentialsHelpers on ApiCredentials {
  /// Whether a GitHub token is present.
  bool get hasGitHubToken => githubToken.isNotEmpty;

  /// Whether a remote ticketing API key is present.
  bool get hasTicketingCredentials => ticketingApiKey.isNotEmpty;

  /// Whether the required credentials are present. Only GitHub is required —
  /// ticketing is optional (the local provider needs no key).
  bool get isConfigured => hasGitHubToken;
}
