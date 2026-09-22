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
      expect(r.lines.firstWhere((l) => l.kind == DiffLineKind.add).text, 'b');
    });

    test('pure deletion', () {
      final r = computeLineDiff('a\nb\nc', 'a\nc');
      expect(r.additions, 0);
      expect(r.deletions, 1);
      expect(r.lines.firstWhere((l) => l.kind == DiffLineKind.del).text, 'b');
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

    test('returns the cached instance for the same text', () {
      const oldText = 'a\nb';
      const newText = 'a\nc';
      final first = computeLineDiff(oldText, newText);
      expect(identical(computeLineDiff(oldText, newText), first), isTrue);
    });
  });

  test('a one-line edit of a long file still diffs inline', () {
    final oldText = List.generate(800, (i) => 'line $i').join('\n');
    final lines = oldText.split('\n')..[10] = 'line 10 changed';
    final diff = lineDiffForBuild(oldText, lines.join('\n'));
    expect(diff, isNotNull);
    expect(diff!.additions, 1);
    expect(diff.deletions, 1);
  });

  test('a rewrite of a long file leaves the ui isolate', () async {
    final oldText = List.generate(800, (i) => 'old line $i').join('\n');
    final newText = List.generate(800, (i) => 'new line $i').join('\n');
    final before = debugLineDiffComputeCount;
    expect(lineDiffForBuild(oldText, newText), isNull);
    expect(debugLineDiffComputeCount, before);
    final diff = await computeLineDiffAsync(oldText, newText);
    expect(debugLineDiffComputeCount, before);
    expect(diff.additions, 800);
    expect(diff.deletions, 800);
    expect(lineDiffForBuild(oldText, newText)?.additions, 800);
  });
}
