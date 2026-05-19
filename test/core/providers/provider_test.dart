import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_infra/src/network/github_api_client.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('githubDioProvider is a valid Provider', () {
    final provider = githubDioProvider;
    expect(provider, isA<Provider<Dio>>());
  });

  test('githubApiClientProvider is a valid Provider', () {
    final provider = githubApiClientProvider;
    expect(provider, isA<Provider<GitHubApiClient>>());
  });

  test('parseViewerGitHubTeams groups slugs by org', () {
    expect(
      parseViewerGitHubTeams([
        {'org': 'Frontify', 'slug': 'frontend-platform'},
        {'org': 'Frontify', 'slug': 'design-system'},
        {'org': 'other', 'slug': 'ops'},
        {'org': '', 'slug': 'ignored'},
      ]),
      {
        'frontify': {'frontend-platform', 'design-system'},
        'other': {'ops'},
      },
    );
    expect(parseViewerGitHubTeams(null), isEmpty);
    expect(parseViewerGitHubTeams('nope'), isEmpty);
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

  test('githubDioProvider resolves with auth token', () async {
    final prefs = AppPreferences.inMemory({'github_token': 'ghp_test123'});
    final container = ProviderContainer(
      overrides: [appPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final dio = container.read(githubDioProvider);
    expect(dio, isA<Dio>());
  });
}
