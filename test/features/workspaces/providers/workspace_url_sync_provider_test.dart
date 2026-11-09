import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:control_center/core/providers/session_scope_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_url_sync_provider.dart';
import 'package:control_center/router/app_router.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Workspace _ws(String id) => Workspace(
  id: id,
  name: id,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  final scope = SessionScope(serverId: 'srv', userId: 'usr');

  Future<(ProviderContainer, GoRouter, StreamController<List<Workspace>>)>
  pumpApp(WidgetTester tester, {required String initial, String? hint}) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/workspaces', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/workspaces/:workspaceId/inbox',
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);
    final workspaces = StreamController<List<Workspace>>();
    addTearDown(workspaces.close);
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          AppPreferences.inMemory({scope.key(activeWorkspaceIdPrefKey): ?hint}),
        ),
        sessionScopeProvider.overrideWithValue(scope),
        routerProvider.overrideWithValue(router),
        workspacesProvider.overrideWith((ref) => workspaces.stream),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: WidgetsApp.router(
          routerConfig: router,
          color: const Color(0xFF000000),
        ),
      ),
    );
    container.listen(workspaceUrlSyncProvider, (_, _) {});
    await tester.pump();
    return (container, router, workspaces);
  }

  testWidgets('the route is what makes a workspace active', (tester) async {
    final (container, router, _) = await pumpApp(
      tester,
      initial: '/workspaces/ws-2/inbox',
    );
    expect(container.read(activeWorkspaceIdProvider), 'ws-2');
    router.go('/workspaces/ws-3/inbox');
    await tester.pumpAndSettle();
    expect(container.read(activeWorkspaceIdProvider), 'ws-3');
  });

  testWidgets(
    'a remembered workspace the server no longer has is forgotten and its '
    'route left for the landing workspace',
    (tester) async {
      final (container, router, workspaces) = await pumpApp(
        tester,
        initial: '/workspaces/ws-dead/inbox',
        hint: 'ws-dead',
      );
      workspaces.add([_ws('ws-1'), _ws('ws-2')]);
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/workspaces/ws-1/inbox',
      );
      expect(container.read(activeWorkspaceIdProvider), 'ws-1');
    },
  );

  testWidgets('a later list that lags a new workspace never moves the route', (
    tester,
  ) async {
    final (container, router, workspaces) = await pumpApp(
      tester,
      initial: '/workspaces/ws-1/inbox',
      hint: 'ws-1',
    );
    workspaces.add([_ws('ws-1')]);
    await tester.pumpAndSettle();
    // A workspace created this session, before the list includes it.
    router.go('/workspaces/ws-new/inbox');
    await tester.pumpAndSettle();
    workspaces.add([_ws('ws-1')]);
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/workspaces/ws-new/inbox',
    );
    expect(container.read(activeWorkspaceIdProvider), 'ws-new');
  });
}
