import 'dart:io';

import 'package:cc_server_core/src/connect/connect_client.dart';
import 'package:cc_server_core/src/connect/connect_settings.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:test/test.dart';

/// The Connect choice, the install seed and the cached config: an unusable
/// `CC_CONNECT_URL` is refused once at boot, the seed is minted once, a
/// change made by `cc_server connect` from another process reaches a running
/// server, and no Klipy key is ever written down.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('cc_connect_set_'));
  tearDown(() => dir.deleteSync(recursive: true));

  ConnectSettings settings({Map<String, String> env = const {}}) =>
      ConnectSettings(
        secrets: FileSecretsStore(dataDir: dir.path),
        environment: env,
      );

  group('CC_CONNECT_URL', () {
    test('usable values pass the boot check', () {
      for (final value in [
        'off',
        'HOSTED',
        'https://connect.example',
        'http://127.0.0.1:8090',
      ]) {
        ConnectSettings.checkEnvironment({'CC_CONNECT_URL': value});
      }
      ConnectSettings.checkEnvironment(const {});
    });

    test('an unusable one is refused with its reason', () {
      for (final value in ['http://connect.example', 'not a url']) {
        expect(
          () => ConnectSettings.checkEnvironment({'CC_CONNECT_URL': value}),
          throwsA(
            isA<ConnectEnvironmentInvalid>().having(
              (e) => e.message,
              'message',
              contains('CC_CONNECT_URL'),
            ),
          ),
          reason: value,
        );
      }
    });

    test(
      'and reads as Connect off instead of throwing at call sites',
      () async {
        final s = settings(env: {'CC_CONNECT_URL': 'http://connect.example'});
        final choice = await s.choice();
        expect(choice.mode, ConnectMode.off);
        expect(choice.enabled, isFalse);
        expect(choice.lockedByEnvironment, isTrue);
        expect(await s.serverOwnAppsActive(), isTrue);
      },
    );
  });

  test('two first reads agree on one seed', () async {
    final s = settings();
    final seeds = await Future.wait([
      for (var i = 0; i < 8; i++) s.installSeed(),
    ]);
    for (final seed in seeds) {
      expect(seed, seeds.first);
    }
    expect(await settings().installSeed(), seeds.first);
  });

  test('a key rotated by another process reaches the running server on its '
      'next config read', () async {
    final server = settings(env: {'CC_CONNECT_URL': 'http://127.0.0.1:9'});
    var changes = 0;
    server.addListener(() => changes++);
    final client = ConnectClient(
      settings: server,
      timeout: const Duration(milliseconds: 200),
    );
    final before = (await client.configState(
      await client.serverTarget(),
    )).installId;
    expect(before, isNotEmpty);
    expect(
      (await client.configState(await client.serverTarget())).installId,
      before,
      reason: 'cached',
    );

    // Another process on the same data directory replaces the seed.
    final other = settings(env: {'CC_CONNECT_URL': 'http://127.0.0.1:9'});
    await other.replaceInstallSeed(await other.installSeed());

    final after = (await client.configState(
      await client.serverTarget(),
    )).installId;
    expect(after, isNot(before));
    expect(changes, 1);
    await client.configState(await client.serverTarget());
    expect(changes, 1, reason: 'one change, noticed once');
  });

  test('a rotation in this process runs the listeners', () async {
    final s = settings();
    var changes = 0;
    s.addListener(() => changes++);
    await s.replaceInstallSeed(await s.installSeed());
    expect(changes, 1);
    await s.noticeExternalChanges();
    expect(changes, 1);
  });

  test('a key-mode Klipy app key is never written down', () async {
    final secrets = FileSecretsStore(dataDir: dir.path);
    final s = ConnectSettings(secrets: secrets);
    const base = 'https://connect.example';
    const target = ConnectTarget(mode: ConnectMode.custom, baseUrl: base);

    await s.cacheConfig(target, {
      'epoch': 1,
      'klipy': {'mode': 'key', 'app_key': 'CONNECT-KEY'},
    });

    final cached = await s.cachedConfig(target);
    expect(cached!['klipy'], {'mode': 'key'});
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      expect(
        await file.readAsString(),
        isNot(contains('CONNECT-KEY')),
        reason: file.path,
      );
    }
  });
}
