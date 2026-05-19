import 'package:control_center/shared/widgets/transcript/util/line_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeLineDiff', () {
    test('identical text yields all context, 0/0', () {
      final r = computeLineDiff('a\nb\nc', 'a\nb\nc');
      expect(r.additions, 0);
      expect(r.deletions, 0);
      expect(r.lines.every((l) => l.kind == DiffLineKind.context), isTrue);
    });

    test('pure insertion', () {
      final r = computeLineDiff('a\nc', 'a\nb\nc');
      expect(r.additions, 1);
      expect(r.deletions, 0);
      expect(
        r.lines.firstWhere((l) => l.kind == DiffLineKind.add).text,
        'b',
      );
    });

    test('pure deletion', () {
      final r = computeLineDiff('a\nb\nc', 'a\nc');
      expect(r.additions, 0);
      expect(r.deletions, 1);
      expect(
        r.lines.firstWhere((l) => l.kind == DiffLineKind.del).text,
        'b',
      );
    });

    test('modification counts as one add and one delete', () {
      final r = computeLineDiff('hello\nworld', 'hello\nthere');
      expect(r.additions, 1);
      expect(r.deletions, 1);
    });

    test('handles duplicate lines via line-mode encoding', () {
      final r = computeLineDiff('x\nx\nx', 'x\nx\nx\nx');
      expect(r.additions, 1);
      expect(r.deletions, 0);
    });

    test('empty old (full insert)', () {
      final r = computeLineDiff('', 'a\nb');
      expect(r.additions, 2);
      expect(r.deletions, 0);
    });

    test('empty new (full delete)', () {
      final r = computeLineDiff('a\nb', '');
      expect(r.additions, 0);
      expect(r.deletions, 2);
    });
  });
}
