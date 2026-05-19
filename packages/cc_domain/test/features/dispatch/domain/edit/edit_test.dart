import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';
import 'package:test/test.dart';

void main() {
  group('InsertCursor', () {
    test('anchored cursors expose their line; head/tail expose null', () {
      expect(const BeforeAnchorCursor(5).anchorLine, 5);
      expect(const AfterAnchorCursor(7).anchorLine, 7);
      expect(const BeginningOfFileCursor().anchorLine, isNull);
      expect(const EndOfFileCursor().anchorLine, isNull);
    });

    test('value equality', () {
      expect(const BeforeAnchorCursor(2), const BeforeAnchorCursor(2));
      expect(const BeforeAnchorCursor(2), isNot(const BeforeAnchorCursor(3)));
      expect(const BeforeAnchorCursor(2), isNot(const AfterAnchorCursor(2)));
      expect(const BeginningOfFileCursor(), const BeginningOfFileCursor());
      expect(const EndOfFileCursor(), const EndOfFileCursor());
    });
  });

  group('Edit equality', () {
    test('InsertEdit', () {
      expect(
        const InsertEdit(cursor: BeforeAnchorCursor(1), text: 'a'),
        const InsertEdit(cursor: BeforeAnchorCursor(1), text: 'a'),
      );
      expect(
        const InsertEdit(cursor: BeforeAnchorCursor(1), text: 'a'),
        isNot(const InsertEdit(cursor: BeforeAnchorCursor(1), text: 'b')),
      );
    });

    test('DeleteEdit', () {
      expect(const DeleteEdit(line: 3), const DeleteEdit(line: 3));
      expect(const DeleteEdit(line: 3), isNot(const DeleteEdit(line: 4)));
    });

    test('ReplaceEdit compares its lines', () {
      expect(
        const ReplaceEdit(startLine: 1, endLine: 2, lines: ['a', 'b']),
        const ReplaceEdit(startLine: 1, endLine: 2, lines: ['a', 'b']),
      );
      expect(
        const ReplaceEdit(startLine: 1, endLine: 2, lines: ['a', 'b']),
        isNot(const ReplaceEdit(startLine: 1, endLine: 2, lines: ['a', 'c'])),
      );
    });

    test('BlockEdit', () {
      expect(
        const BlockEdit(mode: BlockMode.delete, anchorLine: 1),
        const BlockEdit(mode: BlockMode.delete, anchorLine: 1),
      );
      expect(
        const BlockEdit(mode: BlockMode.delete, anchorLine: 1),
        isNot(const BlockEdit(mode: BlockMode.replace, anchorLine: 1)),
      );
    });
  });

  group('lowerReplaceEdits', () {
    test('expands a ReplaceEdit to replacement inserts + range deletes', () {
      final lowered = lowerReplaceEdits([
        const ReplaceEdit(startLine: 2, endLine: 3, lines: ['x', 'y']),
      ]);
      expect(lowered, [
        const InsertEdit(
          cursor: BeforeAnchorCursor(2),
          text: 'x',
          mode: InsertMode.replacement,
        ),
        const InsertEdit(
          cursor: BeforeAnchorCursor(2),
          text: 'y',
          mode: InsertMode.replacement,
        ),
        const DeleteEdit(line: 2),
        const DeleteEdit(line: 3),
      ]);
    });

    test('passes non-replace edits through unchanged and in order', () {
      const insert = InsertEdit(cursor: AfterAnchorCursor(1), text: 'a');
      const delete = DeleteEdit(line: 5);
      final lowered = lowerReplaceEdits([insert, delete]);
      expect(lowered, [insert, delete]);
    });
  });

  group('Section.collectAnchorLines', () {
    test('gathers, de-dups, and sorts anchors across edit kinds', () {
      const section = Section(
        path: 'f.dart',
        fileHash: 'aaaa',
        edits: [
          DeleteEdit(line: 5),
          InsertEdit(cursor: BeforeAnchorCursor(2), text: 'x'),
          InsertEdit(cursor: EndOfFileCursor(), text: 'eof'), // no anchor
          ReplaceEdit(startLine: 8, endLine: 9, lines: ['a']),
          BlockEdit(mode: BlockMode.delete, anchorLine: 3),
        ],
      );
      expect(section.collectAnchorLines(), [2, 3, 5, 8, 9]);
    });

    test('head/tail-only edits contribute no anchors', () {
      const section = Section(
        path: 'f.dart',
        fileHash: 'aaaa',
        edits: [
          InsertEdit(cursor: BeginningOfFileCursor(), text: 'top'),
          InsertEdit(cursor: EndOfFileCursor(), text: 'bottom'),
        ],
      );
      expect(section.collectAnchorLines(), isEmpty);
    });
  });

  group('Patch / Section equality', () {
    test('structural equality', () {
      const a = Patch(
        sections: [
          Section(
            path: 'f.dart',
            fileHash: 'aaaa',
            edits: [DeleteEdit(line: 1)],
          ),
        ],
      );
      const b = Patch(
        sections: [
          Section(
            path: 'f.dart',
            fileHash: 'aaaa',
            edits: [DeleteEdit(line: 1)],
          ),
        ],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
