import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves the current GitHub CLI installation and PAT status.
final githubCliStatusProvider = FutureProvider<GitHubCliStatus>((ref) {
  return ref.watch(githubCliServiceProvider).probe();
});

/// Derives the active GitHub token from credentials or the GitHub CLI.
final githubAuthTokenProvider = Provider<String>((ref) {
  final credentials = ref
      .watch(credentialsProvider)
      .maybeWhen(data: (c) => c, orElse: () => null);
  final pat = credentials?.githubToken ?? '';
  if (pat.isNotEmpty) {
    return pat;
  }

  final cli = ref
      .watch(githubCliStatusProvider)
      .maybeWhen(data: (c) => c, orElse: () => null);
  return cli?.token ?? '';
});

// `isGitHubAuthenticatedProvider` was removed when the app went multi-forge.
// It answered "is GitHub connected?", which is no longer the question anything
// asks: the onboarding gate and every PR surface want "is at least one forge
// connected?" (`hasAnyForgeConnectedProvider`) or the state of one specific
// forge (`forgeConnectionsProvider`). Leaving a GitHub-shaped flag behind would
// invite the next reader to wire a new surface to it and quietly exclude GitLab
// and Bitbucket.

/// True when at least one API credential (GitHub or ticketing) has been loaded.
final isCredentialsLoadedProvider = Provider<bool>((ref) {
  return ref
      .watch(credentialsProvider)
      .maybeWhen(
        data: (c) => c.githubToken.isNotEmpty || c.ticketingApiKey.isNotEmpty,
        orElse: () => false,
      );
});

/// Async notifier that loads and mutates stored API credentials.
final credentialsProvider =
    AsyncNotifierProvider<CredentialsNotifier, ApiCredentials>(
      CredentialsNotifier.new,
    );

/// Credentials notifier.
class CredentialsNotifier extends AsyncNotifier<ApiCredentials> {
  @override
  Future<ApiCredentials> build() async {
    final repo = ref.watch(credentialsRepositoryProvider);
    return repo.loadCredentials();
  }

  /// Set git hub token.
  Future<void> setGitHubToken(String token) async {
    final repo = ref.read(credentialsRepositoryProvider);
    await repo.setGitHubToken(token);
    state = AsyncData(
      state.asData?.value.copyWith(githubToken: token) ??
          ApiCredentials(githubToken: token),
    );
  }

  /// Set the remote ticketing provider API key.
  Future<void> setTicketingApiKey(String key) async {
    final repo = ref.read(credentialsRepositoryProvider);
    await repo.setTicketingApiKey(key);
    state = AsyncData(
      state.asData?.value.copyWith(ticketingApiKey: key) ??
          ApiCredentials(ticketingApiKey: key),
    );
  }

  /// Set the chosen ticketing provider id.
  Future<void> setTicketingProvider(String providerId) async {
    final repo = ref.read(credentialsRepositoryProvider);
    await repo.setTicketingProvider(providerId);
    state = AsyncData(
      state.asData?.value.copyWith(ticketingProviderId: providerId) ??
          ApiCredentials(ticketingProviderId: providerId),
    );
  }

  /// Clear git hub token.
  Future<void> clearGitHubToken() async {
    final repo = ref.read(credentialsRepositoryProvider);
    await repo.setGitHubToken('');
    final current = state.asData?.value ?? const ApiCredentials();
    state = AsyncData(current.copyWith(githubToken: ''));
  }

  /// Clear.
  Future<void> clear() async {
    final repo = ref.read(credentialsRepositoryProvider);
    await repo.clearCredentials();
    state = const AsyncData(ApiCredentials());
  }
}
