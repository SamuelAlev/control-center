import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/testing/fake_workspace_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/session_scope_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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

/// Emits [data] once the queued `sub/subscribe` frames have reached [host].
///
/// `RemoteRpcClient` sends through an ordered async queue, so a snapshot
/// emitted in the same turn as `container.listen` finds no subscriber yet and
/// is dropped.
Future<void> _emitWhenSubscribed(
  FakeRpcHost host,
  String query,
  Map<String, dynamic> data,
) async {
  await Future<void>.delayed(Duration.zero);
  host.emit(query, data);
}

final _scope = SessionScope(serverId: 'srv-a', userId: 'usr-1');
String _scoped(String key) => _scope.key(key);

ProviderContainer _container(
  AppPreferences prefs,
  RemoteRpcClient client, {
  SessionScope? scope,
  bool scoped = true,
}) => ProviderContainer(
  overrides: [
    appPreferencesProvider.overrideWithValue(prefs),
    rpcClientProvider.overrideWithValue(client),
    sessionScopeProvider.overrideWithValue(scoped ? (scope ?? _scope) : null),
  ],
);

void main() {
  group('ActiveWorkspaceIdNotifier', () {
    late FakeRpcHost host;
    late RemoteRpcClient client;

    setUp(() {
      host = FakeRpcHost();
      client = host.client();
    });

    test('build is null with nothing remembered for this session', () {
      final container = _container(AppPreferences.inMemory({}), client);
      addTearDown(container.dispose);
      expect(container.read(activeWorkspaceIdProvider), isNull);
    });

    test(
      'build exposes the id remembered for this server and user immediately',
      () {
        // Regression: the chip flashed "no workspace" on a cold start because
        // the remembered id was discarded while the list was pending.
        final prefs = AppPreferences.inMemory({_scoped(_wsKey): 'ws-2'});
        final container = _container(prefs, client);
        addTearDown(container.dispose);
        expect(container.read(activeWorkspaceIdProvider), 'ws-2');
      },
    );

    test('another server or user never inherits the remembered id', () {
      // H2: an unscoped key let server B land in server A's workspace.
      final prefs = AppPreferences.inMemory({
        _scoped(_wsKey): 'ws-a',
        _wsKey: 'ws-legacy-unscoped',
      });
      for (final other in [
        SessionScope(serverId: 'srv-b', userId: 'usr-1'),
        SessionScope(serverId: 'srv-a', userId: 'usr-2'),
      ]) {
        final container = _container(prefs, client, scope: other);
        addTearDown(container.dispose);
        expect(container.read(activeWorkspaceIdProvider), isNull);
      }
      // No scope at all (identity unresolved): nothing is read either.
      final unscoped = _container(prefs, client, scoped: false);
      addTearDown(unscoped.dispose);
      expect(unscoped.read(activeWorkspaceIdProvider), isNull);
    });

    test('a lagging workspace list never overrides the route', () async {
      // The route made ws-new active; a list emission that predates it must
      // not flip the mirror back to the first workspace.
      final prefs = AppPreferences.inMemory({});
      final container = _container(prefs, client);
      addTearDown(container.dispose);
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await container
          .read(activeWorkspaceIdProvider.notifier)
          .setActive('ws-new');
      await _emitWhenSubscribed(host, 'workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'First')],
      });
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(activeWorkspaceIdProvider), 'ws-new');
    });

    test('setActive persists under the session scope', () async {
      final prefs = AppPreferences.inMemory({});
      final container = _container(prefs, client);
      addTearDown(container.dispose);

      await container
          .read(activeWorkspaceIdProvider.notifier)
          .setActive('ws-1');

      expect(container.read(activeWorkspaceIdProvider), 'ws-1');
      expect(prefs.getString(_scoped(_wsKey)), 'ws-1');
      expect(prefs.getString(_wsKey), isNull);
    });

    test('forget drops the remembered id', () async {
      final prefs = AppPreferences.inMemory({_scoped(_wsKey): 'ws-stale'});
      final container = _container(prefs, client);
      addTearDown(container.dispose);

      await container.read(activeWorkspaceIdProvider.notifier).forget();

      expect(container.read(activeWorkspaceIdProvider), isNull);
      expect(prefs.getString(_scoped(_wsKey)), isNull);
    });
  });

  group('landingWorkspaceIdFor', () {
    final ws1 = Workspace(
      id: 'ws-1',
      name: 'First',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    final ws2 = Workspace(
      id: 'ws-2',
      name: 'Second',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

    test('trusts the hint until the list loads', () {
      expect(
        landingWorkspaceIdFor(remembered: 'ws-9', workspaces: null),
        'ws-9',
      );
    });

    test('keeps a hint the server still has', () {
      expect(
        landingWorkspaceIdFor(remembered: 'ws-2', workspaces: [ws1, ws2]),
        'ws-2',
      );
    });

    test('falls back to the first workspace for a dead or missing hint', () {
      expect(
        landingWorkspaceIdFor(remembered: 'ws-gone', workspaces: [ws1, ws2]),
        'ws-1',
      );
      expect(
        landingWorkspaceIdFor(remembered: null, workspaces: [ws2]),
        'ws-2',
      );
    });

    test('is null when the server has no workspace', () {
      expect(landingWorkspaceIdFor(remembered: 'ws-1', workspaces: []), isNull);
    });
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
        _scoped(_wsKey): 'ws-1',
        _scoped(_wsNameKey): 'Cached name',
        _scoped(_wsHasLogoKey): true,
      });
      final container = _container(prefs, client);
      addTearDown(container.dispose);

      // Before the stream emits, the cached display is used (no "no workspace").
      final cached = container.read(activeWorkspaceDisplayProvider);
      expect(cached?.name, 'Cached name');
      expect(cached?.hasLogo, isTrue);

      // Once the real row loads, it takes over.
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await _emitWhenSubscribed(host, 'workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'Real name')],
      });
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(activeWorkspaceDisplayProvider)?.name, 'Real name');
    });

    test('ignores another session\'s cached display', () {
      final prefs = AppPreferences.inMemory({
        _wsKey: 'ws-1',
        _wsNameKey: 'Unscoped name',
        _scoped(_wsKey): 'ws-1',
        _scoped(_wsNameKey): 'Server A name',
      });
      final container = _container(
        prefs,
        client,
        scope: SessionScope(serverId: 'srv-b', userId: 'usr-1'),
      );
      addTearDown(container.dispose);
      expect(container.read(activeWorkspaceDisplayProvider), isNull);
    });

    test('returns null once the list loads with no workspaces', () async {
      final container = _container(AppPreferences.inMemory({}), client);
      addTearDown(container.dispose);
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await _emitWhenSubscribed(host, 'workspace.watchAll', {
        'workspaces': <Map<String, dynamic>>[],
      });
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
      final container = _container(prefs, client);
      addTearDown(container.dispose);

      // Keep the write-through cache alive, then let the workspace resolve.
      container.listen(workspaceDisplayCacheProvider, (_, _) {});
      container.listen(activeWorkspaceIdProvider, (_, _) {});
      container.listen(workspacesProvider, (_, _) {});
      await container
          .read(activeWorkspaceIdProvider.notifier)
          .setActive('ws-1');
      await _emitWhenSubscribed(host, 'workspace.watchAll', {
        'workspaces': [_wsJson('ws-1', 'First', logoPath: '/icon.png')],
      });
      await Future.delayed(const Duration(milliseconds: 50));

      expect(prefs.getString(_scoped(_wsNameKey)), 'First');
      expect(prefs.getBool(_scoped(_wsHasLogoKey)), isTrue);
      expect(prefs.getString(_wsNameKey), isNull);
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
        final prefs = AppPreferences.inMemory({_scoped(_wsKey): 'ws-1'});
        final container = _container(prefs, client);
        addTearDown(container.dispose);

        // Active workspace resolves synchronously from the remembered id.
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

      final host = FakeRpcHost()
        ..onCall = (op, args) {
          expect(op, 'workspace.create');
          expect(args['name'], 'Acme');
          return {
            'workspace': {
              'id': 'ws-acme',
              'name': args['name'],
              'created_at': DateTime(2024).toIso8601String(),
              'updated_at': DateTime(2024).toIso8601String(),
            },
          };
        };
      addTearDown(host.close);
      final client = host.client();
      final repository = FakeWorkspaceRepository();
      addTearDown(repository.dispose);
      final activeNotifier = _RecordingActiveWorkspaceIdNotifier();

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
            rpcClientProvider.overrideWithValue(client),
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

      expect(id, 'ws-acme');
      // The active id is pre-seeded (so onboarding's finish lands on the new
      // workspace's inbox via the route sync) ...
      expect(activeNotifier.setTo, id);
      // ... but the ROUTE does not move: onboarding still has steps to show.
      expect(router.routeInformationProvider.value.uri.path, '/onboarding');
    });
  });
}

/// Records [setActive] without reading any remembered id.
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
