import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConnectionMode', () {
    test('fromName parses known values and defaults to local', () {
      expect(ServerConnectionMode.fromName('remote'), ServerConnectionMode.remote);
      expect(ServerConnectionMode.fromName('local'), ServerConnectionMode.local);
      expect(ServerConnectionMode.fromName(null), ServerConnectionMode.local);
      expect(ServerConnectionMode.fromName('bogus'), ServerConnectionMode.local);
    });
  });

  group('ServerConnectionConfig', () {
    test('isRemoteComplete needs remote mode + a non-empty URL', () {
      expect(ServerConnectionConfig.localDefault.isRemoteComplete, isFalse);
      expect(
        const ServerConnectionConfig(mode: ServerConnectionMode.remote)
            .isRemoteComplete,
        isFalse,
      );
      expect(
        const ServerConnectionConfig(
          mode: ServerConnectionMode.remote,
          remoteUrl: 'wss://host:9030/rpc',
        ).isRemoteComplete,
        isTrue,
      );
    });

    group('normalizeRemoteUrl', () {
      String? norm(String raw) => ServerConnectionConfig.normalizeRemoteUrl(raw);

      test('appends the required /rpc path when missing', () {
        // The exact value a user types in the setup screen — no path.
        expect(norm('ws://127.0.0.1:9030'), 'ws://127.0.0.1:9030/rpc');
        expect(norm('ws://127.0.0.1:9030/'), 'ws://127.0.0.1:9030/rpc');
        expect(norm('wss://host:9030'), 'wss://host:9030/rpc');
      });

      test('maps http(s) → ws(s) and strips query/fragment', () {
        // Recovers the stray scheme + empty fragment from older saved values.
        expect(norm('http://127.0.0.1:9030#'), 'ws://127.0.0.1:9030/rpc');
        expect(norm('https://host:9030/rpc?x=1'), 'wss://host:9030/rpc');
      });

      test('assumes ws:// for a bare host:port', () {
        expect(norm('127.0.0.1:9030'), 'ws://127.0.0.1:9030/rpc');
        expect(norm('localhost:9030/rpc'), 'ws://localhost:9030/rpc');
      });

      test('preserves an explicit non-root path and omits an absent port', () {
        expect(norm('wss://example.com/cc/rpc'), 'wss://example.com/cc/rpc');
        expect(norm('wss://example.com/rpc'), 'wss://example.com/rpc');
      });

      test('trims surrounding whitespace', () {
        expect(norm('  ws://127.0.0.1:9030  '), 'ws://127.0.0.1:9030/rpc');
      });

      test('returns null for empty or non-WebSocket input', () {
        expect(norm(''), isNull);
        expect(norm('   '), isNull);
        expect(norm('ftp://host:9030'), isNull);
      });
    });

    test('value equality + copyWith', () {
      const a = ServerConnectionConfig(
        mode: ServerConnectionMode.remote,
        remoteUrl: 'wss://a/rpc',
        remoteDeviceId: 'd1',
      );
      expect(a.copyWith(), a);
      expect(
        a.copyWith(mode: ServerConnectionMode.local).mode,
        ServerConnectionMode.local,
      );
      expect(a.copyWith(remoteUrl: 'wss://b/rpc').remoteUrl, 'wss://b/rpc');
      expect(a == a.copyWith(remoteDeviceId: 'd2'), isFalse);
    });
  });

  group('ServerConnectionStore', () {
    late ServerConnectionStore store;

    setUp(() {
      store = ServerConnectionStore(
        AppPreferences.inMemory(),
        SecureStore.inMemory(),
      );
    });

    test('is unconfigured on a fresh install and defaults to local', () {
      expect(store.isConfigured, isFalse);
      final config = store.read();
      expect(config.mode, ServerConnectionMode.local);
      expect(config.remoteUrl, '');
      expect(config.remoteDeviceId, ServerConnectionConfig.defaultRemoteDeviceId);
    });

    test('saving the local default marks it configured', () async {
      await store.save(ServerConnectionConfig.localDefault);
      expect(store.isConfigured, isTrue);
      expect(store.read().mode, ServerConnectionMode.local);
    });

    test('round-trips a remote config and its pairing key', () async {
      await store.save(
        const ServerConnectionConfig(
          mode: ServerConnectionMode.remote,
          remoteUrl: 'wss://example:9030/rpc',
          remoteDeviceId: 'studio-mac',
        ),
        psk: 'super-secret-key',
      );

      final config = store.read();
      expect(config.mode, ServerConnectionMode.remote);
      expect(config.remoteUrl, 'wss://example:9030/rpc');
      expect(config.remoteDeviceId, 'studio-mac');
      expect(await store.readPsk(), 'super-secret-key');
    });

    test('an empty pairing key clears the stored secret', () async {
      await store.save(
        const ServerConnectionConfig(mode: ServerConnectionMode.remote),
        psk: 'first',
      );
      expect(await store.readPsk(), 'first');

      await store.save(
        const ServerConnectionConfig(mode: ServerConnectionMode.remote),
        psk: '',
      );
      expect(await store.readPsk(), isNull);
    });

    test('a null pairing key leaves the stored secret untouched', () async {
      await store.save(
        const ServerConnectionConfig(mode: ServerConnectionMode.remote),
        psk: 'keepme',
      );
      // Save again WITHOUT passing psk — must not wipe it.
      await store.save(
        const ServerConnectionConfig(
          mode: ServerConnectionMode.remote,
          remoteUrl: 'wss://changed/rpc',
        ),
      );
      expect(await store.readPsk(), 'keepme');
      expect(store.read().remoteUrl, 'wss://changed/rpc');
    });
  });
}
