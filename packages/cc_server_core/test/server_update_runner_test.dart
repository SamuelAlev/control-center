import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late Directory bundle;
  late Map<String, List<int>> fixtures; // path → bytes served by the fake API
  late List<String> log;
  late bool liveServerAnswers;
  int liveConnections = 0;

  /// `tar xf` is real (bsdtar exists on the CI/dev runners); the gh CLI is
  /// faked. With [ghPresent] false it is "not installed", so attestation
  /// SKIPS; with it true, `gh --version` succeeds and the verification itself
  /// is controlled by [attestationPasses] — the distinction that separates a
  /// soft skip from a hard refusal.
  ProcessRunner tarRunner({
    bool ghPresent = false,
    bool attestationPasses = true,
  }) => (String exe, List<String> args) async {
    if (exe == 'gh') {
      if (!ghPresent) {
        return ProcessResult(0, 1, '', 'gh not installed (test fake)');
      }
      final isVerify = args.contains('verify');
      if (isVerify && !attestationPasses) {
        return ProcessResult(0, 1, '', 'no attestation matches (test fake)');
      }
      return ProcessResult(0, 0, '', '');
    }
    return Process.run(exe, args);
  };

  ServerUpdateRunner runner({
    bool apply = false,
    bool force = false,
    Uri? probe,
    ProcessRunner? process,
    String os = 'linux',
    String? installOverride,
  }) => ServerUpdateRunner(
    log: log.add,
    probeUri: probe,
    installDir: installOverride ?? bundle.path,
    archOverride: 'x64',
    osOverride: os,
    releaseApiBase: 'https://example.test',
    environment: const {},
    scriptPath: '/opt/cc/bin/cc_server',
    dockerEnvFile: '${tmp.path}/no-dockerenv',
    httpGet: (uri) async {
      // The live-server drain probe.
      if (uri.path == '/healthz') {
        if (!liveServerAnswers) {
          throw const SocketException('no live server');
        }
        return (
          200,
          utf8.encode(
            jsonEncode({'status': 'ok', 'connections': liveConnections}),
          ),
        );
      }
      final bytes = fixtures[uri.path];
      if (bytes == null) {
        return (404, utf8.encode('not found'));
      }
      return (200, bytes);
    },
    processRunner: process ?? tarRunner(),
  );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cc_update_test');
    bundle = Directory('${tmp.path}/cc_server-9.9.9-linux-x64')..createSync();
    final oldBinary = File('${bundle.path}/bin/cc_server')
      ..createSync(recursive: true)
      ..writeAsStringSync('old binary ${BuildInfo.buildVersion}');
    expect(oldBinary.existsSync(), isTrue);

    fixtures = {};
    log = [];
    liveServerAnswers = false;
    liveConnections = 0;

    // A "newer" release whose archive layout mirrors cc_server_package.sh's
    // (<bundle>/bin/cc_server): built with real tar so extraction is real.
    final staging = Directory('${tmp.path}/make')..createSync();
    final inner = Directory('${staging.path}/cc_server-1.2.3-linux-x64')
      ..createSync(recursive: true);
    final newBinary = File('${inner.path}/bin/cc_server')
      ..createSync(recursive: true);
    newBinary.writeAsStringSync('new binary 1.2.3');
    final archivePath = '${staging.path}/cc_server-1.2.3-linux-x64.tar.gz';
    final tar = await Process.run('tar', [
      'czf',
      archivePath,
      '-C',
      staging.path,
      'cc_server-1.2.3-linux-x64',
    ]);
    expect(tar.exitCode, 0, reason: 'test fixture build (tar) failed');
    final archive = File(archivePath).readAsBytesSync();

    fixtures['/repos/SamuelAlev/control-center/releases/latest'] = utf8.encode(
      jsonEncode({
        'tag_name': 'v1.2.3',
        'html_url':
            'https://github.com/SamuelAlev/control-center/releases/v1.2.3',
        'published_at': '2026-01-01T00:00:00Z',
        'assets': [
          {
            'name': 'cc_server-1.2.3-linux-x64.tar.gz',
            'browser_download_url':
                'https://example.test/download/cc_server-1.2.3-linux-x64.tar.gz',
          },
          {
            'name': 'cc_server-1.2.3-macos-arm64.tar.gz',
            'browser_download_url': 'https://example.test/mac',
          },
          {
            'name': 'SHA256SUMS.txt',
            'browser_download_url':
                'https://example.test/download/SHA256SUMS.txt',
          },
        ],
      }),
    );
    fixtures['/download/cc_server-1.2.3-linux-x64.tar.gz'] = archive;
    fixtures['/download/SHA256SUMS.txt'] = utf8.encode(
      '${sha256.convert(archive)}  cc_server-1.2.3-linux-x64.tar.gz\n',
    );
  });

  tearDown(() async {
    try {
      tmp.deleteSync(recursive: true);
    } on Object {
      // Best-effort.
    }
  });

  test('no-op when the binary is managed by the desktop app', () async {
    final r = ServerUpdateRunner(
      log: log.add,
      installDir: bundle.path,
      environment: const {'CC_EMBEDDED': '1'},
      scriptPath: '/opt/cc/bin/cc_server',
    );
    expect(await r.run(), 0);
    expect(log.join('\n'), contains('managed by the Control Center app'));
  });

  test('no-op inside Docker and prints the pull line', () async {
    final r = ServerUpdateRunner(
      log: log.add,
      installDir: bundle.path,
      environment: const {'container': 'docker'},
      scriptPath: '/opt/cc/bin/cc_server',
    );
    expect(await r.run(), 0);
    expect(
      log.join('\n'),
      contains('docker pull ghcr.io/samuelalev/cc-server:latest'),
    );
  });

  test('refuses an unrecognised install layout', () async {
    final r = ServerUpdateRunner(
      log: log.add,
      installDir: '${tmp.path}/not-a-layout',
      environment: const {},
      scriptPath: '/opt/cc/bin/cc_server',
    );
    expect(await r.run(), 1);
    expect(log.join('\n'), contains('refusing'));
  });

  test('up to date when the latest release matches the build', () async {
    fixtures['/repos/SamuelAlev/control-center/releases/latest'] = utf8.encode(
      jsonEncode({
        'tag_name': 'v${BuildInfo.buildVersion}',
        'assets': const [],
      }),
    );
    expect(await runner().run(), 0);
    expect(log.join('\n'), contains('up to date'));
    // Nothing staged next to the install.
    expect(
      Directory('${tmp.path}/cc_server-9.9.9-linux-x64.staging').existsSync(),
      isFalse,
    );
  });

  test('check + download + verify + stage (no apply)', () async {
    expect(await runner().run(), 0);
    final out = log.join('\n');
    expect(out, contains('Update available: v1.2.3'));
    expect(out, contains('SHA-256 verified'));
    expect(out, contains('cc_server update --apply'));
    // The install itself is untouched without --apply.
    expect(
      File('${bundle.path}/bin/cc_server').readAsStringSync(),
      contains('old binary'),
    );
  });

  test('refuses on SHA-256 mismatch (fail closed)', () async {
    fixtures['/download/SHA256SUMS.txt'] = utf8.encode(
      '${'0' * 64}  cc_server-1.2.3-linux-x64.tar.gz\n',
    );
    expect(await runner().run(), 1);
    expect(log.join('\n'), contains('SHA-256 mismatch'));
  });

  test('refuses when the release has no SHA256SUMS.txt', () async {
    final latest =
        fixtures['/repos/SamuelAlev/control-center/releases/latest']!;
    final json = jsonDecode(utf8.decode(latest)) as Map<String, dynamic>;
    (json['assets'] as List).removeWhere(
      (a) => (a as Map)['name'] == 'SHA256SUMS.txt',
    );
    fixtures['/repos/SamuelAlev/control-center/releases/latest'] = utf8.encode(
      jsonEncode(json),
    );
    expect(await runner().run(), 1);
    expect(log.join('\n'), contains('no SHA256SUMS.txt'));
  });

  test('apply refuses while a live server answers the probe', () async {
    liveServerAnswers = true;
    liveConnections = 2;
    expect(
      await runner(
        probe: Uri.parse('https://example.test/healthz'),
      ).run(apply: true),
      1,
    );
    final out = log.join('\n');
    expect(out, contains('refusing to apply'));
    expect(out, contains('2 open client sessions'));
    expect(
      File('${bundle.path}/bin/cc_server').readAsStringSync(),
      contains('old binary'),
    );
  });

  test('apply swaps the whole tree and keeps one .bak', () async {
    expect(
      await runner(
        probe: Uri.parse('https://example.test/healthz'),
      ).run(apply: true),
      0,
    );
    expect(
      File('${bundle.path}/bin/cc_server').readAsStringSync(),
      contains('new binary 1.2.3'),
    );
    final bak = Directory('${bundle.path}.bak');
    expect(bak.existsSync(), isTrue);
    expect(
      File('${bak.path}/bin/cc_server').readAsStringSync(),
      contains('old binary'),
    );
    // Staging scratch is spent.
    expect(
      Directory('${tmp.path}/cc_server-9.9.9-linux-x64.staging').existsSync(),
      isFalse,
    );
  });

  test('apply with --force documents the dropped sessions', () async {
    liveServerAnswers = true;
    liveConnections = 1;
    expect(
      await runner(
        probe: Uri.parse('https://example.test/healthz'),
      ).run(apply: true, force: true),
      0,
    );
    final out = log.join('\n');
    expect(out, contains('--force: applying anyway'));
    expect(out, contains('1 open client session'));
    expect(
      File('${bundle.path}/bin/cc_server').readAsStringSync(),
      contains('new binary 1.2.3'),
    );
  });

  test('refuses a release OLDER than this binary', () async {
    // `releases/latest` moving backwards (a yank, or a locally built binary
    // ahead of the published one) must never silently roll a server back.
    fixtures['/repos/SamuelAlev/control-center/releases/latest'] = utf8.encode(
      jsonEncode({'tag_name': 'v0.0.0', 'assets': const []}),
    );
    expect(await runner().run(), 1);
    final out = log.join('\n');
    expect(out, contains('is OLDER than this binary'));
    expect(out, contains('--allow-downgrade'));
  });

  test('--allow-downgrade installs the older release deliberately', () async {
    // A real downgrade needs a real archive, so reuse the 1.2.3 fixture and
    // claim this binary is newer than it.
    final latest =
        fixtures['/repos/SamuelAlev/control-center/releases/latest']!;
    final json = jsonDecode(utf8.decode(latest)) as Map<String, dynamic>;
    json['tag_name'] = 'v0.0.0-older';
    // Keep the 1.2.3 asset names — assetFor matches on os/arch, not version.
    fixtures['/repos/SamuelAlev/control-center/releases/latest'] = utf8.encode(
      jsonEncode(json),
    );
    expect(await runner().run(allowDowngrade: true), 0);
    expect(log.join('\n'), contains('--allow-downgrade'));
  });

  test('refuses when gh is present and attestation fails', () async {
    // gh available + verification failure is a HARD refusal (the soft skip
    // only applies when gh is missing entirely).
    expect(
      await runner(
        process: tarRunner(ghPresent: true, attestationPasses: false),
      ).run(),
      1,
    );
    expect(log.join('\n'), contains('SLSA attestation verification failed'));
    expect(
      File('${bundle.path}/bin/cc_server').readAsStringSync(),
      contains('old binary'),
    );
  });

  test('verifies the attestation against the repo, not just the owner', () async {
    final calls = <List<String>>[];
    final recording = ServerUpdateRunner(
      log: log.add,
      installDir: bundle.path,
      archOverride: 'x64',
      osOverride: 'linux',
      releaseApiBase: 'https://example.test',
      environment: const {},
      scriptPath: '/opt/cc/bin/cc_server',
      dockerEnvFile: '${tmp.path}/no-dockerenv',
      httpGet: (uri) async {
        final bytes = fixtures[uri.path];
        return bytes == null
            ? (404, utf8.encode('not found'))
            : (200, bytes);
      },
      processRunner: (exe, args) async {
        if (exe == 'gh') {
          calls.add(args);
          return ProcessResult(0, 0, '', '');
        }
        return Process.run(exe, args);
      },
    );
    expect(await recording.run(), 0);

    final verify = calls.firstWhere((a) => a.contains('verify'));
    expect(verify, contains('--repo'));
    expect(verify, contains('SamuelAlev/control-center'));
    expect(
      verify,
      isNot(contains('--owner')),
      reason: '--owner accepts an artifact from any repo under the org',
    );
    expect(log.join('\n'), contains('SLSA attestation verified'));
  });

  test('a second run reuses the verified staged archive', () async {
    expect(await runner().run(), 0);
    final downloads = <String>[];
    final counting = ServerUpdateRunner(
      log: log.add,
      installDir: bundle.path,
      archOverride: 'x64',
      osOverride: 'linux',
      releaseApiBase: 'https://example.test',
      environment: const {},
      scriptPath: '/opt/cc/bin/cc_server',
      dockerEnvFile: '${tmp.path}/no-dockerenv',
      httpGet: (uri) async {
        final bytes = fixtures[uri.path];
        if (bytes == null) {
          return (404, utf8.encode('not found'));
        }
        return (200, bytes);
      },
      httpDownload: (uri, file) async {
        downloads.add(uri.path);
        file.writeAsBytesSync(fixtures[uri.path]!);
        return 200;
      },
      processRunner: tarRunner(),
    );
    log.clear();
    expect(await counting.run(), 0);

    expect(downloads, isEmpty, reason: 'the archive was already verified');
    expect(log.join('\n'), contains('Reusing the verified'));
  });

  test('a corrupted staged archive is re-downloaded, not trusted', () async {
    expect(await runner().run(), 0);
    final staged = File(
      '${tmp.path}/cc_server-9.9.9-linux-x64.staging/'
      'cc_server-1.2.3-linux-x64.tar.gz',
    );
    staged.writeAsBytesSync(utf8.encode('corrupted'));

    log.clear();
    expect(await runner().run(), 0);
    final out = log.join('\n');
    expect(out, isNot(contains('Reusing the verified')));
    expect(out, contains('SHA-256 verified'));
  });

  test('windows applies by parking the locked exe, not renaming the '
      'directory', () async {
    // Windows refuses to rename a directory containing a running image, so
    // the whole POSIX swap is wrong there. This runs the windows code path on
    // the test host via osOverride.
    final winBundle = Directory('${tmp.path}/cc_server-9.9.9-windows-x64')
      ..createSync();
    File('${winBundle.path}/bin/cc_server.exe')
      ..createSync(recursive: true)
      ..writeAsStringSync('old exe');

    final staging = Directory('${tmp.path}/win-make')..createSync();
    final inner = Directory('${staging.path}/cc_server-1.2.3-windows-x64')
      ..createSync(recursive: true);
    File('${inner.path}/bin/cc_server.exe')
      ..createSync(recursive: true)
      ..writeAsStringSync('new exe 1.2.3');
    final archivePath = '${staging.path}/cc_server-1.2.3-windows-x64.zip';
    final tar = await Process.run('tar', [
      'czf',
      archivePath,
      '-C',
      staging.path,
      'cc_server-1.2.3-windows-x64',
    ]);
    expect(tar.exitCode, 0, reason: 'windows fixture build failed');
    final archive = File(archivePath).readAsBytesSync();

    fixtures['/repos/SamuelAlev/control-center/releases/latest'] = utf8.encode(
      jsonEncode({
        'tag_name': 'v1.2.3',
        'assets': [
          {
            'name': 'cc_server-1.2.3-windows-x64.zip',
            'browser_download_url':
                'https://example.test/download/cc_server-1.2.3-windows-x64.zip',
          },
          {
            'name': 'SHA256SUMS.txt',
            'browser_download_url':
                'https://example.test/download/SHA256SUMS.txt',
          },
        ],
      }),
    );
    fixtures['/download/cc_server-1.2.3-windows-x64.zip'] = archive;
    fixtures['/download/SHA256SUMS.txt'] = utf8.encode(
      '${sha256.convert(archive)}  cc_server-1.2.3-windows-x64.zip\n',
    );

    expect(
      await runner(os: 'windows', installOverride: winBundle.path).run(
        apply: true,
      ),
      0,
    );

    expect(
      File('${winBundle.path}/bin/cc_server.exe').readAsStringSync(),
      contains('new exe 1.2.3'),
    );
    // The previous image is parked beside it (deletable once unlocked) and
    // the install directory itself was never renamed.
    expect(
      File('${winBundle.path}/bin/cc_server.exe.old').readAsStringSync(),
      contains('old exe'),
    );
    expect(Directory('${winBundle.path}.bak').existsSync(), isFalse);
  });

  test('compareVersions orders releases, including pre-releases', () {
    expect(compareVersions('1.2.3', '1.2.3'), 0);
    expect(compareVersions('1.2.4', '1.2.3'), greaterThan(0));
    expect(compareVersions('1.2.3', '1.2.4'), lessThan(0));
    expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
    // Missing components are zero, not "shorter therefore older".
    expect(compareVersions('1.2', '1.2.0'), 0);
    // A pre-release precedes the release it leads up to.
    expect(compareVersions('1.2.0-rc.1', '1.2.0'), lessThan(0));
    expect(compareVersions('1.2.0', '1.2.0-rc.1'), greaterThan(0));
    // Build metadata never affects precedence.
    expect(compareVersions('1.2.0+abc', '1.2.0+def'), 0);
  });

  test('UpdateRelease.assetFor picks the os/arch archive', () {
    final release = UpdateRelease.fromJson({
      'tag_name': 'v1.0.0',
      'assets': [
        {
          'name': 'cc_server-1.0.0-macos-arm64.tar.gz',
          'browser_download_url': 'u1',
        },
        {
          'name': 'cc_server-1.0.0-linux-x64.tar.gz',
          'browser_download_url': 'u2',
        },
        {
          'name': 'cc_server-1.0.0-windows-x64.zip',
          'browser_download_url': 'u3',
        },
      ],
    })!;
    expect(release.version, '1.0.0');
    expect(release.assetFor('linux', 'x64')!.url, 'u2');
    expect(release.assetFor('windows', 'x64')!.url, 'u3');
    expect(release.assetFor('linux', 'arm64'), isNull);
  });
}
