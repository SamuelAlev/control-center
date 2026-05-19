import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CcBlockBoundaryScanner', () {
    test('a blank line seals at the start of the next block', () {
      final s = CcBlockBoundaryScanner()..scan('one\n\ntwo\n');
      // Boundary sits AFTER the blank line, at the start of "two".
      expect(s.boundary, 'one\n\n'.length);
    });

    test('a blank line inside a fence is not a boundary', () {
      // scan() takes the full accumulated text each call.
      final s = CcBlockBoundaryScanner()..scan('```\ncode\n\nmore\n');
      expect(s.boundary, 0);
      // Closing the fence + a following blank + a confirming line re-enables
      // sealing.
      s.scan('```\ncode\n\nmore\n```\n\nafter\nx\n');
      expect(s.boundary, greaterThan(0));
    });

    test('a blank line inside <details> is not a boundary', () {
      const inner = '<details>\n<summary>x</summary>\n\nbody\n';
      final s = CcBlockBoundaryScanner()..scan(inner);
      expect(s.boundary, 0);
      s.scan('$inner</details>\n\nafter\nx\n');
      expect(s.boundary, greaterThan(0));
    });

    test('a loose list does not seal mid-list on an indented continuation', () {
      final s = CcBlockBoundaryScanner()..scan('- item\n\n  continued\n');
      // The blank is followed by an indented continuation of the item, so the
      // list stays whole (no seal).
      expect(s.boundary, 0);
    });

    test('a list DOES seal when a plain paragraph follows the blank', () {
      final s = CcBlockBoundaryScanner()..scan('- item\n\nParagraph.\n');
      expect(s.boundary, '- item\n\n'.length);
    });

    test(
      'only complete lines are consumed; scanPos advances monotonically',
      () {
        final s = CcBlockBoundaryScanner()
          ..scan('partial line without newline');
        expect(s.scanPos, 0);
        s.scan('partial line without newline\n');
        expect(s.scanPos, 'partial line without newline\n'.length);
        final before = s.scanPos;
        s.scan('partial line without newline\nnext\n');
        expect(s.scanPos, greaterThanOrEqualTo(before));
      },
    );

    test('reset clears all state', () {
      final s = CcBlockBoundaryScanner()..scan('a\n\nb\n');
      expect(s.boundary, greaterThan(0));
      s.reset();
      expect(s.boundary, 0);
      expect(s.scanPos, 0);
    });
  });
}
