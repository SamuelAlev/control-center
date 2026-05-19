import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/data/repositories/secure_credentials_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecureCredentialsRepository', () {
    late SecureStore storage;
    late AppPreferences prefs;
    late SecureCredentialsRepository repo;

    setUp(() async {
      storage = SecureStore.inMemory();
      prefs = AppPreferences.inMemory();
      repo = SecureCredentialsRepository(storage, prefs);
    });

    test('loadCredentials returns empty defaults when nothing stored', () async {
      final creds = await repo.loadCredentials();
      expect(creds.githubToken, '');
      expect(creds.ticketingApiKey, '');
      expect(creds.ticketingProviderId, 'local');
    });

    test('loadCredentials returns stored values', () async {
      await storage.write(key: githubTokenKey, value: 'gh_token_123');
      await storage.write(key: ticketingApiKeyKey, value: 'tk_key_456');
      await prefs.setString(ticketingProviderKey, 'linear');

      final creds = await repo.loadCredentials();
      expect(creds.githubToken, 'gh_token_123');
      expect(creds.ticketingApiKey, 'tk_key_456');
      expect(creds.ticketingProviderId, 'linear');
    });

    test('saveCredentials persists all fields', () async {
      await repo.saveCredentials(const ApiCredentials(
        githubToken: 'gh_new',
        ticketingApiKey: 'tk_new',
        ticketingProviderId: 'linear',
      ));

      expect(await storage.read(key: githubTokenKey), 'gh_new');
      expect(await storage.read(key: ticketingApiKeyKey), 'tk_new');
      expect(prefs.getString(ticketingProviderKey), 'linear');
    });

    test('saveCredentials skips empty github token', () async {
      await storage.write(key: githubTokenKey, value: 'existing');
      await repo.saveCredentials(const ApiCredentials(
        githubToken: '',
        ticketingApiKey: 'tk',
        ticketingProviderId: 'local',
      ));
      expect(await storage.read(key: githubTokenKey), 'existing');
    });

    test('saveCredentials skips empty ticketing API key', () async {
      await storage.write(key: ticketingApiKeyKey, value: 'existing_key');
      await repo.saveCredentials(const ApiCredentials(
        githubToken: 'gh',
        ticketingApiKey: '',
        ticketingProviderId: 'local',
      ));
      expect(await storage.read(key: ticketingApiKeyKey), 'existing_key');
    });

    test('clearCredentials removes everything', () async {
      await storage.write(key: githubTokenKey, value: 'gh');
      await storage.write(key: ticketingApiKeyKey, value: 'tk');
      await prefs.setString(ticketingProviderKey, 'linear');

      await repo.clearCredentials();

      expect(await storage.read(key: githubTokenKey), isNull);
      expect(await storage.read(key: ticketingApiKeyKey), isNull);
      expect(prefs.getString(ticketingProviderKey), isNull);
    });

    test('setGitHubToken writes token', () async {
      await repo.setGitHubToken('new_gh_token');
      expect(await storage.read(key: githubTokenKey), 'new_gh_token');
    });

    test('setGitHubToken with empty string deletes key', () async {
      await storage.write(key: githubTokenKey, value: 'existing');
      await repo.setGitHubToken('');
      expect(await storage.read(key: githubTokenKey), isNull);
    });

    test('setTicketingApiKey writes key', () async {
      await repo.setTicketingApiKey('new_tk_key');
      expect(await storage.read(key: ticketingApiKeyKey), 'new_tk_key');
    });

    test('setTicketingApiKey with empty string deletes key', () async {
      await storage.write(key: ticketingApiKeyKey, value: 'existing');
      await repo.setTicketingApiKey('');
      expect(await storage.read(key: ticketingApiKeyKey), isNull);
    });

    test('setTicketingProvider writes to prefs', () async {
      await repo.setTicketingProvider('jira');
      expect(prefs.getString(ticketingProviderKey), 'jira');
    });

    test('full round-trip: save then load', () async {
      await repo.saveCredentials(const ApiCredentials(
        githubToken: 'gh_rt',
        ticketingApiKey: 'tk_rt',
        ticketingProviderId: 'linear',
      ));

      final loaded = await repo.loadCredentials();
      expect(loaded.githubToken, 'gh_rt');
      expect(loaded.ticketingApiKey, 'tk_rt');
      expect(loaded.ticketingProviderId, 'linear');
    });
  });
}
