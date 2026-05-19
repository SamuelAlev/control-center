import 'dart:convert';
import 'dart:io';

import 'package:cc_server_core/cc_server_core.dart';
import 'package:cc_server_core/src/builtin_credentials.dart';
import 'package:test/test.dart';

/// Third-party app credentials resolve **flag > environment > baked into the
/// build** and that order is the whole contract.
///
/// A self-hoster who points the server at their own Google Cloud project must
/// always beat the client Control Center ships with — otherwise their consent
/// screen, their quota and their verification status are silently bypassed. In
/// the other direction, an *empty* flag or variable must not shadow the built-in
/// either: `CC_KLIPY_APP_KEY=` in a compose file is a deployment slip, not a
/// request to run without a GIF picker.
///
/// The built-in tier is empty in this repository on purpose (it is written by
/// `scripts/release/builtin_credentials.sh` at release build time), so these
/// assert against the constants rather than literals — that keeps them honest in
/// a release checkout, where the values are real.
void main() {
  // A developer with these exported would otherwise see the "last resort" cases
  // resolve to their own values.
  final env = Platform.environment;
  final envIsClean =
      (env['CC_GOOGLE_OAUTH_CLIENT_ID'] ?? '').isEmpty &&
      (env['CC_GOOGLE_OAUTH_CLIENT_SECRET'] ?? '').isEmpty &&
      (env['CC_KLIPY_APP_KEY'] ?? '').isEmpty;

  group('flags win', () {
    test('a Google client passed on the command line is used verbatim', () {
      final config = CcServerConfig.resolve(const [
        '--google-client-id',
        'flag-id.apps.googleusercontent.com',
        '--google-client-secret',
        'flag-secret',
      ]);

      expect(config.googleClientId, 'flag-id.apps.googleusercontent.com');
      expect(config.googleClientSecret, 'flag-secret');
    });

    test('a Klipy key passed on the command line configures the picker', () {
      final config = CcServerConfig.resolve(const [
        '--klipy-app-key=flag-key',
      ]);

      expect(config.klipyAppKey, 'flag-key');
      expect(config.klipyConfigured, isTrue);
    });

    test('surrounding whitespace is not part of the credential', () {
      // A key copied out of a dashboard or a compose file routinely arrives with
      // a trailing newline, which would reach Google/Klipy as a wrong value.
      final config = CcServerConfig.resolve(const [
        '--klipy-app-key= flag-key \n',
      ]);

      expect(config.klipyAppKey, 'flag-key');
    });
  });

  group('the built-in tier is the last resort', () {
    test('nothing configured falls back to the baked-in credentials', () {
      final config = CcServerConfig.resolve(const []);

      expect(config.googleClientId, builtinGoogleClientId);
      expect(config.googleClientSecret, builtinGoogleClientSecret);
      expect(config.klipyAppKey, builtinKlipyAppKey);
      expect(config.klipyConfigured, builtinKlipyAppKey.isNotEmpty);
    }, skip: envIsClean ? null : 'CC_* credentials set in this environment');

    test('an empty override does not shadow it', () {
      final config = CcServerConfig.resolve(const [
        '--google-client-id=',
        '--google-client-secret=',
        '--klipy-app-key=',
      ]);

      // An unset variable and `CC_X=` have to behave identically: the empty form
      // is what a compose file or a CI matrix produces for "I did not set this".
      expect(config.googleClientId, builtinGoogleClientId);
      expect(config.googleClientSecret, builtinGoogleClientSecret);
      expect(config.klipyAppKey, builtinKlipyAppKey);
    }, skip: envIsClean ? null : 'CC_* credentials set in this environment');
  });

  // `resolve` reads the real process environment, so the environment tier needs a
  // child process. One spawn, two argument groups.
  test('the environment beats the build and a flag beats the environment', () {
    final result = Process.runSync(
      Platform.resolvedExecutable,
      [
        'run',
        // Absolute, resolved from THIS file rather than the CWD: `dart test
        // packages/cc_server_core` and `dart test` from the package root have
        // different working directories, and the relative form failed on the
        // first with "could not find file" — which reads as a broken helper,
        // not as a broken path.
        _helperScriptPath(),
        // Group 1: environment only.
        '--',
        // Group 2: the same environment, overridden on the command line.
        '--google-client-id',
        'flag-id',
        '--klipy-app-key',
        'flag-key',
      ],
      environment: const {
        'CC_GOOGLE_OAUTH_CLIENT_ID': 'env-id.apps.googleusercontent.com',
        'CC_GOOGLE_OAUTH_CLIENT_SECRET': 'env-secret',
        'CC_KLIPY_APP_KEY': 'env-key',
      },
    );

    expect(result.exitCode, 0, reason: '${result.stderr}');
    final lines = const LineSplitter()
        .convert(result.stdout as String)
        .where((l) => l.startsWith('{'))
        .map((l) => jsonDecode(l) as Map<String, dynamic>)
        .toList();
    expect(lines, hasLength(2));

    // A self-hoster's own Google Cloud client and Klipy key are what the server
    // runs on, whatever this build was released with.
    expect(lines[0]['googleClientId'], 'env-id.apps.googleusercontent.com');
    expect(lines[0]['googleClientSecret'], 'env-secret');
    expect(lines[0]['klipyAppKey'], 'env-key');
    expect(lines[0]['klipyConfigured'], isTrue);

    expect(lines[1]['googleClientId'], 'flag-id');
    expect(lines[1]['klipyAppKey'], 'flag-key');
    // Only what the flag named is overridden; the rest still comes from the
    // environment.
    expect(lines[1]['googleClientSecret'], 'env-secret');
  }, timeout: const Timeout(Duration(minutes: 2)));
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
