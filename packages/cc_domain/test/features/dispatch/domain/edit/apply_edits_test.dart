import 'package:cc_domain/features/dispatch/domain/edit/apply_edits.dart';
import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';
import 'package:test/test.dart';

void main() {
  group('applyEdits — empty', () {
    test('no edits is a no-op with null firstChangedLine', () {
      final result = applyEdits('a\nb\nc', const []);
      expect(result.text, 'a\nb\nc');
      expect(result.firstChangedLine, isNull);
    });
  });

  group('applyEdits — insert', () {
    test('before-anchor insert', () {
      final result = applyEdits('a\nb\nc', [
        const InsertEdit(cursor: BeforeAnchorCursor(2), text: 'X'),
      ]);
      expect(result.text, 'a\nX\nb\nc');
      expect(result.firstChangedLine, 2);
    });

    test('after-anchor insert', () {
      final result = applyEdits('a\nb\nc', [
        const InsertEdit(cursor: AfterAnchorCursor(2), text: 'X'),
      ]);
      expect(result.text, 'a\nb\nX\nc');
      expect(result.firstChangedLine, 2);
    });

    test('beginning-of-file insert prepends', () {
      final result = applyEdits('a\nb', [
        const InsertEdit(cursor: BeginningOfFileCursor(), text: 'top'),
      ]);
      expect(result.text, 'top\na\nb');
      expect(result.firstChangedLine, 1);
    });

    test('end-of-file insert appends', () {
      final result = applyEdits('a\nb', [
        const InsertEdit(cursor: EndOfFileCursor(), text: 'bottom'),
      ]);
      expect(result.text, 'a\nb\nbottom');
      expect(result.firstChangedLine, 3);
    });

    test('end-of-file insert preserves a trailing newline', () {
      final result = applyEdits('a\nb\n', [
        const InsertEdit(cursor: EndOfFileCursor(), text: 'c'),
      ]);
      // Trailing "" sentinel stays last so the final newline survives.
      expect(result.text, 'a\nb\nc\n');
    });

    test('beginning-of-file insert into a blank file', () {
      final result = applyEdits('', [
        const InsertEdit(cursor: BeginningOfFileCursor(), text: 'only'),
      ]);
      expect(result.text, 'only');
    });
  });

  group('applyEdits — delete', () {
    test('deletes a single line', () {
      final result = applyEdits('a\nb\nc', [const DeleteEdit(line: 2)]);
      expect(result.text, 'a\nc');
      expect(result.firstChangedLine, 2);
    });

    test('deletes multiple lines bottom-up', () {
      final result = applyEdits('a\nb\nc\nd', [
        const DeleteEdit(line: 1),
        const DeleteEdit(line: 3),
      ]);
      expect(result.text, 'b\nd');
      expect(result.firstChangedLine, 1);
    });
  });

  group('applyEdits — replace (lowered)', () {
    test('single-line replace with multiple replacement lines', () {
      final lowered = lowerReplaceEdits([
        const ReplaceEdit(startLine: 2, endLine: 2, lines: ['Y', 'Z']),
      ]);
      final result = applyEdits('a\nb\nc', lowered);
      expect(result.text, 'a\nY\nZ\nc');
      expect(result.firstChangedLine, 2);
    });

    test('multi-line replace collapses a range to one line', () {
      final lowered = lowerReplaceEdits([
        const ReplaceEdit(startLine: 2, endLine: 3, lines: ['merged']),
      ]);
      final result = applyEdits('a\nb\nc\nd', lowered);
      expect(result.text, 'a\nmerged\nd');
      expect(result.firstChangedLine, 2);
    });

    test('raw ReplaceEdit reaching applyEdits throws', () {
      expect(
        () => applyEdits('a\nb', [
          const ReplaceEdit(startLine: 1, endLine: 1, lines: ['x']),
        ]),
        throwsArgumentError,
      );
    });
  });

  group('applyEdits — bottom-up ordering', () {
    test('mixed edits at different lines stay aligned', () {
      // Insert at line 1 and delete line 3 of a 3-line file; processing the
      // delete (line 3) before the insert (line 1) keeps indices valid.
      final result = applyEdits('a\nb\nc', [
        const InsertEdit(cursor: BeforeAnchorCursor(1), text: 'top'),
        const DeleteEdit(line: 3),
      ]);
      expect(result.text, 'top\na\nb');
      expect(result.firstChangedLine, 1);
    });

    test('within one line, original patch order is preserved', () {
      final result = applyEdits('a\nb\nc', [
        const InsertEdit(cursor: BeforeAnchorCursor(2), text: 'first'),
        const InsertEdit(cursor: BeforeAnchorCursor(2), text: 'second'),
      ]);
      expect(result.text, 'a\nfirst\nsecond\nb\nc');
    });

    test('before + after inserts on the same line bracket the line', () {
      final result = applyEdits('a\nb\nc', [
        const InsertEdit(cursor: BeforeAnchorCursor(2), text: 'pre'),
        const InsertEdit(cursor: AfterAnchorCursor(2), text: 'post'),
      ]);
      expect(result.text, 'a\npre\nb\npost\nc');
    });
  });

  group('applyEdits — bounds', () {
    test('out-of-range anchor throws RangeError', () {
      expect(
        () => applyEdits('a\nb', [const DeleteEdit(line: 9)]),
        throwsRangeError,
      );
    });
  });

  group('repairReplacementBoundaries', () {
    test('drops a trailing payload line duplicating the line below the range',
        () {
      // File: function header, body, closer. The model replaces lines 1-2 but
      // its payload also restates the closer on line 3 (the duplicate below).
      final fileLines = ['fn() {', '  old', '}'];
      final edits = lowerReplaceEdits([
        const ReplaceEdit(startLine: 1, endLine: 2, lines: ['fn() {', '  new', '}']),
      ]);
      final result = repairReplacementBoundaries(edits, fileLines);
      expect(result.warnings, contains(replacementBoundaryRepairWarning));

      // Applying the repaired edits leaves a single closer, not two.
      final applied = applyEdits(fileLines.join('\n'), result.edits);
      expect(applied.text, 'fn() {\n  new\n}');
    });

    test('leaves a non-duplicating replacement untouched', () {
      final fileLines = ['a', 'b', 'c'];
      final edits = lowerReplaceEdits([
        const ReplaceEdit(startLine: 2, endLine: 2, lines: ['B']),
      ]);
      final result = repairReplacementBoundaries(edits, fileLines);
      expect(result.warnings, isEmpty);
      expect(result.edits.length, edits.length);
    });
  });

  group('repairAfterInsertLandings', () {
    test('warns when an after-insert lands on a structural closer', () {
      final fileLines = ['fn() {', '  body', '}'];
      final edits = [
        const InsertEdit(cursor: AfterAnchorCursor(3), text: '  extra'),
      ];
      final result = repairAfterInsertLandings(edits, fileLines);
      expect(result.warnings, contains(afterInsertLandingSuspectWarning));
      // Edit list is left unchanged (conservative).
      expect(result.edits, same(edits));
    });

    test('no warning when the after-insert lands on content', () {
      final fileLines = ['fn() {', '  body', '}'];
      final edits = [
        const InsertEdit(cursor: AfterAnchorCursor(2), text: '  more'),
      ];
      final result = repairAfterInsertLandings(edits, fileLines);
      expect(result.warnings, isEmpty);
    });
  });
}
