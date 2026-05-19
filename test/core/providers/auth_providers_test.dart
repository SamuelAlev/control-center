// ignore_for_file: avoid_dynamic_calls

import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/domain/entities/api_credentials.dart';
import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/domain/ports/github_cli_port.dart';
import 'package:control_center/features/auth/domain/repositories/credentials_repository.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeGitHubCliPort implements GitHubCliPort {
  const _FakeGitHubCliPort(this.status);

  final GitHubCliStatus status;

  @override
  Future<GitHubCliStatus> probe() async => status;
}

class _InMemoryCredentialsRepository implements CredentialsRepository {
  _InMemoryCredentialsRepository([this._creds = const ApiCredentials()]);

  ApiCredentials _creds;

  @override
  Future<ApiCredentials> loadCredentials() async => _creds;

  @override
  Future<void> saveCredentials(ApiCredentials credentials) async {
    _creds = credentials;
  }

  @override
  Future<void> clearCredentials() async {
    _creds = const ApiCredentials();
  }

  @override
  Future<void> setGitHubToken(String token) async {
    _creds = _creds.copyWith(githubToken: token);
  }

  @override
  Future<void> setTicketingApiKey(String key) async {
    _creds = _creds.copyWith(ticketingApiKey: key);
  }

  @override
  Future<void> setTicketingProvider(String providerId) async {
    _creds = _creds.copyWith(ticketingProviderId: providerId);
  }
}

void main() {
  group('sharedPreferencesProvider', () {
    test('returns fake in-memory instance when not overridden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final prefs = container.read(sharedPreferencesProvider);
      expect(prefs, isA<SharedPreferences>());
      expect(prefs.getString('test'), isNull);
    });
  });

  group('CredentialsNotifier', () {
    late ProviderContainer container;
    late _InMemoryCredentialsRepository repo;

    setUp(() {
      repo = _InMemoryCredentialsRepository();
      container = ProviderContainer(
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
    });

    test('build returns empty credentials', () async {
      final state = await container.read(credentialsProvider.future);
      expect(state.githubToken, '');
      expect(state.ticketingApiKey, '');
    });

    test('build loads credentials from repository', () async {
      final repoWithCreds = _InMemoryCredentialsRepository(
        const ApiCredentials(
          githubToken: 'ghp_token123',
          ticketingApiKey: 'tk_api_456',
        ),
      );
      final container2 = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repoWithCreds),
        ],
      );
      addTearDown(container2.dispose);

      final state = await container2.read(credentialsProvider.future);
      expect(state.githubToken, 'ghp_token123');
      expect(state.ticketingApiKey, 'tk_api_456');
    });

    test('load handles empty credentials gracefully', () async {
      final state = await container.read(credentialsProvider.future);
      expect(state.githubToken, '');
      expect(state.ticketingApiKey, '');
    });

    test('setGitHubToken persists and updates state', () async {
      final notifier = container.read(credentialsProvider.notifier);
      await container.read(credentialsProvider.future);
      await notifier.setGitHubToken('new_token');

      final state = container.read(credentialsProvider).requireValue;
      expect(state.githubToken, 'new_token');
      expect(repo._creds.githubToken, 'new_token');
    });

    test('setTicketingApiKey persists and updates state', () async {
      final notifier = container.read(credentialsProvider.notifier);
      await container.read(credentialsProvider.future);
      await notifier.setTicketingApiKey('ticketing_key');

      final state = container.read(credentialsProvider).requireValue;
      expect(state.ticketingApiKey, 'ticketing_key');
      expect(repo._creds.ticketingApiKey, 'ticketing_key');
    });

    test('clearGitHubToken removes token from state', () async {
      final repoWithToken = _InMemoryCredentialsRepository(
        const ApiCredentials(githubToken: 'old_token'),
      );
      final container2 = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repoWithToken),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(credentialsProvider.notifier);
      await container2.read(credentialsProvider.future);
      await notifier.clearGitHubToken();

      expect(
        container2.read(credentialsProvider).requireValue.githubToken,
        '',
      );
      expect(repoWithToken._creds.githubToken, '');
    });

    test('clear removes all credentials', () async {
      final repoWithCreds = _InMemoryCredentialsRepository(
        const ApiCredentials(githubToken: 'ghp_abc', ticketingApiKey: 'tk_def'),
      );
      final container2 = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repoWithCreds),
        ],
      );
      addTearDown(container2.dispose);

      final notifier = container2.read(credentialsProvider.notifier);
      await container2.read(credentialsProvider.future);
      await notifier.clear();

      final state = container2.read(credentialsProvider).requireValue;
      expect(state.githubToken, '');
      expect(state.ticketingApiKey, '');
      expect(repoWithCreds._creds.githubToken, '');
      expect(repoWithCreds._creds.ticketingApiKey, '');
    });
  });

  group('githubAuthTokenProvider', () {
    test('returns PAT when set in credentials', () async {
      final repo = _InMemoryCredentialsRepository(
        const ApiCredentials(githubToken: 'ghp_pat_token'),
      );
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repo),
          githubCliServiceProvider.overrideWithValue(
            const _FakeGitHubCliPort(
              GitHubCliStatus(
                isInstalled: true,
                isAuthenticated: true,
                username: 'testuser',
                token: 'cli_token',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(credentialsProvider.future);
      final token = container.read(githubAuthTokenProvider);
      expect(token, 'ghp_pat_token');
    });

    test('falls back to gh CLI token when PAT is empty', () async {
      final repo = _InMemoryCredentialsRepository();
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repo),
          githubCliServiceProvider.overrideWithValue(
            const _FakeGitHubCliPort(
              GitHubCliStatus(
                isInstalled: true,
                isAuthenticated: true,
                username: 'testuser',
                token: 'cli_token',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(githubCliStatusProvider.future);
      final token = container.read(githubAuthTokenProvider);
      expect(token, 'cli_token');
    });

    test('returns empty string when no token is available', () async {
      final repo = _InMemoryCredentialsRepository();
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repo),
          githubCliServiceProvider.overrideWithValue(
            const _FakeGitHubCliPort(GitHubCliStatus()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(githubCliStatusProvider.future);
      final token = container.read(githubAuthTokenProvider);
      expect(token, '');
    });
  });

  group('isGitHubAuthenticatedProvider', () {
    test('returns true when PAT is present', () async {
      final repo = _InMemoryCredentialsRepository(
        const ApiCredentials(githubToken: 'ghp_real'),
      );
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repo),
          githubCliServiceProvider.overrideWithValue(
            const _FakeGitHubCliPort(GitHubCliStatus()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(credentialsProvider.future);
      expect(container.read(isGitHubAuthenticatedProvider), true);
    });

    test('returns true when gh CLI token is present', () async {
      final repo = _InMemoryCredentialsRepository();
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repo),
          githubCliServiceProvider.overrideWithValue(
            const _FakeGitHubCliPort(
              GitHubCliStatus(
                isInstalled: true,
                isAuthenticated: true,
                token: 'cli_token',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(githubCliStatusProvider.future);
      expect(container.read(isGitHubAuthenticatedProvider), true);
    });

    test('returns false when no token is present', () async {
      final repo = _InMemoryCredentialsRepository();
      final container = ProviderContainer(
        overrides: [
          credentialsRepositoryProvider.overrideWithValue(repo),
          githubCliServiceProvider.overrideWithValue(
            const _FakeGitHubCliPort(GitHubCliStatus()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(githubCliStatusProvider.future);
      expect(container.read(isGitHubAuthenticatedProvider), false);
    });
  });

  group('isCredentialsLoadedProvider', () {
    test('starts false', () async {
      final repo = _InMemoryCredentialsRepository();
      final container = ProviderContainer(
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      expect(container.read(isCredentialsLoadedProvider), false);
    });

    test('becomes true after load with credentials', () async {
      final repo = _InMemoryCredentialsRepository(
        const ApiCredentials(githubToken: 'ghp_something'),
      );
      final container = ProviderContainer(
        overrides: [credentialsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      expect(container.read(isCredentialsLoadedProvider), false);
      await container.read(credentialsProvider.future);
      expect(container.read(isCredentialsLoadedProvider), true);
    });
  });
}
