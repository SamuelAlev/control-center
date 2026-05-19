import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:control_center/shared/widgets/transcript/util/split_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeSplitDiff', () {
    test('context lines occupy both sides of a row', () {
      final rows = computeSplitDiff('a\nb\n', 'a\nb\n');
      expect(rows, hasLength(2));
      for (final row in rows) {
        expect(row.left!.text, row.right!.text);
        expect(row.left!.kind, DiffLineKind.context);
        expect(row.right!.kind, DiffLineKind.context);
      }
    });

    test('pairs a replaced line into one row', () {
      final rows = computeSplitDiff('keep\nold line\n', 'keep\nnew line\n');
      expect(rows, hasLength(2));
      expect(rows[0].left!.kind, DiffLineKind.context);
      expect(rows[1].left!.text, 'old line');
      expect(rows[1].left!.kind, DiffLineKind.del);
      expect(rows[1].right!.text, 'new line');
      expect(rows[1].right!.kind, DiffLineKind.add);
    });

    test('a pure insertion gets a filler on the old side', () {
      final rows = computeSplitDiff('a\n', 'a\nb\n');
      expect(rows, hasLength(2));
      expect(rows[1].left, isNull);
      expect(rows[1].right!.text, 'b');
      expect(rows[1].right!.kind, DiffLineKind.add);
    });

    test('a pure deletion gets a filler on the new side', () {
      final rows = computeSplitDiff('a\nb\n', 'a\n');
      expect(rows, hasLength(2));
      expect(rows[1].right, isNull);
      expect(rows[1].left!.text, 'b');
      expect(rows[1].left!.kind, DiffLineKind.del);
    });

    test('an unbalanced block pairs what it can and fills the surplus', () {
      final rows = computeSplitDiff('x1\nx2\nx3\n', 'y1\n');
      // Three deletions against one addition: one paired row, two fillers.
      final changed = rows.where((r) => r.left?.kind == DiffLineKind.del);
      expect(changed, hasLength(3));
      expect(changed.where((r) => r.right != null), hasLength(1));
      expect(changed.where((r) => r.right == null), hasLength(2));
    });

    test('line indices address each side independently', () {
      // Old: a, gone, b   New: a, b, added
      final rows = computeSplitDiff('a\ngone\nb\n', 'a\nb\nadded\n');
      final lefts = rows
          .where((r) => r.left != null)
          .map((r) => r.left!.lineIndex)
          .toList();
      final rights = rows
          .where((r) => r.right != null)
          .map((r) => r.right!.lineIndex)
          .toList();
      // Each side's indices are a gap-free 0..n-1 walk of its own text.
      expect(lefts, List.generate(lefts.length, (i) => i));
      expect(rights, List.generate(rights.length, (i) => i));
    });

    test('indices resolve to the right source line on each side', () {
      const oldText = 'a\ngone\nb\n';
      const newText = 'a\nb\nadded\n';
      final oldLines = oldText.trimRight().split('\n');
      final newLines = newText.trimRight().split('\n');
      for (final row in computeSplitDiff(oldText, newText)) {
        if (row.left != null) {
          expect(oldLines[row.left!.lineIndex], row.left!.text);
        }
        if (row.right != null) {
          expect(newLines[row.right!.lineIndex], row.right!.text);
        }
      }
    });

    test('empty texts produce no rows', () {
      expect(computeSplitDiff('', ''), isEmpty);
    });
  });

  group('computeIntralineRanges', () {
    test('marks only the changed span of a paired line', () {
      const oldLine = 'child: MaterialApp(';
      const newLine = 'child: const MaterialApp(';
      final ranges = computeIntralineRanges(oldLine, newLine);
      expect(ranges.oldRanges, isEmpty);
      expect(ranges.newRanges, hasLength(1));
      final (start, end) = ranges.newRanges.single;
      expect(newLine.substring(start, end), contains('const'));
    });

    test('reports ranges on both sides of a two-way change', () {
      final ranges = computeIntralineRanges(
        'final value = oldName;',
        'final value = newName;',
      );
      expect(ranges.oldRanges, isNotEmpty);
      expect(ranges.newRanges, isNotEmpty);
      for (final (start, end) in ranges.oldRanges) {
        expect(start, lessThan(end));
        expect(end, lessThanOrEqualTo('final value = oldName;'.length));
      }
    });

    test('ranges are ascending and non-overlapping', () {
      final ranges = computeIntralineRanges(
        'a b c d e f g h',
        'a X c d Y f g Z',
      );
      var previousEnd = 0;
      for (final (start, end) in ranges.newRanges) {
        expect(start, greaterThanOrEqualTo(previousEnd));
        previousEnd = end;
      }
    });

    test('identical lines have no changed ranges', () {
      final ranges = computeIntralineRanges('same', 'same');
      expect(ranges.oldRanges, isEmpty);
      expect(ranges.newRanges, isEmpty);
    });

    test('wholly dissimilar lines fall back to whole-line highlighting', () {
      final ranges = computeIntralineRanges(
        'aaaaaaaaaaaaaaaaaaaa',
        'zzzzzzzzzzzzzzzzzzzz',
      );
      expect(ranges.oldRanges, isEmpty);
      expect(ranges.newRanges, isEmpty);
    });

    test('very long lines skip the character diff', () {
      final long = 'x' * 3000;
      final ranges = computeIntralineRanges(long, '${long}y');
      expect(ranges.oldRanges, isEmpty);
      expect(ranges.newRanges, isEmpty);
    });
  });
}
