import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Contract tests for `scripts/release/check_no_bundled_secrets.sh`, the
/// release gate that keeps third-party keys out of every shipped binary.
///
/// Credentials in the fixtures are assembled at run time so this file holds
/// none a secret scanner could flag.
void main() {
  final root = Directory.current.path;
  const script = 'scripts/release/check_no_bundled_secrets.sh';

  ProcessResult run(List<String> args) =>
      Process.runSync('bash', [script, ...args], workingDirectory: root);

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('cc_secret_scan_'));
  tearDown(() => dir.deleteSync(recursive: true));

  File plant(String name, String content) =>
      File('${dir.path}/$name')..writeAsBytesSync([0, ...content.codeUnits, 0]);

  test('its self-test passes', () {
    final result = run(['--self-test']);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });

  test('a GitHub token inside a binary fails the scan', () {
    plant('app.so', 'gh${'p_'}${'A1b2' * 9}');
    final result = run([dir.path]);
    expect(result.exitCode, 1);
    expect(result.stderr, contains('GitHub token'));
  });

  test('a Google client secret fails the scan', () {
    plant('main.dart.js', 'const s="GOC${'SPX-'}${'a' * 28}";');
    final result = run([dir.path]);
    expect(result.exitCode, 1);
    expect(result.stderr, contains('Google OAuth client secret'));
  });

  test('builtin credential plumbing fails the scan', () {
    plant('cc_server', 'CC_BUILT${'IN_'}GOOGLE_CLIENT_ID');
    expect(run([dir.path]).exitCode, 1);
  });

  test('redaction regex source passes', () {
    plant(
      'cc_server',
      r"RegExp(r'\bghp_[A-Za-z0-9]{36}\b') xox[abeoprs]- GOCSPX- AIza Iv23",
    );
    final result = run([dir.path]);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  });

  test('a missing path fails instead of passing silently', () {
    final result = run(['${dir.path}/nope']);
    expect(result.exitCode, 66);
  });

  test('every release build job scans what it ships', () {
    final workflow = File(
      '$root/.github/workflows/release.yml',
    ).readAsStringSync();
    for (final paths in [
      'build/macos/Build/Products/Release apps/cc_server/build/cli',
      '"build/windows/\$ARCH/runner/Release" apps/cc_server/build/cli',
      [
        'build/linux/x64/release/bundle',
        'apps/cc_server/build/cli',
        'apps/cc_demo_server/build/cli',
      ].join(' '),
      'build/web apps/cc_remote/build/web',
    ]) {
      expect(workflow, contains('$script $paths'), reason: paths);
    }
    expect(
      RegExp(RegExp.escape('$script --self-test')).allMatches(workflow),
      hasLength(4),
    );
  });
}
