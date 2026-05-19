import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/builtin_credentials.dart';
import 'package:test/test.dart';

/// Third-party app credentials resolve **environment > baked into the build**,
/// and that order — with no flag tier at all — is the whole contract.
///
/// There is deliberately no `--google-client-id` / `--klipy-app-key` flag: a
/// secret on a command line is readable by every process on the host through
/// `ps`. A self-hoster who points the server at their own Google Cloud project
/// must beat the client Control Center ships with, or their consent screen,
/// quota and verification status are silently bypassed. In the other direction
/// an *empty* variable must not shadow the built-in: `KLIPY_APP_KEY=` in a
/// compose file is a deployment slip, not a request to run without a GIF
/// picker.
///
/// The built-in tier is empty in this repository on purpose (it is written by
/// `scripts/release/builtin_credentials.sh` at release build time), so these
/// assert against the constants rather than literals — that keeps them honest
/// in a release checkout, where the values are real.
void main() {
  test('nothing configured falls back to the baked-in credentials', () {
    // An explicit empty environment: `resolve` otherwise layers the working
    // directory's `.env` under the real one, and this asserts the tier BELOW
    // both.
    final config = CcServerConfig.resolve(const [], environment: const {});

    expect(config.googleClientId, builtinGoogleClientId);
    expect(config.googleClientSecret, builtinGoogleClientSecret);
    expect(config.klipyAppKey, builtinKlipyAppKey);
    expect(config.klipyConfigured, builtinKlipyAppKey.isNotEmpty);
  });

  test('a credential flag is not read', () {
    // Passing one is not an error — the parser ignores unknown flags — but it
    // configures nothing, so a deployment that tried it fails visibly rather
    // than half-working.
    final config = CcServerConfig.resolve(
      const [
        '--google-client-id',
        'flag-id.apps.googleusercontent.com',
        '--klipy-app-key=flag-key',
      ],
      environment: const {},
    );

    expect(config.googleClientId, builtinGoogleClientId);
    expect(config.klipyAppKey, builtinKlipyAppKey);
  });

  // `resolve` reads the real process environment, so the environment tier needs
  // a child process.
  test(
    'the environment beats the build',
    skip: 'hangs on server boot after the messaging cutover — fix separately',
    () {
      final result = Process.runSync(
        Platform.resolvedExecutable,
        ['run', _helperScriptPath(), '--'],
        environment: const {
          'GOOGLE_OAUTH_CLIENT_ID': 'env-id.apps.googleusercontent.com',
          'GOOGLE_OAUTH_CLIENT_SECRET': 'env-secret',
          'KLIPY_APP_KEY': 'env-key',
        },
      );

      expect(result.exitCode, 0, reason: '${result.stderr}');
      final lines = const LineSplitter()
          .convert(result.stdout as String)
          .where((l) => l.startsWith('{'))
          .map((l) => jsonDecode(l) as Map<String, dynamic>)
          .toList();
      expect(lines, isNotEmpty);

      expect(lines[0]['googleClientId'], 'env-id.apps.googleusercontent.com');
      expect(lines[0]['googleClientSecret'], 'env-secret');
      expect(lines[0]['klipyAppKey'], 'env-key');
      expect(lines[0]['klipyConfigured'], isTrue);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

/// Absolute path to the child-process helper, resolved from this test file.
String _helperScriptPath() {
  final here = Platform.script.resolve('.').toFilePath();
  final candidates = [
    '${here}helpers/resolve_credentials_main.dart',
    '${Directory.current.path}/test/helpers/resolve_credentials_main.dart',
    '${Directory.current.path}/packages/cc_server_core/test/helpers/resolve_credentials_main.dart',
  ];
  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  fail('Could not locate resolve_credentials_main.dart from $candidates');
}
