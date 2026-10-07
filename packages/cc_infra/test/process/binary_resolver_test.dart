import 'dart:io';

import 'package:cc_infra/src/process/binary_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [resolveBinaryPath] — the install-location prober that finds
/// bundled-app CLIs (Homebrew, Nix, fnm, …) when the launcher's minimal PATH
/// misses them. Covers the VULN-002 input rejection and the successful
/// resolution of a known-present binary (`git`/`ls`) on the test host.
void main() {
  group('resolveBinaryPath — input validation (VULN-002)', () {
    test('rejects an empty name', () async {
      expect(await resolveBinaryPath(''), isNull);
    });

    test('rejects a path separator', () async {
      expect(await resolveBinaryPath('a/b'), isNull);
      expect(await resolveBinaryPath(r'a\b'), isNull);
    });

    test("rejects '..' traversal", () async {
      expect(await resolveBinaryPath('..'), isNull);
      expect(await resolveBinaryPath('a..b'), isNull); // contains ..
    });

    test('rejects a leading dash (option injection)', () async {
      expect(await resolveBinaryPath('--version'), isNull);
    });

    test('rejects an absolute path', () async {
      expect(await resolveBinaryPath('/usr/bin/git'), isNull);
    });
  });

  group('resolveBinaryPath — resolution', () {
    test('resolves a known-on-PATH binary (git or ls)', () async {
      // Either git or ls is virtually always on PATH/known dirs on the runner.
      final git = await resolveBinaryPath('git');
      final ls = await resolveBinaryPath('ls');
      expect(git != null || ls != null, isTrue);
    });

    test('returns an absolute path or bare name for a found binary', () async {
      final git = await resolveBinaryPath('git');
      if (git != null) {
        // Candidate-hit yields an absolute path; PATH-fallback yields the
        // bare name. Either is non-empty.
        expect(git, isNotEmpty);
      }
    });

    test('returns null for a binary that does not exist', () async {
      final res = await resolveBinaryPath('definitely-not-a-real-binary-xyz');
      expect(res, isNull);
    });
  });

  group('compareVersionDirs', () {
    test('orders versions numerically, not as strings', () {
      final dirs = ['/n/v9.11.2', '/n/v26.10.0', '/n/v24.18.0', '/n/v24.9.0']
        ..sort(compareVersionDirs);
      expect(dirs, ['/n/v9.11.2', '/n/v24.9.0', '/n/v24.18.0', '/n/v26.10.0']);
    });

    test('sorts unversioned names below every version', () {
      final dirs = ['/n/v1.0.0', '/n/system', '/n/.DS_Store']
        ..sort(compareVersionDirs);
      expect(dirs.last, '/n/v1.0.0');
    });
  });

  group('versionManagedBinaryPaths', () {
    late Directory home;

    setUp(() => home = Directory.systemTemp.createTempSync('cc-vm-home-'));
    tearDown(() => home.deleteSync(recursive: true));

    void install(String root, String version, String binSubpath) => Directory(
      p.join(home.path, root, version, binSubpath),
    ).createSync(recursive: true);

    test('yields every fnm and nvm version, newest first', () {
      for (final v in ['v9.11.2', 'v24.18.0', 'v26.10.0']) {
        install('.local/share/fnm/node-versions', v, 'installation/bin');
      }
      install('.nvm/versions/node', 'v20.1.0', 'bin');

      final paths = versionManagedBinaryPaths('node', home: home.path).toList();
      // The resolver joins with `/` on every platform.
      final fnm = '${home.path}/.local/share/fnm/node-versions';
      expect(paths, [
        '${home.path}/.nvm/versions/node/v20.1.0/bin/node',
        '$fnm/v26.10.0/installation/bin/node',
        '$fnm/v24.18.0/installation/bin/node',
        '$fnm/v9.11.2/installation/bin/node',
      ]);
    });

    test('yields nothing for an unsafe name or an empty home', () {
      install('.local/share/fnm/node-versions', 'v1.0.0', 'installation/bin');
      expect(versionManagedBinaryPaths('../node', home: home.path), isEmpty);
      expect(versionManagedBinaryPaths('node', home: ''), isEmpty);
    });
  });
}
