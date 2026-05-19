import 'package:cc_domain/cc_domain.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/server/server_connection_config.dart';
import 'package:flutter_test/flutter_test.dart';

ConnectionDescriptor _descriptor(
  String serverId, {
  String name = 'Test server',
  String fingerprint = 'fp-aaaa',
}) => ConnectionDescriptor(
  serverId: serverId,
  serverName: name,
  fingerprint: fingerprint,
  paths: const [LanPath(host: '192.168.1.10', port: 9030, tls: false)],
);

ServerEntry _entry(String serverId, {String fingerprint = 'fp-aaaa'}) =>
    ServerEntry(
      descriptor: _descriptor(serverId, fingerprint: fingerprint),
      deviceId: 'dev-1',
    );

void main() {
  group('ServerConnectionMode', () {
    test('fromName parses known values and defaults to local', () {
      expect(
        ServerConnectionMode.fromName('remote'),
        ServerConnectionMode.remote,
      );
      expect(
        ServerConnectionMode.fromName('local'),
        ServerConnectionMode.local,
      );
      expect(ServerConnectionMode.fromName(null), ServerConnectionMode.local);
      expect(
        ServerConnectionMode.fromName('bogus'),
        ServerConnectionMode.local,
      );
    });
  });

  group('normalizeServerUrl', () {
    test('appends the required /rpc path when missing', () {
      // The exact value a user types in the setup screen — no path.
      expect(
        normalizeServerUrl('ws://127.0.0.1:9030'),
        'ws://127.0.0.1:9030/rpc',
      );
      expect(
        normalizeServerUrl('ws://127.0.0.1:9030/'),
        'ws://127.0.0.1:9030/rpc',
      );
      expect(normalizeServerUrl('wss://host:9030'), 'wss://host:9030/rpc');
    });

    test('maps http(s) → ws(s) and strips query/fragment', () {
      expect(
        normalizeServerUrl('http://127.0.0.1:9030#'),
        'ws://127.0.0.1:9030/rpc',
      );
      expect(
        normalizeServerUrl('https://host:9030/rpc?x=1'),
        'wss://host:9030/rpc',
      );
    });

    test('assumes ws:// for a bare host:port', () {
      expect(normalizeServerUrl('127.0.0.1:9030'), 'ws://127.0.0.1:9030/rpc');
      expect(
        normalizeServerUrl('localhost:9030/rpc'),
        'ws://localhost:9030/rpc',
      );
    });

    test('preserves an explicit non-root path and omits an absent port', () {
      expect(
        normalizeServerUrl('wss://example.com/cc/rpc'),
        'wss://example.com/cc/rpc',
      );
      expect(
        normalizeServerUrl('wss://example.com/rpc'),
        'wss://example.com/rpc',
      );
    });

    test('rejects empty input, bad schemes and missing hosts', () {
      expect(normalizeServerUrl(''), isNull);
      expect(normalizeServerUrl('   '), isNull);
      expect(normalizeServerUrl('ftp://host:1'), isNull);
      expect(normalizeServerUrl('ws://'), isNull);
    });
  });

  group('ServerEntry', () {
    test('round-trips through JSON without secrets', () {
      final entry = _entry('srv-1');
      final restored = ServerEntry.fromJson(entry.toJson());
      expect(restored, entry);
      expect(restored.pinnedFingerprint, 'fp-aaaa');
      expect(entry.toJson().toString(), isNot(contains('psk')));
    });

    test('pin defaults to the descriptor fingerprint and survives a '
        'descriptor refresh (a refresh must never rotate trust)', () {
      final entry = _entry('srv-1');
      expect(entry.pinnedFingerprint, 'fp-aaaa');
      final refreshed = entry.withDescriptor(
        _descriptor('srv-1', fingerprint: 'fp-EVIL'),
      );
      expect(refreshed.pinnedFingerprint, 'fp-aaaa', reason: 'pin kept');
      expect(refreshed.descriptor.fingerprint, 'fp-EVIL');
    });
  });

  group('ServerConnectionStore', () {
    late AppPreferences prefs;
    late SecureStore secure;
    late ServerConnectionStore store;

    setUp(() {
      prefs = AppPreferences.inMemory();
      secure = SecureStore.inMemory();
      store = ServerConnectionStore(prefs, secure);
    });

    test('starts unconfigured with no entries', () {
      expect(store.isConfigured, isFalse);
      expect(store.readEntries(), isEmpty);
      expect(store.readActive(), isNull);
      expect(store.readMode(), ServerConnectionMode.local);
    });

    test('setMode marks the store configured', () async {
      await store.setMode(ServerConnectionMode.remote);
      expect(store.isConfigured, isTrue);
      expect(store.readMode(), ServerConnectionMode.remote);
    });

    test('upsertEntry adds, replaces by server id and stores the PSK in the '
        'secure store only', () async {
      await store.upsertEntry(_entry('srv-1'), psk: 'secret-1');
      await store.upsertEntry(_entry('srv-2'), psk: 'secret-2');
      expect(store.readEntries(), hasLength(2));
      expect(await store.readPsk('srv-1'), 'secret-1');
      expect(
        prefs.getString(ServerConnectionStore.entriesKey),
        isNot(contains('secret-1')),
        reason: 'PSKs never land in prefs',
      );

      // Replacing keeps the list at 2 and leaves the PSK untouched.
      await store.upsertEntry(_entry('srv-1', fingerprint: 'fp-bbbb'));
      expect(store.readEntries(), hasLength(2));
      expect(store.entry('srv-1')!.pinnedFingerprint, 'fp-bbbb');
      expect(await store.readPsk('srv-1'), 'secret-1');

      // An empty PSK deletes the stored secret.
      await store.upsertEntry(_entry('srv-1'), psk: '');
      expect(await store.readPsk('srv-1'), isNull);
    });

    test(
      'readActive prefers the chosen server and falls back to the first',
      () async {
        await store.upsertEntry(_entry('srv-1'));
        await store.upsertEntry(_entry('srv-2'));
        expect(
          store.readActive()!.serverId,
          'srv-1',
          reason: 'fallback: first',
        );
        await store.setActiveServer('srv-2');
        expect(store.readActive()!.serverId, 'srv-2');
      },
    );

    test('updateDescriptor refreshes paths but keeps the TOFU pin; a '
        'descriptor with the wrong server id is ignored', () async {
      await store.upsertEntry(_entry('srv-1'));
      await store.updateDescriptor(
        'srv-1',
        _descriptor('srv-1', name: 'Renamed', fingerprint: 'fp-EVIL'),
      );
      final updated = store.entry('srv-1')!;
      expect(updated.name, 'Renamed');
      expect(updated.pinnedFingerprint, 'fp-aaaa', reason: 'pin kept');

      await store.updateDescriptor('srv-1', _descriptor('srv-OTHER'));
      expect(
        store.entry('srv-1')!.name,
        'Renamed',
        reason: 'id mismatch → no-op',
      );
    });

    test(
      'removeEntry drops the entry, its PSK and the active pointer',
      () async {
        await store.upsertEntry(_entry('srv-1'), psk: 'secret-1');
        await store.setActiveServer('srv-1');
        await store.removeEntry('srv-1');
        expect(store.readEntries(), isEmpty);
        expect(await store.readPsk('srv-1'), isNull);
        expect(store.readActiveServerId(), isNull);
      },
    );

    test('clear forgets entries, PSKs, active pointer and the mode', () async {
      await store.setMode(ServerConnectionMode.remote);
      await store.upsertEntry(_entry('srv-1'), psk: 'secret-1');
      await store.setActiveServer('srv-1');
      await store.clear();
      expect(store.isConfigured, isFalse);
      expect(store.readEntries(), isEmpty);
      expect(await store.readPsk('srv-1'), isNull);
      expect(store.readActiveServerId(), isNull);
    });

    test('corrupt entries JSON reads as empty instead of throwing', () async {
      await prefs.setString(ServerConnectionStore.entriesKey, '{not json');
      expect(store.readEntries(), isEmpty);
      await prefs.setString(ServerConnectionStore.entriesKey, '[{"bogus":1}]');
      expect(store.readEntries(), isEmpty);
    });
  });
}
