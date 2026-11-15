import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

import 'support/harness.dart';

Future<String> _writeSigned(
  Directory dir,
  List<int> signingSeed, {
  int epoch = 3,
  String githubClientId = 'Iv23test',
  KlipyLaneConfig klipy = const KlipyLaneConfig(mode: KlipyLaneMode.proxy),
  String name = 'signed.json',
}) async {
  final config = ConnectConfig(
    epoch: epoch,
    issuedAt: DateTime.utc(2026, 11, 1),
    github: GitHubLaneConfig(
      appId: 4242,
      clientId: githubClientId,
      appSlug: 'cc-test',
      minSealGeneration: 2,
    ),
    google: const ClientIdLaneConfig(
      clientId: 'g-client.apps.googleusercontent.com',
    ),
    slack: const SlackLaneConfig(appId: 'A0TEST', clientId: '111.222'),
    klipy: klipy,
  );
  final payload = config.payload();
  final signed = {
    ...payload,
    'signature': await signConnectConfig(payload, signingSeed),
  };
  final file = File('${dir.path}/$name');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(signed));
  return file.path;
}

void main() {
  late ConnectInstallIdentity a;
  late ConnectInstallIdentity b;
  late Directory scratch;

  setUpAll(() async {
    a = await ConnectInstallIdentity.derive(
      masterSeed: seed(1),
      connectUrl: testPublicUrl,
    );
    b = await ConnectInstallIdentity.derive(
      masterSeed: seed(2),
      connectUrl: testPublicUrl,
    );
  });

  setUp(() async {
    scratch = await Directory.systemTemp.createTemp('cc_connect_config');
  });
  tearDown(() => scratch.delete(recursive: true));

  Map<String, String> base() => Harness.defaultEnv([a], scratch.path);

  void refuses(Map<String, String> env, Pattern message) {
    expect(
      () => ConnectServiceConfig.fromEnvironment(env),
      throwsA(
        isA<ConnectConfigException>().having(
          (e) => e.message,
          'message',
          contains(message),
        ),
      ),
    );
  }

  test('core\'s secret variable list is exactly what the configuration '
      'reads as a secret', () {
    final source = File('lib/src/service_config.dart').readAsStringSync();
    String name(Match m) => m.group(1)!;
    final dual = RegExp(
      r"\bdual\(\s*'(CONNECT_[A-Z0-9_]+)'",
    ).allMatches(source).map(name).toSet();
    final single = RegExp(
      r"\bsecret\(\s*'(CONNECT_[A-Z0-9_]+)'",
    ).allMatches(source).map(name).toSet();
    expect(dual, isNotEmpty);
    expect(single, isNotEmpty);
    // A dual secret also reads its previous generation.
    final read = {...single, ...dual, for (final n in dual) '${n}_PREVIOUS'};
    expect(connectSecretEnvKeys, read);
    // Every other variable named anywhere in the service is not a secret.
    final named = <String>{
      for (final file in [
        ...Directory('lib').listSync(recursive: true),
        ...Directory('bin').listSync(recursive: true),
      ].whereType<File>().where((f) => f.path.endsWith('.dart')))
        ...RegExp(
          r"'(CONNECT_[A-Z0-9_]+)'",
        ).allMatches(file.readAsStringSync()).map(name),
    };
    final others = named.difference(read);
    expect(others, contains('CONNECT_GITHUB_CLIENT_ID'));
    for (final key in others) {
      expect(isConnectSecretEnvKey(key), isFalse, reason: key);
    }
    for (final key in read) {
      expect(isConnectSecretEnvKey('${key}_FILE'), isFalse, reason: key);
    }
  });

  group('fromEnvironment refuses', () {
    test('a missing public URL', () {
      refuses({...base()}..remove('CONNECT_PUBLIC_URL'), 'CONNECT_PUBLIC_URL');
    });

    test('plain http off loopback, queries and fragments', () {
      refuses({
        ...base(),
        'CONNECT_PUBLIC_URL': 'http://connect.example',
      }, 'https');
      refuses({
        ...base(),
        'CONNECT_PUBLIC_URL': 'https://connect.example/?a=1',
      }, 'query');
    });

    test('an empty allow list (closed by default)', () {
      refuses(
        {...base()}..remove('CONNECT_ALLOWED_INSTALLS'),
        'CONNECT_ALLOWED_INSTALLS',
      );
      refuses({
        ...base(),
        'CONNECT_ALLOWED_INSTALLS': ' , ',
      }, 'names no install');
    });

    test('* without a signed config', () {
      refuses({
        ...base(),
        'CONNECT_ALLOWED_INSTALLS': '*',
      }, 'CONNECT_SIGNED_CONFIG_FILE');
    });

    test('a malformed install id, without echoing secrets', () {
      refuses({...base(), 'CONNECT_ALLOWED_INSTALLS': 'nope'}, '"nope"');
      refuses({
        ...base(),
        'CONNECT_DENY_INSTALLS': 'nope',
      }, 'CONNECT_DENY_INSTALLS');
    });

    test('a local seal backend without keys', () {
      refuses({...base()}..remove('CONNECT_SEAL_KEYS'), 'CONNECT_SEAL_KEYS');
    });

    test('a malformed KMS key, Redis URL or Firestore project', () {
      refuses({
        ...base(),
        'CONNECT_SEAL_BACKEND': 'gcp-kms',
      }, 'CONNECT_KMS_KEY');
      refuses({...base(), 'CONNECT_STATE': 'redis'}, 'CONNECT_REDIS_URL');
      refuses({
        ...base(),
        'CONNECT_STATE': 'redis',
        'CONNECT_REDIS_URL': 'http://x',
      }, 'CONNECT_REDIS_URL');
      refuses({
        ...base(),
        'CONNECT_BINDINGS': 'firestore',
      }, 'CONNECT_FIRESTORE_PROJECT');
      refuses({...base(), 'CONNECT_STATE': 'sqlite'}, 'CONNECT_STATE');
    });

    test('a KMS key that cannot encrypt and decrypt refuses to boot', () async {
      await expectLater(
        Harness.start(
          allowed: [a],
          env: {
            'CONNECT_SEAL_BACKEND': 'gcp-kms',
            'CONNECT_KMS_KEY':
                'projects/p/locations/global/keyRings/r/cryptoKeys/seals',
          },
        ),
        throwsA(
          isA<ConnectConfigException>().having(
            (e) => e.message,
            'message',
            contains('boot round trip'),
          ),
        ),
      );
    });

    test('NAME and NAME_FILE together', () {
      refuses({
        ...base(),
        'CONNECT_GITHUB_CLIENT_SECRET_FILE': '/run/secret',
      }, 'not both');
    });

    test('bad numbers and flags', () {
      refuses({...base(), 'CONNECT_TRUST_PROXY': 'yes'}, 'CONNECT_TRUST_PROXY');
      refuses({...base(), 'CONNECT_PORT': '70000'}, 'CONNECT_PORT');
      refuses({
        ...base(),
        'CONNECT_GITHUB_ACCEPTS_NEW': 'maybe',
      }, 'ACCEPTS_NEW');
      refuses({
        ...base(),
        'CONNECT_GITHUB_SECRET_GENERATION': '0',
      }, 'GENERATION');
      refuses({...base(), 'CONNECT_GITHUB_APP_ID': 'abc'}, 'APP_ID');
      refuses({
        ...base(),
        'CONNECT_GITHUB_APP_PRIVATE_KEY': 'not a key',
      }, 'CONNECT_GITHUB_APP_PRIVATE_KEY');
      refuses({...base(), 'CONNECT_KLIPY_MODE': 'open'}, 'CONNECT_KLIPY_MODE');
    });

    test('messages never carry secret values', () {
      try {
        ConnectServiceConfig.fromEnvironment({
          ...base(),
          'CONNECT_GITHUB_CLIENT_SECRET_FILE': '/run/secret',
        });
        fail('expected a refusal');
      } on ConnectConfigException catch (error) {
        expect(error.message, isNot(contains('gh-secret')));
      }
    });
  });

  group('fromEnvironment accepts', () {
    test('a complete env, loopback http and a trusted proxy', () {
      final config = ConnectServiceConfig.fromEnvironment({
        ...base(),
        'CONNECT_PUBLIC_URL': 'http://127.0.0.1:8790/',
        'CONNECT_TRUST_PROXY': '2',
        'CONNECT_ALLOWED_INSTALLS':
            '${a.installId.toUpperCase()}, ${b.installId}',
      });
      expect(config.publicBaseUrl, 'http://127.0.0.1:8790');
      expect(config.basePath, isEmpty);
      expect(config.trustProxyHops, 2);
      expect(config.access.permits(a.installId), isTrue);
      expect(config.access.permits(b.installId), isTrue);
      expect(config.github!.clientSecret.generation, 2);
      expect(config.github!.clientSecret.previousValue, 'gh-secret-1');
      expect(config.klipy!.mode, KlipyLaneMode.proxy);
      expect(config.rateLimits.perInstallPerMinute, 600);
    });

    test('a mount path', () {
      final config = ConnectServiceConfig.fromEnvironment({
        ...base(),
        'CONNECT_PUBLIC_URL': 'https://host.example/connect/',
      });
      expect(config.publicBaseUrl, 'https://host.example/connect');
      expect(config.basePath, '/connect');
    });
  });

  group('file-backed secrets', () {
    test('are re-read at most every 30s and keep the last good value', () {
      final files = {'/run/gh': 'first\n'};
      var now = DateTime.utc(2026, 11, 8, 12);
      final config = ConnectServiceConfig.fromEnvironment(
        {
          ...base(),
          'CONNECT_GITHUB_CLIENT_SECRET': '',
          'CONNECT_GITHUB_CLIENT_SECRET_FILE': '/run/gh',
        },
        readFile: (path) =>
            files[path] ?? (throw const FileSystemException('gone')),
        clock: () => now,
      );
      final secret = config.github!.clientSecret;
      expect(secret.current.isFileBacked, isTrue);
      expect(secret.currentValue, 'first');
      files['/run/gh'] = 'second';
      now = now.add(const Duration(seconds: 10));
      expect(secret.currentValue, 'first');
      now = now.add(const Duration(seconds: 25));
      expect(secret.currentValue, 'second');
      files.remove('/run/gh');
      now = now.add(const Duration(minutes: 1));
      expect(secret.currentValue, 'second');
    });

    test('a never-readable file makes the lane unavailable', () async {
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_GITHUB_CLIENT_SECRET': '',
          'CONNECT_GITHUB_CLIENT_SECRET_FILE': '${scratch.path}/missing',
        },
      );
      addTearDown(harness.close);
      final config = ConnectConfig.fromJson(
        (await harness.call(a, 'GET', '/v1/config')).json,
      );
      expect(config.github, isNull);
    });

    test('DualSecret.values lists current then previous', () {
      final pair = DualSecret(
        current: SecretSource.value('X', 'new'),
        previous: SecretSource.value('X_PREVIOUS', 'old'),
        generation: 5,
      );
      expect(pair.values, ['new', 'old']);
      expect(pair.previousGeneration, 4);
      final single = DualSecret(current: SecretSource.value('X', 'only'));
      expect(single.values, ['only']);
      expect(single.previousValue, isNull);
    });
  });

  group('signed config (hosted)', () {
    late List<int> signingSeed;
    late String publicKey;

    setUp(() async {
      signingSeed = seed(42);
      publicKey = await configPublicKeyForSeed(signingSeed);
    });

    test('is served byte for byte and lets * through', () async {
      final path = await _writeSigned(scratch, signingSeed);
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_ALLOWED_INSTALLS': '*',
          'CONNECT_DENY_INSTALLS': b.installId,
          'CONNECT_SIGNED_CONFIG_FILE': path,
          'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
        },
      );
      addTearDown(harness.close);
      final stranger = await ConnectInstallIdentity.derive(
        masterSeed: seed(9),
        connectUrl: testPublicUrl,
      );
      final response = await harness.call(stranger, 'GET', '/v1/config');
      expect(response.status, 200);
      expect(response.body, await File(path).readAsString());
      expect(
        await verifyConnectConfigSignature(
          response.json,
          trustedKeys: [publicKey],
        ),
        isTrue,
      );
      final config = ConnectConfig.fromJson(response.json);
      expect(config.epoch, 3);
      expect(config.linear, isNull, reason: 'the signed file decides lanes');
      final denied = await harness.call(b, 'GET', '/v1/config');
      expect(denied.json, {'error': 'install_blocked'});
      // * under a key the operator supplied, not the hosted root: said at
      // error level when the service starts.
      final open = harness.logs
          .map((l) => jsonDecode(l) as Map<String, Object?>)
          .where((l) => l['event'] == 'config.open_to_any_install');
      expect(open.single['level'], 'error');
    });

    test('a signed config with an allow list says nothing about *', () async {
      final path = await _writeSigned(scratch, signingSeed);
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_SIGNED_CONFIG_FILE': path,
          'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
        },
      );
      addTearDown(harness.close);
      expect(
        harness.logs.where((l) => l.contains('config.open_to_any_install')),
        isEmpty,
      );
    });

    test('inline, it is served byte for byte and lets * through', () async {
      final path = await _writeSigned(scratch, signingSeed);
      final inline = await File(path).readAsString();
      final harness = await Harness.start(
        allowed: [a],
        env: {
          'CONNECT_ALLOWED_INSTALLS': '*',
          'CONNECT_SIGNED_CONFIG': inline,
          'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
        },
      );
      addTearDown(harness.close);
      final stranger = await ConnectInstallIdentity.derive(
        masterSeed: seed(9),
        connectUrl: testPublicUrl,
      );
      final response = await harness.call(stranger, 'GET', '/v1/config');
      expect(response.status, 200);
      expect(response.body, inline);
      expect(ConnectConfig.fromJson(response.json).epoch, 3);
    });

    test('inline and file together refuse to start', () async {
      final path = await _writeSigned(scratch, signingSeed);
      final inline = await File(path).readAsString();
      expect(
        () => Harness.start(
          allowed: [a],
          env: {
            'CONNECT_SIGNED_CONFIG': inline,
            'CONNECT_SIGNED_CONFIG_FILE': path,
            'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
          },
        ),
        throwsA(
          isA<ConnectConfigException>().having(
            (e) => '$e',
            'message',
            contains('not both'),
          ),
        ),
      );
    });

    test('an inline config signed by an untrusted key refuses', () async {
      final path = await _writeSigned(scratch, seed(43));
      final inline = await File(path).readAsString();
      expect(
        () => Harness.start(
          allowed: [a],
          env: {
            'CONNECT_SIGNED_CONFIG': inline,
            'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
          },
        ),
        throwsA(isA<ConnectConfigException>()),
      );
    });

    test('a lane that differs from the credentials refuses to start', () async {
      final path = await _writeSigned(
        scratch,
        signingSeed,
        githubClientId: 'Iv23other',
      );
      expect(
        () => Harness.start(
          allowed: [a],
          env: {
            'CONNECT_SIGNED_CONFIG_FILE': path,
            'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
          },
        ),
        throwsA(isA<ConnectConfigException>()),
      );
    });

    test(
      'a signed file with no key to check it against refuses to start',
      skip: hostedConfigRootKeys.isNotEmpty
          ? 'a hosted root key is compiled in'
          : false,
      () {
        expect(
          () => Harness.start(
            allowed: [a],
            env: {'CONNECT_SIGNED_CONFIG_FILE': '${scratch.path}/any.json'},
          ),
          throwsA(
            isA<ConnectConfigException>().having(
              (e) => '$e',
              'message',
              contains('CONNECT_CONFIG_PUBLIC_KEYS'),
            ),
          ),
        );
      },
    );

    test('a key-mode Klipy app key must be one Connect holds', () async {
      final path = await _writeSigned(
        scratch,
        signingSeed,
        klipy: const KlipyLaneConfig(mode: KlipyLaneMode.key, appKey: 'other'),
      );
      expect(
        () => Harness.start(
          allowed: [a],
          env: {
            'CONNECT_SIGNED_CONFIG_FILE': path,
            'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
            'CONNECT_KLIPY_MODE': 'key',
          },
        ),
        throwsA(isA<ConnectConfigException>()),
      );
    });

    test('a signature from an untrusted key refuses to start', () async {
      final path = await _writeSigned(scratch, seed(43));
      expect(
        () => Harness.start(
          allowed: [a],
          env: {
            'CONNECT_SIGNED_CONFIG_FILE': path,
            'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
          },
        ),
        throwsA(isA<ConnectConfigException>()),
      );
    });

    test('a refused start lets go of the data directory', () async {
      final dir = await Directory.systemTemp.createTemp('cc_connect_refused');
      addTearDown(() => dir.delete(recursive: true));
      final path = await _writeSigned(scratch, seed(43));
      final config = ConnectServiceConfig.fromEnvironment({
        ...Harness.defaultEnv([a], dir.path),
        'CONNECT_SIGNED_CONFIG_FILE': path,
        'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
      });
      await expectLater(
        ConnectService.start(config, upstream: FakeUpstream()),
        throwsA(isA<ConnectConfigException>()),
      );
      // The binding store's lock is released, so the directory opens again.
      final store = await FileBindingStore.open(dir.path);
      await store.close();
    });

    test('a lane whose secret file is missing refuses signed boot', () async {
      final path = await _writeSigned(scratch, signingSeed);
      await expectLater(
        Harness.start(
          allowed: [a],
          env: {
            'CONNECT_SIGNED_CONFIG_FILE': path,
            'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
            'CONNECT_GITHUB_CLIENT_SECRET': '',
            'CONNECT_GITHUB_CLIENT_SECRET_FILE': '${scratch.path}/missing',
          },
        ),
        throwsA(isA<ConnectConfigException>()),
      );
    });

    test('an unsigned or unreadable file refuses to start', () async {
      final unsigned = File('${scratch.path}/unsigned.json')
        ..writeAsStringSync(
          jsonEncode(
            ConnectConfig(epoch: 1, issuedAt: DateTime.utc(2026)).payload(),
          ),
        );
      for (final path in [unsigned.path, '${scratch.path}/missing.json']) {
        await expectLater(
          Harness.start(
            allowed: [a],
            env: {
              'CONNECT_SIGNED_CONFIG_FILE': path,
              'CONNECT_CONFIG_PUBLIC_KEYS': publicKey,
            },
          ),
          throwsA(isA<ConnectConfigException>()),
        );
      }
    });
  });

  group('GitHub App key pasted into an environment variable', () {
    final canonical = normalizePem(testGitHubAppKey);
    final oneLineEscaped = testGitHubAppKey.trim().replaceAll('\n', r'\n');

    for (final (name, pasted) in [
      ('as is', testGitHubAppKey),
      ('with literal \\n escapes', oneLineEscaped),
      ('quoted with escapes', '"$oneLineEscaped"'),
      ('line breaks as spaces', testGitHubAppKey.trim().replaceAll('\n', ' ')),
      ('CRLF line breaks', testGitHubAppKey.replaceAll('\n', '\r\n')),
      ('base64 of the PEM', base64.encode(utf8.encode(testGitHubAppKey))),
    ]) {
      test('$name reads as the same key', () {
        expect(normalizePem(pasted), canonical);
        expect(isReadableGitHubAppKey(pasted), isTrue);
        expect(
          () => ConnectServiceConfig.fromEnvironment({
            ...base(),
            'CONNECT_GITHUB_APP_PRIVATE_KEY': pasted,
          }),
          returnsNormally,
        );
      });
    }

    test('anything that is not a key is still refused', () {
      for (final junk in ['not a key', 'bm90IGEga2V5', '"-----BEGIN X-----"']) {
        expect(isReadableGitHubAppKey(junk), isFalse, reason: junk);
      }
    });
  });
}
