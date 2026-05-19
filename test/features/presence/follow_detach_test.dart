import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:control_center/features/presence/providers/follow_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('followShouldDetach (pure, PRD 16 §4 "follow until you act")', () {
    test('stays attached before any programmatic navigation has happened', () {
      expect(
        followShouldDetach(
          currentLocation: '/workspaces/ws-1/channels/chan-1',
          lastFollowNavigatedLocation: null,
        ),
        isFalse,
      );
    });

    test('stays attached while the visible location still matches the last '
        'follow-driven navigation', () {
      expect(
        followShouldDetach(
          currentLocation: '/workspaces/ws-1/channels/chan-1',
          lastFollowNavigatedLocation: '/workspaces/ws-1/channels/chan-1',
        ),
        isFalse,
      );
    });

    test('detaches once the visible location diverges — the user navigated '
        'under their own steam', () {
      expect(
        followShouldDetach(
          currentLocation: '/workspaces/ws-1/inbox',
          lastFollowNavigatedLocation: '/workspaces/ws-1/channels/chan-1',
        ),
        isTrue,
      );
    });

    test('detaches on a query-string-only change too', () {
      expect(
        followShouldDetach(
          currentLocation: '/workspaces/ws-1/channels/chan-1?m=msg-2',
          lastFollowNavigatedLocation: '/workspaces/ws-1/channels/chan-1',
        ),
        isTrue,
      );
    });
  });

  group('routeForLocus (pure)', () {
    const workspaceId = 'ws-1';

    test('ChannelLocus resolves to the channel route', () {
      expect(
        routeForLocus(workspaceId, const ChannelLocus(channelId: 'chan-1')),
        '/workspaces/ws-1/channels/chan-1',
      );
    });

    test('PrLocus resolves to the PR detail route', () {
      expect(
        routeForLocus(
          workspaceId,
          const PrLocus(repoFullName: 'acme/widgets', prNumber: 42),
        ),
        '/workspaces/ws-1/pull-requests/acme/widgets/42',
      );
    });

    test('TicketLocus resolves to the ticket detail route', () {
      expect(
        routeForLocus(workspaceId, const TicketLocus(ticketId: 'tk-9')),
        '/workspaces/ws-1/tickets/tk-9',
      );
    });

    test('FileLocus has no direct route', () {
      expect(
        routeForLocus(
          workspaceId,
          const FileLocus(repoId: 'repo-1', path: 'lib/main.dart'),
        ),
        isNull,
      );
    });

    test('PlanNodeLocus has no direct route', () {
      expect(
        routeForLocus(
          workspaceId,
          const PlanNodeLocus(orchestrationId: 'orch-1', nodeId: 'node-1'),
        ),
        isNull,
      );
    });
  });

  group('FollowedPrincipalNotifier', () {
    test('toggle follows, then detaches on a second toggle of the same '
        'principal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const alice = UserPrincipal('alice');
      const bob = UserPrincipal('bob');

      final notifier = container.read(followedPrincipalProvider.notifier);
      expect(container.read(followedPrincipalProvider), isNull);

      notifier.toggle(alice);
      expect(container.read(followedPrincipalProvider), alice);

      // Toggling a different principal switches the target (does not detach).
      notifier.toggle(bob);
      expect(container.read(followedPrincipalProvider), bob);

      // Toggling the currently-followed principal again detaches.
      notifier.toggle(bob);
      expect(container.read(followedPrincipalProvider), isNull);
    });

    test('detach is a no-op when nobody is followed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(followedPrincipalProvider.notifier).detach();
      expect(container.read(followedPrincipalProvider), isNull);
    });
  });
}
