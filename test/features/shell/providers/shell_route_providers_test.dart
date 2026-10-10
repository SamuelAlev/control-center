import 'package:control_center/features/shell/providers/shell_route_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRouter router() => GoRouter(
    initialLocation: '/workspaces/ws/spaces/a',
    routes: [
      GoRoute(
        path: '/workspaces/:workspaceId/spaces/:spaceId',
        builder: (_, _) => const SizedBox(),
      ),
      GoRoute(
        path: '/workspaces/:workspaceId/inbox',
        builder: (_, _) => const SizedBox(),
      ),
    ],
  );

  testWidgets('the router path follows navigation but not a query change', (
    tester,
  ) async {
    final goRouter = router();
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(
      WidgetsApp.router(routerConfig: goRouter, color: const Color(0xFF000000)),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final paths = <String>[];
    final sub = container.listen(
      routerPathProvider(goRouter),
      (_, next) => paths.add(next),
      fireImmediately: true,
    );
    addTearDown(sub.close);
    expect(paths, ['/workspaces/ws/spaces/a']);

    // A `?tab=` change inside the open space reaches nothing downstream.
    goRouter.go('/workspaces/ws/spaces/a?tab=chat');
    await tester.pumpAndSettle();
    expect(container.read(routerPathProvider(goRouter)), paths.last);
    expect(paths, ['/workspaces/ws/spaces/a']);

    goRouter.go('/workspaces/ws/spaces/b');
    await tester.pumpAndSettle();
    expect(
      container.read(routerPathProvider(goRouter)),
      '/workspaces/ws/spaces/b',
    );
    expect(paths, ['/workspaces/ws/spaces/a', '/workspaces/ws/spaces/b']);
  });

  testWidgets('derived route answers', (tester) async {
    final goRouter = router();
    addTearDown(goRouter.dispose);
    await tester.pumpWidget(
      WidgetsApp.router(routerConfig: goRouter, color: const Color(0xFF000000)),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(routeWorkspaceIdProvider(goRouter)), 'ws');
    expect(container.read(shellLogicalRouteProvider(goRouter)), '/spaces/a');
    expect(
      container.read(
        routeSpaceIdProvider((router: goRouter, workspaceId: 'ws')),
      ),
      'a',
    );
    // A space route of another workspace never reads as selected here.
    expect(
      container.read(
        routeSpaceIdProvider((router: goRouter, workspaceId: 'other')),
      ),
      isNull,
    );

    goRouter.go('/workspaces/ws/inbox');
    await tester.pumpAndSettle();
    expect(
      container.read(
        routeSpaceIdProvider((router: goRouter, workspaceId: 'ws')),
      ),
      isNull,
    );
  });

  test('route matching modes', () {
    expect(
      shellRouteMatches('/tickets/42', '/tickets', ShellNavMatch.section),
      isTrue,
    );
    expect(
      shellRouteMatches('/ticketsArchive', '/tickets', ShellNavMatch.section),
      isFalse,
    );
    expect(
      shellRouteMatches('/tickets/42', '/tickets', ShellNavMatch.exact),
      isFalse,
    );
    expect(
      shellRouteMatches(
        '/settings/appearance',
        '/settings',
        ShellNavMatch.prefix,
      ),
      isTrue,
    );
    expect(workspaceIdFromLocation('/workspaces'), isNull);
    expect(workspaceIdFromLocation('/workspaces/ws'), 'ws');
    expect(spaceIdFromLocation('/workspaces/ws/spaces/a/files', 'ws'), 'a');
  });
}
