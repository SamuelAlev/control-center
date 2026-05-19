import 'package:cc_domain/features/sandboxing/domain/command_policy/shell_command_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseShellCommand', () {
    test('single command', () {
      expect(parseShellCommand('git push'), ['git push']);
    });

    test('pipe splits commands', () {
      expect(parseShellCommand('git log | grep foo'), [
        'git log',
        'grep foo',
      ]);
    });

    test('&& splits commands', () {
      expect(parseShellCommand('git add . && git commit'), [
        'git add .',
        'git commit',
      ]);
    });

    test('|| splits commands', () {
      expect(parseShellCommand('cmd1 || cmd2'), ['cmd1', 'cmd2']);
    });

    test('; splits commands', () {
      expect(parseShellCommand('cmd1; cmd2'), ['cmd1', 'cmd2']);
    });

    test('quoted pipes are not split', () {
      expect(parseShellCommand("echo 'a | b'"), ["echo 'a | b'"]);
    });

    test('double-quoted pipes are not split', () {
      expect(parseShellCommand('echo "a | b"'), ['echo "a | b"']);
    });

    test('subshell parentheses are not split', () {
      expect(parseShellCommand('(cd /tmp && ls) | grep x'), [
        '(cd /tmp && ls)',
        'grep x',
      ]);
    });
  });

  group('expandShellInvocation', () {
    test('bash -c extracts inner command', () {
      final result = expandShellInvocation("bash -c 'git push'");
      expect(result, contains("git push"));
      expect(result.length, greaterThanOrEqualTo(2)); // outer + inner
    });

    test('sh -c extracts inner command', () {
      final result = expandShellInvocation("sh -c 'sudo rm -rf /'");
      expect(result, contains('sudo rm -rf /'));
    });

    test('zsh -lc extracts inner command (combined flags)', () {
      final result = expandShellInvocation("zsh -lc 'git push'");
      expect(result, contains('git push'));
    });

    test('non-shell command returns as-is', () {
      expect(expandShellInvocation('git push'), ['git push']);
    });

    test('python is not treated as shell', () {
      expect(expandShellInvocation('python3 -c "print(1)"'), [
        'python3 -c "print(1)"',
      ]);
    });
  });

  group('matchesTokenizedCommandRule', () {
    test('exact match', () {
      expect(
        matchesTokenizedCommandRule(
          normalizeCommandTokens('git push'),
          normalizeCommandTokens('git push'),
        ),
        isTrue,
      );
    });

    test('prefix match with extra args', () {
      expect(
        matchesTokenizedCommandRule(
          normalizeCommandTokens('git push origin main'),
          normalizeCommandTokens('git push'),
        ),
        isTrue,
      );
    });

    test('no match different executable', () {
      expect(
        matchesTokenizedCommandRule(
          normalizeCommandTokens('git pull'),
          normalizeCommandTokens('git push'),
        ),
        isFalse,
      );
    });

    test('global flag with value consumption (git -C /tmp push)', () {
      expect(
        matchesTokenizedCommandRule(
          normalizeCommandTokens('git -C /tmp push'),
          normalizeCommandTokens('git push'),
        ),
        isTrue,
      );
    });
    test('presence check with = suffix', () {
      expect(
        matchesTokenizedCommandRule(
          normalizeCommandTokens('docker run --privileged=true'),
          normalizeCommandTokens('docker run --privileged='),
        ),
        isTrue,
      );
    });

    test('presence check with = suffix requires value', () {
      // Bare --privileged (no =value) does NOT match --privileged=
      expect(
        matchesTokenizedCommandRule(
          normalizeCommandTokens('docker run --privileged'),
          normalizeCommandTokens('docker run --privileged='),
        ),
        isFalse,
      );
    });

    test('presence check fails when absent', () {
      expect(
        matchesTokenizedCommandRule(
          normalizeCommandTokens('docker run alpine'),
          normalizeCommandTokens('docker run --privileged='),
        ),
        isFalse,
      );
    });
  });

  group('normalizeCommandTokens', () {
    test('strips leading path from executable', () {
      expect(
        normalizeCommandTokens('/usr/bin/git push'),
        ['git', 'push'],
      );
    });

    test('collapses extra spaces', () {
      expect(
        normalizeCommandTokens('git   push'),
        ['git', 'push'],
      );
    });
  });

  group('basename', () {
    test('unix path', () {
      expect(basename('/usr/bin/git'), 'git');
    });

    test('no path separator', () {
      expect(basename('git'), 'git');
    });

    test('windows path', () {
      expect(basename(r'C:\bin\git'), 'git');
    });
  });
}
