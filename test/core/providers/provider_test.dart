import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/agent_dao.dart';
import 'package:control_center/core/database/daos/cache_dao.dart';
import 'package:control_center/core/database/daos/messaging_dao.dart';
import 'package:control_center/core/database/daos/pull_request_dao.dart';
import 'package:control_center/core/database/daos/repo_dao.dart';
import 'package:control_center/core/database/daos/review_dao.dart';
import 'package:control_center/core/database/daos/rss_dao.dart';
import 'package:control_center/core/database/daos/workspace_dao.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/network/github_api_client.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('databaseProvider creates AppDatabase and disposes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final db = container.read(databaseProvider);
    expect(db, isA<AppDatabase>());
  });
  test('workspaceDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(workspaceDaoProvider);
    expect(dao, isA<WorkspaceDao>());
  });

  test('repoDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(repoDaoProvider);
    expect(dao, isA<RepoDao>());
  });

  test('agentDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(agentDaoProvider);
    expect(dao, isA<AgentDao>());
  });

  test('messagingDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(messagingDaoProvider);
    expect(dao, isA<MessagingDao>());
  });

  test('reviewDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(reviewDaoProvider);
    expect(dao, isA<ReviewDao>());
  });

  test('pullRequestDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(pullRequestDaoProvider);
    expect(dao, isA<PullRequestDao>());
  });

  test('cacheDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(cacheDaoProvider);
    expect(dao, isA<CacheDao>());
  });

  test('rssDaoProvider derives from databaseProvider', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final dao = container.read(rssDaoProvider);
    expect(dao, isA<RssDao>());
  });

  test('githubDioProvider is a valid Provider', () {
    final provider = githubDioProvider;
    expect(provider, isA<Provider<Dio>>());
  });

  test('githubApiClientProvider is a valid Provider', () {
    final provider = githubApiClientProvider;
    expect(provider, isA<Provider<GitHubApiClient>>());
  });

  test('githubUserProvider returns null when not authenticated', () async {
    final container = ProviderContainer(
      overrides: [isGitHubAuthenticatedProvider.overrideWith((ref) => false)],
    );
    addTearDown(container.dispose);

    final user = await container.read(githubUserProvider.future);
    expect(user, isNull);
  });

  test('domainEventBusProvider creates a bus', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final bus = container.read(domainEventBusProvider);
    expect(bus, isA<DomainEventBus>());
  });

  test('domainEventBusProvider returns same instance', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final bus1 = container.read(domainEventBusProvider);
    final bus2 = container.read(domainEventBusProvider);
    expect(identical(bus1, bus2), isTrue);
  });

  test('databaseProvider returns same instance for multiple reads', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final db1 = container.read(databaseProvider);
    final db2 = container.read(databaseProvider);
    expect(identical(db1, db2), isTrue);
  });

  test('githubDioProvider resolves with auth token', () async {
    SharedPreferences.setMockInitialValues({'github_token': 'ghp_test123'});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final dio = container.read(githubDioProvider);
    expect(dio, isA<Dio>());
  });
}
