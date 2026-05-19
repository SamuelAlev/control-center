import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../fakes/fake_filesystem_port.dart';
import '../../../helpers/fake_rpc_client.dart';

const String _wsKey = 'active_workspace_id';
const String _wsNameKey = 'active_workspace_name';
const String _wsHasLogoKey = 'active_workspace_has_logo';

Map<String, dynamic> _wsJson(String id, String name, {String? logoPath}) => {
  'id': id,
  'name': name,
  'logo_path': ?logoPath,
  'created_at': DateTime(2024).toIso8601String(),
  'updated_at': DateTime(2024).toIso8601String(),
};

void main() {
  group('ActiveWorkspaceIdNotifier', () {
    late FakeRpcHost host;
    late RemoteRpcClient client;

    setUp(() {
      host = FakeRpcHost();
      client = host.client();
    });

    test('build returns null when no workspaces exist', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      host.emit('workspace.watchAll', {'workspaces': <Map<String, dynamic>>[]});
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, null);
    });

    test('build returns first workspace id when no saved preference', () async {
      final prefs = AppPreferences.inMemory({});

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      host.emit('workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'First'), _wsJson('ws-2', 'Second')],
      });
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, 'ws-1');
    });

    test('build returns saved workspace id when valid', () async {
      final prefs = AppPreferences.inMemory({_wsKey: 'ws-2'});

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      host.emit('workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'First'), _wsJson('ws-2', 'Second')],
      });
      await Future.delayed(const Duration(milliseconds: 50));
      final id = container.read(activeWorkspaceIdProvider);
      expect(id, 'ws-2');
    });

    test(
      'build falls back to first when saved workspace no longer exists',
      () async {
        final prefs = AppPreferences.inMemory({_wsKey: 'ws-gone'});

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            rpcClientProvider.overrideWithValue(client),
          ],
        );
        addTearDown(container.dispose);
        container.listen(activeWorkspaceIdProvider, (_, _) {});
        container.listen(workspacesProvider, (_, _) {});
        host.emit('workspace.watchAll', {
          'workspaces': [_wsJson('ws-1', 'First')],
        });
        await Future.delayed(const Duration(milliseconds: 50));
        final id = container.read(activeWorkspaceIdProvider);
        expect(id, 'ws-1');
        // The correction must be PERSISTED, not just held in memory: the
        // optimistic branch re-reads the pref on every build, so leaving
        // 'ws-gone' on disk brings it back on the next connect.
        expect(prefs.getString(_wsKey), 'ws-1');
      },
    );

    test(
      'a persisted id this server does not know is dropped from prefs',
      () async {
        // The reported failure: a client whose `active_workspace_id` predates
        // a data-dir reset connects to a server that has never registered it.
        // Left in prefs, the id rode the pre-list window on every reconnect —
        // the router landed on `/workspaces/<dead-id>/…` and every
        // workspace-scoped subscription was refused by the server.
        final prefs = AppPreferences.inMemory({_wsKey: 'ws-stale'});

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            rpcClientProvider.overrideWithValue(client),
          ],
        );
        addTearDown(container.dispose);
        container.listen(activeWorkspaceIdProvider, (_, _) {});
        container.listen(workspacesProvider, (_, _) {});

        // Before the list arrives the stale id is still exposed — that window
        // is deliberate (it stops the workspace chip flashing empty).
        expect(container.read(activeWorkspaceIdProvider), 'ws-stale');

        host.emit('workspace.watchAll', {
          'workspaces': <Map<String, dynamic>>[],
        });
        await Future.delayed(const Duration(milliseconds: 50));

        expect(container.read(activeWorkspaceIdProvider), null);
        expect(prefs.getString(_wsKey), null);
      },
    );

    test('setActive persists and updates state', () async {
      final prefs = AppPreferences.inMemory({});

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      host.emit('workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'First')],
      });
      await Future.delayed(const Duration(milliseconds: 50));

      await container
          .read(activeWorkspaceIdProvider.notifier)
          .setActive('ws-1');

      expect(container.read(activeWorkspaceIdProvider), 'ws-1');
      expect(prefs.getString(_wsKey), 'ws-1');
    });

    test(
      'build exposes the persisted id immediately, before the list loads',
      () async {
        // Regression: the chip flashed "no workspace" for a few seconds on a
        // cold start because the persisted id was discarded while the stream's
        // first emit was pending. The id must surface synchronously.
        final prefs = AppPreferences.inMemory({_wsKey: 'ws-2'});

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            rpcClientProvider.overrideWithValue(client),
          ],
        );
        addTearDown(container.dispose);

        // Read synchronously — the workspaces stream has not emitted yet.
        expect(container.read(activeWorkspaceIdProvider), 'ws-2');

        // And it still resolves to the same id once the list loads.
        container.listen(workspacesProvider, (_, _) {});
        host.emit('workspace.watchAll', {
          'workspaces': [_wsJson('ws-1', 'First'), _wsJson('ws-2', 'Second')],
        });
        await Future.delayed(const Duration(milliseconds: 50));
        expect(container.read(activeWorkspaceIdProvider), 'ws-2');
      },
    );
  });

  group('activeWorkspaceDisplayProvider', () {
    late FakeRpcHost host;
    late RemoteRpcClient client;

    setUp(() {
      host = FakeRpcHost();
      client = host.client();
    });

    test('falls back to the cached display while the list loads', () async {
      final prefs = AppPreferences.inMemory({
        _wsKey: 'ws-1',
        _wsNameKey: 'Cached name',
        _wsHasLogoKey: true,
      });

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      // Before the stream emits, the cached display is used (no "no workspace").
      final cached = container.read(activeWorkspaceDisplayProvider);
      expect(cached?.name, 'Cached name');
      expect(cached?.hasLogo, isTrue);

      // Once the real row loads, it takes over.
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      host.emit('workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'Real name')],
      });
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(activeWorkspaceDisplayProvider)?.name, 'Real name');
    });

    test('returns null once the list loads with no workspaces', () async {
      final prefs = AppPreferences.inMemory({});

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      host.emit('workspace.watchAll', {'workspaces': <Map<String, dynamic>>[]});
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container.read(activeWorkspaceDisplayProvider), isNull);
    });
  });

  group('workspaceDisplayCacheProvider', () {
    late FakeRpcHost host;
    late RemoteRpcClient client;

    setUp(() {
      host = FakeRpcHost();
      client = host.client();
    });

    test('persists name + logo when the active workspace resolves', () async {
      final prefs = AppPreferences.inMemory({});

      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      // Keep the write-through cache alive, then let the workspace resolve.
      container.listen(workspaceDisplayCacheProvider, (_, _) {});
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      host.emit('workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'First', logoPath: '/icon.png')],
      });
      await Future.delayed(const Duration(milliseconds: 50));

      expect(prefs.getString(_wsKey), 'ws-1');
      expect(prefs.getString(_wsNameKey), 'First');
      expect(prefs.getBool(_wsHasLogoKey), isTrue);
    });
  });

  group('ActiveRepoIdNotifier', () {
    late FakeRpcHost host;
    late RemoteRpcClient client;

    setUp(() {
      host = FakeRpcHost();
      client = host.client();
    });

    test('build returns null when no active workspace', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      final repoId = container.read(activeRepoIdProvider);
      expect(repoId, isNull);
    });

    test('setActive returns early when no workspace is active', () async {
      final prefs = AppPreferences.inMemory({});
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(client),
        ],
      );
      addTearDown(container.dispose);

      await container.read(activeRepoIdProvider.notifier).setActive('repo-1');
      expect(container.read(activeRepoIdProvider), isNull);
    });

    test(
      'setActive flips state synchronously, before the persist resolves',
      () async {
        // Regression: setActive() persisted to shared_preferences BEFORE flipping
        // in-memory state. openPrInRepo() / the command palette call setActive
        // WITHOUT awaiting and navigate immediately, so the PR detail screen built
        // against the PREVIOUS active repo — the PR-review surface then resolved
        // the wrong owner/repo and the host 404'd a cross-repo PR. The flip must
        // be visible synchronously, before the (awaited) persist completes.
        final prefs = AppPreferences.inMemory({_wsKey: 'ws-1'});

        final container = ProviderContainer(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            rpcClientProvider.overrideWithValue(client),
          ],
        );
        addTearDown(container.dispose);

        // Active workspace resolves synchronously from the persisted id.
        expect(container.read(activeWorkspaceIdProvider), 'ws-1');

        // Fire-and-forget, exactly like openPrInRepo(): do NOT await.
        final pending = container
            .read(activeRepoIdProvider.notifier)
            .setActive('repo-x');

        // The flip is already visible — before the persist future resolves.
        expect(container.read(activeRepoIdProvider), 'repo-x');

        await pending;
        expect(prefs.getString('active_repo_id:ws-1'), 'repo-x');
      },
    );
  });

  group('CreateWorkspaceNotifier', () {
    testWidgets('create does NOT navigate away from the current route', (
      tester,
    ) async {
      // Regression: create() used to `go(inboxRoute(id))` through
      // rootNavigatorKey the moment the insert landed. Onboarding's workspace
      // step creates the workspace MID-FLOW — the navigation unmounted the
      // onboarding screen and skipped the sandbox / adapter / voice-model /
      // embedding steps. Navigation is now the caller's business; this pins
      // the notifier staying put with a live router attached to
      // [rootNavigatorKey] standing at /onboarding.
      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/onboarding',
        routes: [
          GoRoute(path: '/onboarding', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '/workspaces/:workspaceId/inbox',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      addTearDown(router.dispose);

      final repository = FakeWorkspaceRepository();
      addTearDown(repository.dispose);
      final activeNotifier = _RecordingActiveWorkspaceIdNotifier();

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
            workspaceRepositoryProvider.overrideWithValue(repository),
            domainEventBusProvider.overrideWithValue(DomainEventBus()),
            workspaceFilesystemPortProvider.overrideWithValue(
              FakeFilesystemPort(),
            ),
            activeWorkspaceIdProvider.overrideWith(() => activeNotifier),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pump();
      expect(router.routeInformationProvider.value.uri.path, '/onboarding');

      final id = await capturedRef
          .read(createWorkspaceProvider.notifier)
          .create(name: 'Acme');
      await tester.pump();

      expect(id, isNotNull);
      expect(repository.saved.single.name, 'Acme');
      // The active id is pre-seeded (so onboarding's finish lands on the new
      // workspace's inbox via the route sync) ...
      expect(activeNotifier.setTo, id);
      // ... but the ROUTE does not move: onboarding still has steps to show.
      expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    });
  });
}

/// Records [setActive] without watching the private bootstrap stream.
class _RecordingActiveWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  String? setTo;

  @override
  String? build() => null;

  @override
  Future<void> setActive(String id) async {
    setTo = id;
    state = id;
  }
}
