@Timeout(Duration(minutes: 2))
library;

import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/cc_connect.dart';
import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:test/test.dart';

/// Runs a `bin/` script with the test's own Dart VM (no `dart run`, so no
/// pub resolution), from the package directory.
Future<ProcessResult> _dart(
  String script,
  List<String> args, {
  Map<String, String>? environment,
}) => Process.run(
  Platform.resolvedExecutable,
  [script, ...args],
  environment: environment,
  includeParentEnvironment: environment == null,
);

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('cc_tool'));
  tearDown(() => dir.delete(recursive: true));

  test('config_tool keygen → sign → verify', () async {
    final seedPath = '${dir.path}/seed';
    final keygen = await _dart('bin/config_tool.dart', [
      'keygen',
      '--out',
      seedPath,
    ]);
    expect(keygen.exitCode, 0, reason: '${keygen.stderr}');
    final publicKey = RegExp(
      r'public key: (\S+)',
    ).firstMatch('${keygen.stdout}')!.group(1)!;
    expect(
      publicKey,
      await configPublicKeyForSeed(File(seedPath).readAsBytesSync()),
    );
    if (!Platform.isWindows) {
      expect(File(seedPath).statSync().mode & 0x3f, 0);
    }
    final again = await _dart('bin/config_tool.dart', [
      'keygen',
      '--out',
      seedPath,
    ]);
    expect(again.exitCode, 64, reason: 'never overwrites a signing seed');

    final payload = File('${dir.path}/payload.json')
      ..writeAsStringSync(
        jsonEncode({
          'epoch': 4,
          'github': const GitHubLaneConfig(
            appId: 4242,
            clientId: 'Iv23test',
            appSlug: 'cc-test',
          ).toJson(),
          'klipy': const KlipyLaneConfig(mode: KlipyLaneMode.proxy).toJson(),
        }),
      );
    final signedPath = '${dir.path}/signed.json';
    final sign = await _dart('bin/config_tool.dart', [
      'sign',
      '--seed',
      seedPath,
      '--payload',
      payload.path,
      '--out',
      signedPath,
    ]);
    expect(sign.exitCode, 0, reason: '${sign.stderr}');
    final signed =
        jsonDecode(File(signedPath).readAsStringSync()) as Map<String, Object?>;
    expect(signed['protocol'], connectProtocolVersion);
    expect(signed['epoch'], 4);
    expect(signed['signature'], isA<String>());
    expect(
      SignedConfigFile.parse(File(signedPath).readAsBytesSync()).config.epoch,
      4,
    );

    final ok = await _dart('bin/config_tool.dart', [
      'verify',
      '--key',
      publicKey,
      signedPath,
    ]);
    expect(ok.exitCode, 0);
    final other = await configPublicKeyForSeed(List.filled(32, 7));
    final bad = await _dart('bin/config_tool.dart', [
      'verify',
      '--key',
      other,
      signedPath,
    ]);
    expect(bad.exitCode, 1);

    final malformed = File('${dir.path}/bad.json')
      ..writeAsStringSync(
        jsonEncode({
          'epoch': 1,
          'github': {'app_id': 'x'},
        }),
      );
    final refused = await _dart('bin/config_tool.dart', [
      'sign',
      '--seed',
      seedPath,
      '--payload',
      malformed.path,
    ]);
    expect(refused.exitCode, 64);
  });

  test('config_tool seal-key prints a usable keyring entry', () async {
    final result = await _dart('bin/config_tool.dart', ['seal-key']);
    expect(result.exitCode, 0);
    expect(
      parseSealKeyring('${result.stdout}'.trim()).single.key,
      hasLength(32),
    );
  });

  test(
    'the server refuses a half-configured environment with EX_CONFIG',
    () async {
      final result = await _dart(
        'bin/server.dart',
        const [],
        environment: {'CONNECT_PUBLIC_URL': 'https://connect.example'},
      );
      expect(result.exitCode, 78);
      expect('${result.stderr}', contains('CONNECT_ALLOWED_INSTALLS'));
    },
  );

  test('--healthcheck fails when nothing listens', () async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    final result = await _dart(
      'bin/server.dart',
      const ['--healthcheck'],
      environment: {'CONNECT_PORT': '$port'},
    );
    expect(result.exitCode, 1);
  });
}
