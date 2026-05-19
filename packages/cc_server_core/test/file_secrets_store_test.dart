import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';

void main() {
  group('FileSecretsStore', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('file_secrets_store_test');
    });

    tearDown(() => deleteDirBestEffort(tmp));

    File secretsFile() => File('${tmp.path}/${FileSecretsStore.fileName}');

    test('every tenant round-trips through one secrets.json', () async {
      // Device PSKs, the provider app identity, per-user tokens and the SSO
      // secrets share this file behind namespaced keys — the store itself is
      // just a map, so the namespacing is what keeps them apart.
      final store = FileSecretsStore(dataDir: tmp.path);
      await store.writePsk('device-1', 'psk');
      await store.writePsk(
        'provider_app_github_private_key',
        '-----BEGIN RSA PRIVATE KEY-----',
      );
      await store.writePsk('user_forge_github_alice', 'token');

      expect(secretsFile().existsSync(), isTrue);
      expect(jsonDecode(secretsFile().readAsStringSync()), {
        'device-1': 'psk',
        'provider_app_github_private_key': '-----BEGIN RSA PRIVATE KEY-----',
        'user_forge_github_alice': 'token',
      });
      expect(
        await FileSecretsStore(dataDir: tmp.path).readPsk('device-1'),
        'psk',
      );
    });

    test('a data dir with no secrets file starts empty', () async {
      final store = FileSecretsStore(dataDir: tmp.path);

      expect(await store.readPsk('device-1'), isNull);
      expect(secretsFile().existsSync(), isFalse);
    });

    test('a corrupt file is quarantined, never overwritten', () async {
      // Reading a corrupt file as empty meant the next write flushed that
      // emptiness over it: every PSK, the App private key and every user token
      // gone, silently. The bytes have to survive somewhere.
      secretsFile().writeAsStringSync('{"device-1": "psk"'); // truncated

      final store = FileSecretsStore(dataDir: tmp.path);
      expect(await store.readPsk('device-1'), isNull);
      await store.writePsk('device-2', 'psk-2');

      final quarantined = tmp
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('.corrupt-'))
          .toList();
      expect(quarantined, hasLength(1));
      expect(quarantined.single.readAsStringSync(), '{"device-1": "psk"');
      expect(jsonDecode(secretsFile().readAsStringSync()), {
        'device-2': 'psk-2',
      });
    });

    test('concurrent writes all survive', () async {
      // Both flushes build the SAME `<file>.tmp`; unserialized, the second
      // rename throws on a file the first already moved away.
      final store = FileSecretsStore(dataDir: tmp.path);

      await Future.wait([
        store.writePsk('device-1', 'a'),
        store.writePsk('provider_app_github_private_key', 'b'),
        store.writePsk('user_forge_github_alice', 'c'),
      ]);

      expect(jsonDecode(secretsFile().readAsStringSync()), {
        'device-1': 'a',
        'provider_app_github_private_key': 'b',
        'user_forge_github_alice': 'c',
      });
    });

    test('a write merges with what another process added', () async {
      // `calendar connect` and `cc_server pair` write this file from their own
      // processes. A whole-map write from a cache read at boot would drop what
      // they added.
      final store = FileSecretsStore(dataDir: tmp.path);
      await store.writePsk('device-1', 'psk');

      secretsFile().writeAsStringSync(
        jsonEncode({'device-1': 'psk', 'google_acct': 'token'}),
      );
      await store.writePsk('device-2', 'psk-2');

      expect(jsonDecode(secretsFile().readAsStringSync()), {
        'device-1': 'psk',
        'google_acct': 'token',
        'device-2': 'psk-2',
      });
      // …and a miss re-reads rather than trusting a cache from before that
      // write, which is what keeps a freshly connected calendar syncing.
      expect(await store.readFresh('google_acct'), 'token');
    });

    test('a device paired by another process needs no restart', () async {
      // `cc_server pair` writes this file from its OWN process. The cached map
      // held no key for the new device, so it authenticated as `psk=missing`
      // and the server had to be restarted before the device could connect.
      final store = FileSecretsStore(dataDir: tmp.path);
      await store.writePsk('device-1', 'psk');
      expect(await store.readPsk('device-1'), 'psk');

      secretsFile().writeAsStringSync(
        jsonEncode({'device-1': 'psk', 'phone': 'psk-phone'}),
      );

      expect(await store.readPsk('phone'), 'psk-phone');
    });

    test('re-pairing an existing device rotates the cached PSK', () async {
      // Rotation is the case a MISS cannot cover — the key is already cached,
      // so only the file's identity says the value changed underneath us.
      final store = FileSecretsStore(dataDir: tmp.path);
      await store.writePsk('device-1', 'old-psk');
      expect(await store.readPsk('device-1'), 'old-psk');

      // Same key and the same byte length, so this exercises the mtime lane
      // rather than the size one (a real PSK rotation is length-preserving).
      final file = secretsFile();
      file.writeAsStringSync(jsonEncode({'device-1': 'new-psk'}));
      file.setLastModifiedSync(
        file.lastModifiedSync().add(const Duration(seconds: 5)),
      );

      expect(await store.readPsk('device-1'), 'new-psk');
    });

    test('an unflushed local write survives a foreign re-read', () async {
      // The re-read must not roll back what this process has in flight.
      final store = FileSecretsStore(dataDir: tmp.path);
      await store.writePsk('device-1', 'psk');
      final pending = store.writePsk('device-2', 'psk-2');

      secretsFile().writeAsStringSync(jsonEncode({'device-1': 'psk'}));

      expect(await store.readPsk('device-2'), 'psk-2');
      await pending;
      expect(jsonDecode(secretsFile().readAsStringSync()), {
        'device-1': 'psk',
        'device-2': 'psk-2',
      });
    });

    test('a delete is not resurrected by the merge', () async {
      final store = FileSecretsStore(dataDir: tmp.path);
      await store.writePsk('device-1', 'psk');

      await store.deletePsk('device-1');

      expect(jsonDecode(secretsFile().readAsStringSync()), <String, String>{});
    });

    test('deletePsk drops one key and keeps the rest', () async {
      final store = FileSecretsStore(dataDir: tmp.path);
      await store.writePsk('device-1', 'psk');
      await store.writePsk('device-2', 'psk-2');

      await store.deletePsk('device-1');

      expect(await store.readPsk('device-1'), isNull);
      expect(jsonDecode(secretsFile().readAsStringSync()), {
        'device-2': 'psk-2',
      });
    });
  });
}
