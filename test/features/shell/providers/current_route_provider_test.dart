import 'package:control_center/features/shell/providers/current_route_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _routerAt(String location) => GoRouter(
  initialLocation: location,
  routes: [
    GoRoute(
      path: '/workspaces/:workspaceId/channels',
      builder: (_, _) => const SizedBox(),
      routes: [
        GoRoute(path: ':channelId', builder: (_, _) => const SizedBox()),
      ],
    ),
    GoRoute(
      path: '/workspaces/:workspaceId/pull-requests',
      builder: (_, _) => const SizedBox(),
    ),
  ],
);

void main() {
  testWidgets('a notification route matches the open channel despite its query', (
    tester,
  ) async {
    final router = _routerAt('/workspaces/ws-1/channels/ch-1');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // A new-message notification deep-links to the message permalink, so its
    // route carries `?m=<id>` while the location is a bare path. Comparing the
    // raw strings made the open channel look off-route, and every agent message
    // raised an OS notification for the channel the reader was looking at.
    expect(
      isRouteActive(router, '/workspaces/ws-1/channels/ch-1?m=msg-9'),
      isTrue,
    );
    expect(isRouteActive(router, '/workspaces/ws-1/channels/ch-1'), isTrue);
    // Prefix matching still holds: the channel list contains this channel.
    expect(isRouteActive(router, '/workspaces/ws-1/channels'), isTrue);
  });

  testWidgets('a different channel or surface is not active', (tester) async {
    final router = _routerAt('/workspaces/ws-1/channels/ch-1');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(
      isRouteActive(router, '/workspaces/ws-1/channels/ch-2?m=msg-9'),
      isFalse,
    );
    expect(isRouteActive(router, '/workspaces/ws-1/channels/ch-2'), isFalse);
    expect(isRouteActive(router, '/workspaces/ws-1/pull-requests'), isFalse);
    // Not a path-segment boundary — a sibling whose name merely shares a prefix.
    expect(isRouteActive(router, '/workspaces/ws-1/chan'), isFalse);
  });
}
