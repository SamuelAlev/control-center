import 'package:cc_domain/cc_domain.dart'
    show ConnectionDescriptor, LoopbackPath;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/bootstrap/session_overrides.dart';
import 'package:control_center/core/offline/offline_queue_provider.dart';
import 'package:control_center/core/providers/server_switch_provider.dart';
import 'package:control_center/core/providers/session_scope_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/storage/observable_key_value_backend.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/guards.dart' show OnboardingGate;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_rpc_client.dart';

ServerConnectionSupervisor _supervisor(String serverId) =>
    ServerConnectionSupervisor(
      descriptor: ConnectionDescriptor(
        serverId: serverId,
        serverName: 'Server',
        fingerprint: 'fp',
        paths: const [LoopbackPath(port: 9030)],
      ),
      deviceId: 'dev',
      psk: 'psk',
    );

/// A client whose `identity.me` answers [userId], or fails when it is null.
RemoteRpcClient _identityClient(String? userId) {
  final host = FakeRpcHost()
    ..onCall = (op, args) {
      if (op != 'identity.me' || userId == null) {
        throw RemoteRpcException(-32000, 'unavailable');
      }
      return {
        'user': {'id': userId, 'handle': 'me'},
        'device_id': 'dev',
        'memberships': const <Object>[],
      };
    };
  return host.client();
}

/// The container a composition root builds: only [sessionOverrides], over a
/// device store shared by every session on this device.
ProviderContainer _session(
  ObservableKeyValueBackend backend,
  SessionScope? scope,
) {
  final container = ProviderContainer(
    overrides: sessionOverrides(
      client: fakeRpcClient(),
      supervisor: _supervisor(scope?.serverId ?? 'srv-a'),
      mediaProxy: null,
      prefsBackend: backend,
      secureStore: SecureStore.inMemory(),
      scope: scope,
      switchServer: (_) async {},
      returnToSignIn: () async {},
    ),
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final scopeA = SessionScope(serverId: 'srv-a', userId: 'usr-1');
  final scopeB = SessionScope(serverId: 'srv-b', userId: 'usr-1');

  group('sessionOverrides scoping', () {
    late ObservableKeyValueBackend backend;
    late AppPreferences device;

    setUp(() {
      backend = ObservableKeyValueBackend(InMemoryStorage());
      device = AppPreferences(backend);
    });

    test('installs the session scope over the shared device store', () {
      final container = _session(backend, scopeA);

      expect(container.read(sessionScopeProvider), scopeA);
      // The preferences the app reads are the device store itself, so a
      // choice made on a pre-app surface is the one the session sees.
      expect(container.read(keyValueBackendProvider), same(backend));
    });

    test(
      'a remembered workspace is read and written under its own scope only',
      () async {
        final a = _session(backend, scopeA);
        await a.read(activeWorkspaceIdProvider.notifier).setActive('ws-a');

        expect(device.getString(scopeA.key(activeWorkspaceIdPrefKey)), 'ws-a');
        expect(device.getString(activeWorkspaceIdPrefKey), isNull);

        // A later session on another server, over the same device store.
        final b = _session(backend, scopeB);
        expect(b.read(activeWorkspaceIdProvider), isNull);

        final aAgain = _session(backend, scopeA);
        expect(aAgain.read(activeWorkspaceIdProvider), 'ws-a');
      },
    );

    test('an unknown scope neither reads nor writes any cache', () async {
      // Every cache a scoped session could find: this server's, another
      // server's and the unscoped keys older builds wrote.
      await device.setString(scopeA.key(activeWorkspaceIdPrefKey), 'ws-a');
      await device.setString(activeWorkspaceIdPrefKey, 'ws-legacy');
      await device.setBool(scopeA.key('onboarding_complete'), value: true);
      await device.setBool('onboarding_complete', value: true);
      final before = {for (final k in backend.keys) k: backend.get(k)};

      final container = _session(backend, null);

      expect(container.read(sessionScopeProvider), isNull);
      // No remembered workspace is offered as a landing hint...
      expect(container.read(activeWorkspaceIdProvider), isNull);
      // ...and the gate holds the splash until the live checks settle.
      expect(container.read(onboardingGateProvider), OnboardingGate.loading);

      // Adopting and forgetting a workspace only changes memory.
      final notifier = container.read(activeWorkspaceIdProvider.notifier);
      await notifier.setActive('ws-live');
      expect(container.read(activeWorkspaceIdProvider), 'ws-live');
      await notifier.forget();
      expect(container.read(activeWorkspaceIdProvider), isNull);

      expect({for (final k in backend.keys) k: backend.get(k)}, before);
    });
  });

  group('session admission', () {
    test(
      'the scope names the descriptor server and the identity user',
      () async {
        final scope = await resolveSessionScope(
          _identityClient('usr-7'),
          _supervisor('srv-9'),
        );
        expect(scope, SessionScope(serverId: 'srv-9', userId: 'usr-7'));
      },
    );

    test('the web gate admits a connection whose user resolves', () async {
      var disposed = 0;
      final scope = await admitSessionScope(
        _identityClient('usr-1'),
        _supervisor('srv-a'),
        dispose: () async => disposed++,
      );
      expect(scope, scopeA);
      expect(disposed, 0);
    });

    test('the web gate disposes and rethrows when identity.me fails', () async {
      var disposed = 0;
      await expectLater(
        admitSessionScope(
          _identityClient(null),
          _supervisor('srv-a'),
          dispose: () async => disposed++,
        ),
        throwsA(isA<RemoteRpcException>()),
      );
      expect(disposed, 1);
    });

    test('the web gate refuses an identity without a user id', () async {
      var disposed = 0;
      await expectLater(
        admitSessionScope(
          _identityClient(''),
          _supervisor('srv-a'),
          dispose: () async => disposed++,
        ),
        throwsArgumentError,
      );
      expect(disposed, 1);
    });

    test('the desktop keeps the session without a scope when identity.me '
        'fails', () async {
      final errors = <Object>[];
      final scope = await tryResolveSessionScope(
        _identityClient(null),
        _supervisor('srv-a'),
        onError: errors.add,
      );
      expect(scope, isNull);
      expect(errors, hasLength(1));

      expect(
        await tryResolveSessionScope(
          _identityClient('usr-1'),
          _supervisor('srv-a'),
        ),
        scopeA,
      );
    });
  });
  group('leaving the session drops the offline queue', () {
    late ObservableKeyValueBackend backend;
    late List<String> left;

    ProviderContainer session() {
      final container = ProviderContainer(
        overrides: sessionOverrides(
          client: fakeRpcClient(),
          supervisor: _supervisor('srv-a'),
          mediaProxy: null,
          prefsBackend: backend,
          secureStore: SecureStore.inMemory(),
          scope: scopeA,
          switchServer: (id) async => left.add('switch:$id'),
          returnToSignIn: () async => left.add('sign-in'),
        ),
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<void> queueOne(ProviderContainer c) => c
        .read(offlineQueueControllerProvider.notifier)
        .enqueue(
          workspaceId: 'ws',
          idempotencyKey: 'k1',
          op: 'tickets.patch',
          args: const {'workspace_id': 'ws'},
        );

    setUp(() {
      backend = ObservableKeyValueBackend(InMemoryStorage());
      left = [];
    });

    test('a server switch drops it before switching', () async {
      final a = session();
      await queueOne(a);
      expect(a.read(offlineQueueControllerProvider), 1);

      await a.read(serverSwitchHandlerProvider)('srv-b');

      expect(left, ['switch:srv-b']);
      expect(a.read(offlineQueueControllerProvider), 0);
      // Even the same user back on the same server finds nothing to replay.
      expect(session().read(offlineMutationQueueProvider).length, 0);
    });

    test('returning to sign-in drops it', () async {
      final a = session();
      await queueOne(a);

      await a.read(returnToServerSignInProvider)!();

      expect(left, ['sign-in']);
      expect(session().read(offlineMutationQueueProvider).length, 0);
    });
  });
}
