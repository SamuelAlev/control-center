import 'package:cc_domain/features/pr_review/domain/services/ci_log_parser.dart';
import 'package:test/test.dart';

/// A realistic `dart test` failure, compact reporter, as CI captures it.
const _dartLog = '''
00:00 +0: loading test/auth_test.dart
00:02 +11: test/auth_test.dart: AuthService keeps a valid token
00:03 +12 -1: test/auth_test.dart: AuthService refreshes on 401 [E]
  Expected: <200>
    Actual: <401>

  package:matcher                             expect
  package:my_pkg/src/auth.dart 88:7           AuthService.refresh
  test/auth_test.dart 42:9                    main.<fn>

00:03 +12 -1: Some tests failed.
''';

/// A jest run, default reporter.
const _jestLog = '''
FAIL src/cart.test.ts
  Cart
    ✓ is empty by default (1 ms)
    ✕ applies the discount (7 ms)

  ● Cart › applies the discount

    expect(received).toBe(expected)

    Expected: 90
    Received: 100

      at Object.<anonymous> (src/cart.test.ts:14:23)
      at applyDiscount (src/cart.ts:31:9)
      at src/checkout.ts:8:3

Tests:       1 failed, 1 passed, 2 total
''';

/// A pytest run: traceback, location line, then the short summary.
const _pytestLog = '''
=================================== FAILURES ===================================
_________________________________ test_totals __________________________________

    def test_totals():
        cart = Cart()
>       assert cart.total() == 30
E       assert 25 == 30

tests/test_cart.py:12: AssertionError
---------------------------- Captured stderr call -----------------------------
Traceback (most recent call last):
  File "app/cart.py", line 44, in total
    return sum(self.items)
TypeError: unsupported operand type(s)
=========================== short test summary info ============================
FAILED tests/test_cart.py::test_totals - assert 25 == 30
''';

void main() {
  const parser = CiLogParser();

  group('parse — dart/flutter package:test', () {
    test('names the failing test from the [E] progress line', () {
      final signals = parser.parse(_dartLog);
      expect(signals.failingTests, [
        'test/auth_test.dart: AuthService refreshes on 401',
      ]);
    });

    test('ignores passing progress lines', () {
      final signals = parser.parse(_dartLog);
      expect(
        signals.failingTests.any((t) => t.contains('keeps a valid token')),
        isFalse,
      );
    });

    test('records the suite verdict despite its counter prefix', () {
      final signals = parser.parse(_dartLog);
      expect(signals.errorLines, contains('Some tests failed.'));
    });

    test('records a bare suite verdict too', () {
      final signals = parser.parse('Some tests failed.');
      expect(signals.errorLines, ['Some tests failed.']);
    });

    test('extracts package: and relative frames with their lines', () {
      final signals = parser.parse(_dartLog);
      expect(
        signals.frames,
        containsAll(const [
          CiFrame(filePath: 'package:my_pkg/src/auth.dart', line: 88),
          CiFrame(filePath: 'test/auth_test.dart', line: 42),
        ]),
      );
    });

    test('ignores a package frame with no line number', () {
      final signals = parser.parse(_dartLog);
      expect(
        signals.frames.any((f) => f.filePath.contains('matcher')),
        isFalse,
      );
    });

    test('extracts a file:// frame as an absolute path', () {
      final signals = parser.parse(
        'file:///home/runner/work/repo/repo/lib/src/auth.dart:12:5',
      );
      expect(signals.frames, [
        const CiFrame(
          filePath: '/home/runner/work/repo/repo/lib/src/auth.dart',
          line: 12,
        ),
      ]);
    });

    test('does not mistake an SDK frame for a repo file', () {
      final signals = parser.parse('dart:async/zone.dart 1234:5  runBody');
      expect(signals.frames, isEmpty);
    });
  });

  group('parse — jest/vitest', () {
    test('names the failing test, the bullet header and the suite', () {
      final signals = parser.parse(_jestLog);
      expect(
        signals.failingTests,
        containsAll(const [
          'FAIL src/cart.test.ts',
          'Cart › applies the discount',
          'applies the discount',
        ]),
      );
    });

    test('ignores passing tests', () {
      final signals = parser.parse(_jestLog);
      expect(
        signals.failingTests.any((t) => t.contains('is empty by default')),
        isFalse,
      );
    });

    test('extracts parenthesised and bare at-frames', () {
      final signals = parser.parse(_jestLog);
      expect(
        signals.frames,
        containsAll(const [
          CiFrame(filePath: 'src/cart.test.ts', line: 14),
          CiFrame(filePath: 'src/cart.ts', line: 31),
          CiFrame(filePath: 'src/checkout.ts', line: 8),
        ]),
      );
    });

    test('drops the timing suffix so a retried test de-duplicates', () {
      final signals = parser.parse(
        '  ✕ applies the discount (7 ms)\n  ✕ applies the discount (12 ms)\n',
      );
      expect(signals.failingTests, ['applies the discount']);
    });

    test('accepts the vitest × marker', () {
      final signals = parser.parse('   × Cart > loads the cart (4 ms)');
      expect(signals.failingTests, ['Cart > loads the cart']);
    });
  });

  group('parse — pytest', () {
    test('names the failing test id from the short summary', () {
      final signals = parser.parse(_pytestLog);
      expect(signals.failingTests, ['tests/test_cart.py::test_totals']);
    });

    test('captures the E-prefixed assertion line', () {
      final signals = parser.parse(_pytestLog);
      expect(signals.errorLines, contains('E       assert 25 == 30'));
    });

    test('extracts traceback and location frames', () {
      final signals = parser.parse(_pytestLog);
      expect(
        signals.frames,
        containsAll(const [
          CiFrame(filePath: 'tests/test_cart.py', line: 12),
          CiFrame(filePath: 'app/cart.py', line: 44),
        ]),
      );
    });

    test('a FAILED test id is not also counted as an error line', () {
      final signals = parser.parse(_pytestLog);
      expect(signals.errorLines.any((l) => l.startsWith('FAILED')), isFalse);
    });

    test('a FAILED line without a test id falls back to an error line', () {
      final signals = parser.parse('FAILED to upload the artifact');
      expect(signals.failingTests, isEmpty);
      expect(signals.errorLines, ['FAILED to upload the artifact']);
    });
  });

  group('parse — generic fallback', () {
    test('captures every recognized prefix', () {
      const log = '''
Error: Cannot find module './missing'
error: linker command failed with exit code 1
ERROR Build failed in 3.2s
✗ analyze
''';
      final signals = parser.parse(log);
      expect(signals.errorLines, [
        "Error: Cannot find module './missing'",
        'error: linker command failed with exit code 1',
        'ERROR Build failed in 3.2s',
        '✗ analyze',
      ]);
    });

    test('strips the GitHub Actions ##[error] marker', () {
      final signals = parser.parse(
        '##[error]Process completed with exit code 1',
      );
      expect(signals.errorLines, ['Process completed with exit code 1']);
    });

    test('keeps a bare ##[error] marker rather than an empty entry', () {
      final signals = parser.parse('##[error]');
      expect(signals.errorLines, ['##[error]']);
    });

    test('ignores ordinary output', () {
      final signals = parser.parse('Compiling lib/main.dart...\nDone in 4s\n');
      expect(signals.isEmpty, isTrue);
    });
  });

  group('parse — hygiene', () {
    test('empty input yields an empty result', () {
      expect(parser.parse('').isEmpty, isTrue);
      expect(parser.parse(''), same(CiSignals.empty));
    });

    test('CiSignals.empty is empty', () {
      expect(CiSignals.empty.isEmpty, isTrue);
      expect(CiSignals.empty.failingTests, isEmpty);
      expect(CiSignals.empty.errorLines, isEmpty);
      expect(CiSignals.empty.frames, isEmpty);
    });

    test('whitespace-only input yields an empty result', () {
      expect(parser.parse('   \n\n\t  \n').isEmpty, isTrue);
    });

    test('binary garbage never throws and invents nothing', () {
      final garbage = String.fromCharCodes(
        List<int>.generate(4096, (i) => (i * 7919) % 0xFFFF),
      );
      final signals = parser.parse(garbage);
      expect(signals.failingTests.length, lessThanOrEqualTo(50));
      expect(signals.errorLines.length, lessThanOrEqualTo(50));
      expect(signals.frames.length, lessThanOrEqualTo(50));
    });

    test('a single unrecognized line yields an empty result', () {
      expect(parser.parse('hello world').isEmpty, isTrue);
    });

    test('strips ANSI colour before matching', () {
      const log =
          '\x1B[31m✕ renders the header\x1B[39m\n'
          '\x1B[1m\x1B[31mError: boom\x1B[0m\n'
          '      at \x1B[36msrc/header.tsx\x1B[0m:9:4\n';
      final signals = parser.parse(log);
      expect(signals.failingTests, ['renders the header']);
      expect(signals.errorLines, ['Error: boom']);
      expect(signals.frames, [
        const CiFrame(filePath: 'src/header.tsx', line: 9),
      ]);
    });

    test('strips the GitHub Actions timestamp prefix', () {
      const log =
          '2026-08-20T12:34:56.7890123Z ##[error]Job failed\n'
          '2026-08-20T12:34:57.0000000Z FAILED tests/test_cart.py::test_totals\n'
          '2026-08-20T12:34:57.1000000Z   at src/cart.ts:31:9\n';
      final signals = parser.parse(log);
      expect(signals.errorLines, ['Job failed']);
      expect(signals.failingTests, ['tests/test_cart.py::test_totals']);
      expect(signals.frames, [
        const CiFrame(filePath: 'src/cart.ts', line: 31),
      ]);
    });

    test('handles CRLF and bare CR line breaks', () {
      const log = 'Error: one\r\n\rError: two\r';
      final signals = parser.parse(log);
      expect(signals.errorLines, ['Error: one', 'Error: two']);
    });

    test('de-duplicates while preserving first-seen order', () {
      const log = '''
Error: beta
Error: alpha
Error: beta
  at src/a.ts:1:1
  at src/a.ts:1:1
✕ flaky
✕ flaky
''';
      final signals = parser.parse(log);
      expect(signals.errorLines, ['Error: beta', 'Error: alpha']);
      expect(signals.frames, [const CiFrame(filePath: 'src/a.ts', line: 1)]);
      expect(signals.failingTests, ['flaky']);
    });

    test('caps error lines at 50, keeping the first', () {
      final log = [
        for (var i = 0; i < 400; i++) 'Error: failure $i',
      ].join('\n');
      final signals = parser.parse(log);
      expect(signals.errorLines, hasLength(CiLogParser.maxEntries));
      expect(signals.errorLines.first, 'Error: failure 0');
      expect(signals.errorLines.last, 'Error: failure 49');
    });

    test('caps frames at 50, keeping the first', () {
      final log = [
        for (var i = 0; i < 400; i++) '      at src/file$i.ts:$i:1',
      ].join('\n');
      final signals = parser.parse(log);
      expect(signals.frames, hasLength(CiLogParser.maxEntries));
      expect(signals.frames.first.filePath, 'src/file0.ts');
      expect(signals.frames.last.filePath, 'src/file49.ts');
    });

    test('caps failing tests at 50, keeping the first', () {
      final log = [for (var i = 0; i < 400; i++) '✕ case $i'].join('\n');
      final signals = parser.parse(log);
      expect(signals.failingTests, hasLength(CiLogParser.maxEntries));
      expect(signals.failingTests.first, 'case 0');
      expect(signals.failingTests.last, 'case 49');
    });

    test('a capped result stays capped across all three lists', () {
      final log = [
        for (var i = 0; i < 200; i++)
          '✕ case $i\nError: failure $i\n  at src/file$i.ts:1:1',
      ].join('\n');
      final signals = parser.parse(log);
      expect(signals.failingTests, hasLength(CiLogParser.maxEntries));
      expect(signals.errorLines, hasLength(CiLogParser.maxEntries));
      expect(signals.frames, hasLength(CiLogParser.maxEntries));
    });

    test('frames are equal by location, not by evidence', () {
      const a = CiFrame(filePath: 'lib/a.dart', line: 3, evidence: 'one');
      const b = CiFrame(filePath: 'lib/a.dart', line: 3, evidence: 'two');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const CiFrame(filePath: 'lib/a.dart', line: 4)));
      expect(a.toString(), contains('lib/a.dart:3'));
    });
  });

  group('correlate', () {
    test('matches a package: frame onto a changed file by suffix', () {
      final signals = parser.parse(_dartLog);
      final matches = parser.correlate(signals, ['lib/src/auth.dart']);
      expect(matches, hasLength(1));
      expect(matches.single.filePath, 'lib/src/auth.dart');
      expect(matches.single.line, 88);
      expect(
        matches.single.evidence,
        'test/auth_test.dart: AuthService refreshes on 401',
      );
    });

    test('matches an absolute CI path onto a repo-relative changed file', () {
      final signals = parser.parse(
        'file:///home/runner/work/repo/repo/lib/src/auth.dart:12:5',
      );
      final matches = parser.correlate(signals, ['lib/src/auth.dart']);
      expect(matches, [
        const CiCorrelation(filePath: 'lib/src/auth.dart', line: 12),
      ]);
    });

    test('keeps the caller spelling of the changed path', () {
      final signals = parser.parse('  at src/cart.ts:31:9');
      final matches = parser.correlate(signals, ['./src/cart.ts']);
      expect(matches.single.filePath, './src/cart.ts');
    });

    test('normalizes windows separators on both sides', () {
      final signals = parser.parse(r'  at C:\proj\src\cart.ts:31:9');
      final matches = parser.correlate(signals, ['src/cart.ts']);
      expect(matches.single.filePath, 'src/cart.ts');
      expect(matches.single.line, 31);
    });

    test('returns nothing when there are no changed files', () {
      final signals = parser.parse(_dartLog);
      expect(parser.correlate(signals, const []), isEmpty);
    });

    test('returns nothing when there are no frames', () {
      expect(parser.correlate(CiSignals.empty, ['lib/src/auth.dart']), isEmpty);
    });

    test('requires a parent segment, not just the basename', () {
      final signals = parser.parse('  at src/cart.ts:31:9');
      expect(parser.correlate(signals, ['lib/other/cart.ts']), isEmpty);
    });

    test(
      'a bare basename matches when exactly one changed file carries it',
      () {
        final signals = parser.parse('package:my_pkg/auth.dart 5:1  refresh');
        final matches = parser.correlate(signals, [
          'lib/src/auth.dart',
          'lib/src/cart.dart',
        ]);
        expect(matches, hasLength(1));
        expect(matches.single.filePath, 'lib/src/auth.dart');
        expect(matches.single.line, 5);
      },
    );

    test('a bare basename is dropped when several changed files carry it', () {
      final signals = parser.parse('package:my_pkg/auth.dart 5:1  refresh');
      final matches = parser.correlate(signals, [
        'lib/a/auth.dart',
        'lib/b/auth.dart',
      ]);
      expect(matches, isEmpty);
    });

    test('a suffix tie is dropped rather than guessed', () {
      final signals = parser.parse('package:my_pkg/src/auth.dart 88:7  x');
      final matches = parser.correlate(signals, [
        'a/src/auth.dart',
        'b/src/auth.dart',
      ]);
      expect(matches, isEmpty);
    });

    test('prefers the candidate whose whole path the frame contains', () {
      final signals = parser.parse('file:///w/repo/lib/src/auth.dart:88:7');
      final matches = parser.correlate(signals, [
        'other/lib/src/auth.dart',
        'lib/src/auth.dart',
      ]);
      expect(matches, hasLength(1));
      expect(matches.single.filePath, 'lib/src/auth.dart');
    });

    test('falls back to the nearest error line when no test failed', () {
      final signals = parser.parse(_pytestLog);
      final matches = parser.correlate(signals, ['app/cart.py']);
      expect(matches, hasLength(1));
      expect(matches.single.evidence, 'E       assert 25 == 30');
    });

    test('prefers a failing test name over an error line as evidence', () {
      const log = '''
Error: something upstream
● Cart › applies the discount
  at src/cart.ts:31:9
''';
      final signals = parser.parse(log);
      final matches = parser.correlate(signals, ['src/cart.ts']);
      expect(matches.single.evidence, 'Cart › applies the discount');
    });

    test('leaves evidence empty when nothing preceded the frame', () {
      final signals = parser.parse('  at src/cart.ts:31:9');
      final matches = parser.correlate(signals, ['src/cart.ts']);
      expect(matches.single.evidence, isEmpty);
    });

    test('de-duplicates by file and line', () {
      const log = '''
● Cart › applies the discount
  at Object.<anonymous> (src/cart.ts:31:9)
  at applyDiscount (src/cart.ts:31:9)
  at reprice (src/cart.ts:44:2)
''';
      final signals = parser.parse(log);
      final matches = parser.correlate(signals, ['src/cart.ts']);
      expect(matches, hasLength(2));
      expect(matches.map((m) => m.line), [31, 44]);
    });

    test('correlations compare by value', () {
      const a = CiCorrelation(filePath: 'lib/a.dart', line: 3, evidence: 'e');
      expect(
        a,
        const CiCorrelation(filePath: 'lib/a.dart', line: 3, evidence: 'e'),
      );
      expect(
        a.hashCode,
        const CiCorrelation(
          filePath: 'lib/a.dart',
          line: 3,
          evidence: 'e',
        ).hashCode,
      );
      expect(a, isNot(const CiCorrelation(filePath: 'lib/a.dart', line: 4)));
      expect(a.toString(), contains('lib/a.dart:3'));
    });

    test('correlates a jest run end to end', () {
      final signals = parser.parse(_jestLog);
      final matches = parser.correlate(signals, [
        'src/cart.ts',
        'src/checkout.ts',
      ]);
      expect(matches.map((m) => m.filePath), [
        'src/cart.ts',
        'src/checkout.ts',
      ]);
      expect(
        matches.every((m) => m.evidence == 'Cart › applies the discount'),
        isTrue,
      );
    });
  });
}
