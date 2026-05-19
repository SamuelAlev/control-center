import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseViewerGitHubTeams groups slugs by org', () {
    expect(
      parseViewerGitHubTeams([
        {'org': 'Google', 'slug': 'google-cloud-a'},
        {'org': 'Google', 'slug': 'google-cloud-b'},
        {'org': 'other', 'slug': 'ops'},
        {'org': '', 'slug': 'ignored'},
      ]),
      {
        'google': {'google-cloud-a', 'google-cloud-b'},
        'other': {'ops'},
      },
    );
    expect(parseViewerGitHubTeams(null), isEmpty);
    expect(parseViewerGitHubTeams('nope'), isEmpty);
  });

  test('githubUserProvider returns null when not authenticated', () async {
    final container = ProviderContainer(
      overrides: const [],
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
}
