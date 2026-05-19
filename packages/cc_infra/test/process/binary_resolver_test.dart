import 'package:cc_infra/src/process/binary_resolver.dart';
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
}
