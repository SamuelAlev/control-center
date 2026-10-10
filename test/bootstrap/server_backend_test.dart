import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/bootstrap/server_backend.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decision tests for [resolveServerBackend]: which backend a boot or an
/// in-app switch produces, and above all that the bundled `cc_server` is
/// started ONLY when local is the target. No process, socket or window —
/// every source is a recording fake.

ServerEntry _entry(String serverId) => ServerEntry(
  descriptor: ConnectionDescriptor(
    serverId: serverId,
    serverName: 'Server $serverId',
    fingerprint: 'fp-$serverId',
    paths: const [LanPath(host: '192.168.1.10', port: 9030, tls: false)],
  ),
  deviceId: 'dev-1',
);

/// Records every source call and hands back inert backends.
class _Sources {
  final List<String> calls = [];
  final List<ServerBackend> _made = [];
  Object? localError;
  Object? remoteError;

  bool get startedLocal => calls.contains('local');

  ServerBackend _backend(String serverId) {
    final supervisor = ServerConnectionSupervisor(
      descriptor: _entry(serverId).descriptor,
      deviceId: 'dev-1',
      psk: 'psk',
    );
    final backend = ServerBackend(
      client: ResilientRpcClient(supervisor),
      supervisor: supervisor,
    );
    _made.add(backend);
    return backend;
  }

  ServerBackendSources get sources => ServerBackendSources(
    startLocal: () async {
      calls.add('local');
      if (localError case final error?) {
        throw error;
      }
      return _backend('local');
    },
    connectRemote: (store, entry, psk) async {
      calls.add('remote:${entry.serverId}:$psk');
      if (remoteError case final error?) {
        throw error;
      }
      return _backend(entry.serverId);
    },
    runSetup: (store, {error}) async {
      calls.add(error == null ? 'setup' : 'setup:error');
      return _backend('setup');
    },
  );

  Future<void> dispose() async {
    for (final backend in _made) {
      await backend.client.close();
    }
  }
}

void main() {
  late AppPreferences prefs;
  late SecureStore secure;
  late ServerConnectionStore store;
  late _Sources fakes;

  setUp(() {
    prefs = AppPreferences.inMemory();
    secure = SecureStore.inMemory();
    store = ServerConnectionStore(prefs, secure);
    fakes = _Sources();
  });

  tearDown(() => fakes.dispose());

  Future<ServerBackend> resolve({String? forceServerId}) =>
      resolveServerBackend(
        prefs: prefs,
        secureStore: secure,
        forceServerId: forceServerId,
        sources: fakes.sources,
      );

  Future<void> pair(String serverId, {String? psk = 'key'}) =>
      store.upsertEntry(_entry(serverId), psk: psk);

  group('boot', () {
    test('a configured remote server is connected without starting the '
        'bundled server', () async {
      await pair('srv-a');
      await store.setMode(ServerConnectionMode.remote);
      await store.setActiveServer('srv-a');

      await resolve();

      expect(fakes.calls, ['remote:srv-a:key']);
      expect(fakes.startedLocal, isFalse);
    });

    test('a failed remote connect asks the user rather than starting the '
        'bundled server', () async {
      await pair('srv-a');
      await store.setMode(ServerConnectionMode.remote);
      fakes.remoteError = StateError('unreachable');

      await resolve();

      expect(fakes.calls, ['remote:srv-a:key', 'setup:error']);
      expect(fakes.startedLocal, isFalse);
    });

    test('a remote entry without a stored key asks the user', () async {
      await pair('srv-a', psk: null);
      await store.setMode(ServerConnectionMode.remote);

      await resolve();

      expect(fakes.calls, ['setup']);
    });

    test('local mode starts the bundled server and nothing else', () async {
      await pair('srv-a');
      await store.setMode(ServerConnectionMode.local);

      await resolve();

      expect(fakes.calls, ['local']);
    });

    test('a failed local start falls back to the setup screen', () async {
      await store.setMode(ServerConnectionMode.local);
      fakes.localError = StateError('no cc_server');

      await resolve();

      expect(fakes.calls, ['local', 'setup:error']);
    });

    test('first run shows the setup screen and starts nothing', () async {
      await resolve();

      expect(fakes.calls, ['setup']);
    });
  });

  group('in-app switch', () {
    test('local to remote connects the paired server without starting the '
        'bundled server, then persists the choice', () async {
      await pair('srv-a');
      await store.setMode(ServerConnectionMode.local);

      await resolve(forceServerId: 'srv-a');

      expect(fakes.calls, ['remote:srv-a:key']);
      expect(store.readMode(), ServerConnectionMode.remote);
      expect(store.readActiveServerId(), 'srv-a');
    });

    test('a failed switch throws, keeps the live choice persisted and never '
        'shows the setup screen or starts the bundled server', () async {
      await pair('srv-a');
      await store.setMode(ServerConnectionMode.local);
      fakes.remoteError = StateError('unreachable');

      await expectLater(resolve(forceServerId: 'srv-a'), throwsStateError);

      expect(fakes.calls, ['remote:srv-a:key']);
      expect(store.readMode(), ServerConnectionMode.local);
      expect(store.readActiveServerId(), isNull);
    });

    test('an unknown server id throws instead of falling back to the '
        'persisted local mode (a second bundled server)', () async {
      await store.setMode(ServerConnectionMode.local);

      await expectLater(resolve(forceServerId: 'gone'), throwsStateError);

      expect(fakes.calls, isEmpty);
      expect(store.readMode(), ServerConnectionMode.local);
    });

    test('a paired server without a stored key throws instead of showing '
        'the setup screen', () async {
      await pair('srv-a', psk: null);
      await store.setMode(ServerConnectionMode.local);

      await expectLater(resolve(forceServerId: 'srv-a'), throwsStateError);

      expect(fakes.calls, isEmpty);
    });

    test('remote to local starts the bundled server on demand', () async {
      await pair('srv-a');
      await store.setMode(ServerConnectionMode.remote);
      await store.setActiveServer('srv-a');

      await resolve(forceServerId: localServerId);

      expect(fakes.calls, ['local']);
      expect(store.readMode(), ServerConnectionMode.local);
    });

    test('a failed local start keeps the remote choice persisted', () async {
      await pair('srv-a');
      await store.setMode(ServerConnectionMode.remote);
      fakes.localError = StateError('no cc_server');

      await expectLater(
        resolve(forceServerId: localServerId),
        throwsStateError,
      );

      expect(fakes.calls, ['local']);
      expect(store.readMode(), ServerConnectionMode.remote);
    });
  });
}
