import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract tests for `scripts/release/sentry_upload.sh`, the uploader that
/// replaced the `sentry_dart_plugin` dev dependency (whose transient chain
/// carried the discontinued `globbing` package, and which downloaded its own
/// unpinned sentry-cli at run time).
///
/// Every case runs the real script against a fixture build tree with a stub
/// `sentry-cli` (and, for the download path, a stub `curl`) on `PATH`. Nothing
/// touches the network or a Sentry account; the thing under test is the exact
/// command line the script would have run for real — release name, org/project,
/// uploaded roots — plus which files and credentials it prepares.
void main() {
  final root = Directory.current.path;
  group('platform fixture', () {
    late _Fixture fixture;
    setUp(() => fixture = _Fixture(root));
    tearDown(() => fixture.dispose());

    test('linux: the release is the identity the app reports', () {
      final result = fixture.run(['--platform', 'linux']);

      expect(result.exitCode, 0, reason: result.stderr);
      // From the bundle's version.json — what package_info_plus reads — not the
      // pubspec: an upload under any other name symbolicates nothing.
      expect(
        _call(result.calls, 'debug-files', 'upload'),
        contains('${fixture.buildDir}/linux/x64/release/bundle'),
      );
      expect(
        _call(result.calls, 'releases', 'new'),
        contains('control_center@9.9.9+7'),
      );
      expect(
        _call(result.calls, 'releases', 'finalize'),
        contains('control_center@9.9.9+7'),
      );
    });

    test('linux: a build input the artifact does not agree with fails', () {
      final result = fixture.run([
        '--platform',
        'linux',
        '--build-name',
        '9.9.9',
        '--build-number',
        '8',
      ]);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('--build-number'));
      expect(result.calls, isEmpty, reason: 'nothing may be uploaded');
    });

    test('windows: arm64 uses the arm64 bundle and the Runner.rc owner', () {
      final result = fixture.run([
        '--platform',
        'windows',
        '--arch',
        'arm64',
        '--build-name',
        '9.9.9',
        '--build-number',
        '7',
      ]);

      expect(result.exitCode, 0, reason: result.stderr);
      expect(
        _call(result.calls, 'debug-files', 'upload'),
        contains('${fixture.buildDir}/windows/arm64/runner/Release'),
      );
      // package_info_plus reports Runner.rc's InternalName as packageName on
      // Windows, so the release owner is that literal, cross-checked against the
      // pubspec by the script.
      expect(
        _call(result.calls, 'releases', 'new'),
        contains('${fixture.windowsInternalName}@9.9.9+7'),
      );
    });

    test('web: debug ids are injected per JS file, then the maps upload', () {
      final result = fixture.run(['--platform', 'web']);

      expect(result.exitCode, 0, reason: result.stderr);
      final inject = _call(result.calls, 'sourcemaps', 'inject');
      expect(
        inject,
        contains('${fixture.buildDir}/web/main.dart.js'),
        reason: 'inject must list the JavaScript files, not the directory',
      );
      expect(inject, isNot(contains('${fixture.buildDir}/web')));

      final upload = _call(result.calls, 'sourcemaps', 'upload');
      expect(
        upload,
        containsAllInOrder(['--release', 'control_center@9.9.9+7']),
      );
      expect(upload, containsAllInOrder(['--dist', '7']));
      expect(upload, containsAllInOrder(['--ext', 'js', '--ext', 'map']));
      expect(
        result.calls.indexOf(inject),
        lessThan(result.calls.indexOf(upload)),
        reason: 'upload must see the already-injected JavaScript',
      );
    });

    test(
      'macOS: the release is the bundle id plus the Info.plist versions',
      () {
        if (!Platform.isMacOS) {
          markTestSkipped('deriving the release needs PlistBuddy (macOS only)');
          return;
        }
        final result = fixture.run([
          '--platform',
          'macos',
          '--build-number',
          '7',
        ]);

        expect(result.exitCode, 0, reason: result.stderr);
        expect(
          _call(result.calls, 'releases', 'new'),
          contains('com.alev.control-center@1.5.0+7'),
        );
        expect(
          _call(result.calls, 'debug-files', 'upload'),
          contains('${fixture.buildDir}/macos/Build/Products/Release'),
        );
      },
    );

    test('macOS: a build number the app does not report fails', () {
      if (!Platform.isMacOS) {
        markTestSkipped('deriving the release needs PlistBuddy (macOS only)');
        return;
      }
      final result = fixture.run([
        '--platform',
        'macos',
        '--build-number',
        '8',
      ]);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('--build-number'));
      expect(result.calls, isEmpty);
    });

    test('SENTRY_RELEASE / SENTRY_DIST override the derivation', () {
      final result = fixture.run(
        ['--platform', 'linux'],
        env: {'SENTRY_RELEASE': 'custom@1.0.0', 'SENTRY_DIST': '99'},
      );

      expect(result.exitCode, 0, reason: result.stderr);
      final created = _call(result.calls, 'releases', 'new');
      expect(created, contains('custom@1.0.0'));
      expect(created, isNot(contains('control_center@9.9.9+7')));
    });

    test('a nonexistent --split-debug-info directory fails', () {
      final result = fixture.run([
        '--platform',
        'linux',
        '--split-debug-info',
        '${fixture.dir.path}/nope',
      ]);

      expect(result.exitCode, isNot(0));
      expect(result.calls, isEmpty);
    });

    test('no secret reaches argv and sources are never uploaded', () {
      final result = fixture.run(['--platform', 'linux']);

      expect(result.exitCode, 0, reason: result.stderr);
      expect(result.calls, isNotEmpty);
      for (final call in result.calls) {
        expect(call, isNot(contains('--auth-token')));
        expect(call, isNot(contains(_Fixture.token)));
        // The removed plugin config never enabled source uploads, and source
        // bundles are a separate disclosure decision.
        expect(call, isNot(contains('--include-sources')));
      }
    });
  });

  group('credentials', () {
    late _Fixture fixture;
    setUp(() => fixture = _Fixture(root));
    tearDown(() => fixture.dispose());

    test('a missing token fails instead of uploading nothing', () {
      final result = fixture.run(['--platform', 'linux'], withToken: false);

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('SENTRY_AUTH_TOKEN'));
      expect(result.calls, isEmpty, reason: 'nothing may be uploaded');
    });

    test('--allow-missing-credentials skips locally', () {
      final result = fixture.run([
        '--platform',
        'linux',
        '--allow-missing-credentials',
      ], withToken: false);

      expect(result.exitCode, 0, reason: result.stderr);
      expect(result.stderr.toLowerCase(), contains('skipping'));
      expect(result.calls, isEmpty);
    });

    test(
      'an explicit credential-free CI upload skips without sending data',
      () {
        final result = fixture.run(
          ['--platform', 'linux', '--allow-missing-credentials'],
          withToken: false,
          env: {'GITHUB_ACTIONS': 'true'},
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(result.calls, isEmpty);
      },
    );
  });

  group('pinned sentry-cli', () {
    late _Fixture fixture;
    setUp(() => fixture = _Fixture(root));
    tearDown(() => fixture.dispose());

    Map<String, String> pinnedEnv() => {
      'SENTRY_CLI_VERSION': _Fixture.cliVersion,
      'SENTRY_CLI_SHA256_LINUX_X86_64': fixture.stubCliSha256,
    };

    test('it downloads the pinned GitHub release asset and runs it', () {
      final result = fixture.run(
        ['--platform', 'linux'],
        withCurlStub: true,
        env: pinnedEnv(),
      );

      expect(result.exitCode, 0, reason: result.stderr);
      expect(
        fixture.curlLog.readAsLinesSync(),
        contains(
          contains(
            'https://github.com/getsentry/sentry-cli/releases/download/'
            '${_Fixture.cliVersion}/sentry-cli-Linux-x86_64',
          ),
        ),
      );
      expect(
        File(
          '${fixture.buildDir}/sentry-cli/${_Fixture.cliVersion}/'
          'sentry-cli-Linux-x86_64',
        ).existsSync(),
        isTrue,
        reason: 'the verified binary is cached under the build dir',
      );
      expect(result.calls, isNotEmpty);
    });

    test('a cached binary is reused without another download', () {
      expect(
        fixture
            .run(['--platform', 'linux'], withCurlStub: true, env: pinnedEnv())
            .exitCode,
        0,
      );
      final downloads = fixture.curlLog.readAsLinesSync().length;
      expect(downloads, greaterThan(0));

      expect(
        fixture
            .run(['--platform', 'linux'], withCurlStub: true, env: pinnedEnv())
            .exitCode,
        0,
      );
      expect(fixture.curlLog.readAsLinesSync(), hasLength(downloads));
    });

    test('a checksum mismatch fails before anything is uploaded', () {
      final result = fixture.run(
        ['--platform', 'linux'],
        withCurlStub: true,
        env: {
          'SENTRY_CLI_VERSION': _Fixture.cliVersion,
          'SENTRY_CLI_SHA256_LINUX_X86_64': 'deadbeef' * 8,
        },
      );

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains('checksum mismatch'));
      expect(result.calls, isEmpty);
    });

    test('a binary reporting another version fails', () {
      final result = fixture.run(
        ['--platform', 'linux'],
        withCurlStub: true,
        env: {
          ...pinnedEnv(),
          // The stub reports this instead of the pinned release.
          'CC_STUB_VERSION': '0.0.1',
        },
      );

      expect(result.exitCode, isNot(0));
      expect(result.stderr, contains(_Fixture.cliVersion));
      expect(result.calls, isEmpty);
    });

    test('an explicit SENTRY_CLI bypasses the pin and says so', () {
      // The tests' own escape hatch; a local bisect uses it too. It must be
      // loud, because nothing verifies that binary.
      final result = fixture.run(['--platform', 'linux']);
      expect(result.exitCode, 0, reason: result.stderr);
      expect(result.stderr, contains('SENTRY_CLI'));
      expect(fixture.curlLog.existsSync(), isFalse);
    });
  });
}

/// The argv of the first sentry-cli invocation starting with [first] (and
/// [second] when given).
List<String> _call(List<List<String>> calls, String first, [String? second]) {
  for (final call in calls) {
    if (call.isEmpty || call.first != first) {
      continue;
    }
    if (second != null && (call.length < 2 || call[1] != second)) {
      continue;
    }
    return call;
  }
  fail(
    'no sentry-cli invocation "$first ${second ?? ''}" in:\n  '
    '${calls.map((c) => c.join(' ')).join('\n  ')}',
  );
}

/// A fixture build tree plus the stub `sentry-cli` / `curl` the uploader can be
/// driven with.
class _Fixture {
  _Fixture(this.repoRoot) {
    dir = Directory.systemTemp.createTempSync('cc_sentry_upload');
    buildDir = '${dir.path}/build';
    Directory(buildDir).createSync(recursive: true);
    binDir = Directory('${dir.path}/bin')..createSync(recursive: true);
    argvLog = File('${dir.path}/argv.log');
    curlLog = File('${dir.path}/curl.log');

    _writeVersionJson('$buildDir/linux/x64/release/bundle/data/flutter_assets');
    _writeVersionJson('$buildDir/web');
    _writeWebSources();
    Directory(
      '$buildDir/windows/x64/runner/Release',
    ).createSync(recursive: true);
    Directory(
      '$buildDir/windows/arm64/runner/Release',
    ).createSync(recursive: true);
    _writeMacosApp();

    cliStub = File('${binDir.path}/sentry-cli')
      ..writeAsStringSync(_cliStubSource);
    _makeExecutable(cliStub);
    curlStub = File('${binDir.path}/curl')..writeAsStringSync(_curlStubSource);
    _makeExecutable(curlStub);
  }

  static const token = 'test-token-not-a-real-secret';
  static const cliVersion = '3.8.0';

  final String repoRoot;
  late final Directory dir;
  late final String buildDir;
  late final Directory binDir;
  late final File argvLog;
  late final File curlLog;
  late final File cliStub;
  late final File curlStub;

  /// The release owner the Windows build reports — read from the same file the
  /// script reads, so the two fail together if they ever drift.
  String get windowsInternalName {
    final rc = File('$repoRoot/windows/runner/Runner.rc').readAsStringSync();
    return RegExp(r'VALUE "InternalName", "([^"]*)"').firstMatch(rc)!.group(1)!;
  }

  String get stubCliSha256 =>
      sha256.convert(cliStub.readAsBytesSync()).toString();

  void dispose() => dir.deleteSync(recursive: true);

  /// Runs the uploader with a hermetic environment: every SENTRY_* and CI
  /// variable the host may carry is unset first, so a developer's own token can
  /// neither change the outcome nor be uploaded by a test.
  _Run run(
    List<String> args, {
    Map<String, String> env = const {},
    bool withToken = true,
    bool withCurlStub = false,
  }) {
    final unset = <String>[
      'SENTRY_AUTH_TOKEN',
      'SENTRY_ORG',
      'SENTRY_PROJECT',
      'SENTRY_URL',
      'SENTRY_RELEASE',
      'SENTRY_DIST',
      'SENTRY_CLI',
      'SENTRY_CLI_VERSION',
      'SENTRY_CLI_SHA256_DARWIN_UNIVERSAL',
      'SENTRY_CLI_SHA256_LINUX_X86_64',
      'SENTRY_CLI_SHA256_LINUX_AARCH64',
      'SENTRY_CLI_SHA256_WINDOWS_X86_64',
      'SENTRY_CLI_SHA256_WINDOWS_AARCH64',
      'SENTRY_SPLIT_DEBUG_INFO_DIR',
      'GITHUB_ACTIONS',
      'CI',
      'CC_STUB_VERSION',
    ];
    final parentPath = Platform.environment['PATH'] ?? '/usr/bin:/bin';
    final assignments = <String>[
      if (!withCurlStub) 'SENTRY_CLI=${cliStub.path}',
      'CC_ARGV_LOG=${argvLog.path}',
      'CC_FAKE_BIN=${cliStub.path}',
      'CC_CURL_LOG=${curlLog.path}',
      if (withToken) 'SENTRY_AUTH_TOKEN=$token',
      // The stub's directory first, so the download path under test never
      // reaches the real GitHub release over the network.
      'PATH=${withCurlStub ? '${binDir.path}:' : ''}$parentPath',
      for (final entry in env.entries) '${entry.key}=${entry.value}',
    ];

    final result = Process.runSync('env', <String>[
      for (final name in unset) ...['-u', name],
      ...assignments,
      'bash',
      '$repoRoot/scripts/release/sentry_upload.sh',
      ...args,
      '--build-dir',
      buildDir,
    ], workingDirectory: repoRoot);

    return _Run(
      result.exitCode,
      result.stdout as String,
      result.stderr as String,
      _parseArgv(argvLog.existsSync() ? argvLog.readAsStringSync() : ''),
    );
  }

  static List<List<String>> _parseArgv(String contents) {
    final calls = <List<String>>[];
    for (final line in const LineSplitter().convert(contents)) {
      if (line == '=== ARGV') {
        calls.add([]);
      } else if (line.startsWith('arg:') && calls.isNotEmpty) {
        calls.last.add(line.substring(4));
      }
    }
    return calls;
  }

  void _writeVersionJson(String assetsDir) {
    Directory(assetsDir).createSync(recursive: true);
    File('$assetsDir/version.json').writeAsStringSync(
      '{"app_name":"control_center","version":"9.9.9",'
      '"build_number":"7","package_name":"control_center"}',
    );
  }

  void _writeWebSources() {
    File('$buildDir/web/main.dart.js').writeAsStringSync('console.log(1);\n');
    File('$buildDir/web/main.dart.js.map').writeAsStringSync(
      '{"version":3,"sources":['
      '"/builds/flutter/packages/flutter/lib/src/widgets/app.dart",'
      '"../lib/main.dart","../../x.dart"],"mappings":"AAAA"}',
    );
  }

  void _writeMacosApp() {
    final contents = Directory(
      '$buildDir/macos/Build/Products/Release/Control Center.app/Contents',
    )..createSync(recursive: true);
    File('${contents.path}/Info.plist').writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
\t<key>CFBundleIdentifier</key>
\t<string>com.alev.control-center</string>
\t<key>CFBundleShortVersionString</key>
\t<string>1.5.0</string>
\t<key>CFBundleVersion</key>
\t<string>7</string>
</dict>
</plist>
''');
  }

  void _makeExecutable(File file) {
    Process.runSync('chmod', ['+x', file.path]);
  }

  static String get _cliStubSource =>
      '''
#!/usr/bin/env bash
set -euo pipefail
if [ "\${1:-}" = "--version" ]; then
  printf 'sentry-cli %s\\n' "\${CC_STUB_VERSION:-$cliVersion}"
  exit 0
fi
# The uploader hands the credential over in the environment; a command line is
# world-readable in a process listing and lands in CI logs.
[ -n "\${SENTRY_AUTH_TOKEN:-}" ] || { echo "stub: no SENTRY_AUTH_TOKEN" >&2; exit 3; }
{
  printf '=== ARGV\\n'
  for arg in "\$@"; do printf 'arg:%s\\n' "\$arg"; done
} >> "\$CC_ARGV_LOG"
''';

  static const _curlStubSource = '''
#!/usr/bin/env bash
set -euo pipefail
printf 'curl %s\\n' "\$*" >> "\$CC_CURL_LOG"
out=''
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o) out="\$2"; shift 2 ;;
    *) shift ;;
  esac
done
cp "\$CC_FAKE_BIN" "\$out"
''';
}

class _Run {
  _Run(this.exitCode, this.stdout, this.stderr, this.calls);

  final int exitCode;
  final String stdout;
  final String stderr;
  final List<List<String>> calls;
}
