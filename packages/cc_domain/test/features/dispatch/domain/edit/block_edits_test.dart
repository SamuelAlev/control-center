import 'package:cc_domain/features/dispatch/domain/edit/apply_edits.dart';
import 'package:cc_domain/features/dispatch/domain/edit/block_resolver.dart';
import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';
import 'package:test/test.dart';

/// A hand-written [BlockResolver] returning a fixed span (or null) regardless
/// of input, for deterministic block-expansion tests.
class FakeBlockResolver implements BlockResolver {
  FakeBlockResolver(this._span);
  final BlockSpan? _span;

  int calls = 0;

  @override
  BlockSpan? resolveBlock({
    required String path,
    required String text,
    required int line,
  }) {
    calls++;
    return _span;
  }
}

void main() {
  const file = 'fn() {\n  a\n  b\n}\ntail';

  group('resolveBlockEdits — fast path', () {
    test('returns the input unchanged when there is no block edit', () {
      final edits = [const DeleteEdit(line: 1)];
      final result = resolveBlockEdits(edits, file, 'a.dart', null);
      expect(result.edits, same(edits));
      expect(result.warnings, isEmpty);
    });
  });

  group('resolveBlockEdits — no resolver / unresolved', () {
    test('insertAfter on a closer line lowers with closer warning', () {
      final edits = [
        const BlockEdit(
          mode: BlockMode.insertAfter,
          anchorLine: 4, // '}' is a structural closer
          payloads: ['  after'],
        ),
      ];
      final result = resolveBlockEdits(edits, file, 'a.dart', null);
      expect(result.warnings, contains(insertAfterBlockCloserLoweredWarning));
      expect(result.edits, hasLength(1));
      final lowered = result.edits.single as InsertEdit;
      expect(lowered.cursor, const AfterAnchorCursor(4));
      expect(lowered.text, '  after');
    });

    test('insertAfter on a content line lowers with unresolved warning', () {
      final edits = [
        const BlockEdit(
          mode: BlockMode.insertAfter,
          anchorLine: 2, // '  a' is content
          payloads: ['  after'],
        ),
      ];
      final result = resolveBlockEdits(edits, file, 'a.dart', null);
      expect(
        result.warnings,
        contains(insertAfterBlockUnresolvedLoweredWarning),
      );
      final lowered = result.edits.single as InsertEdit;
      expect(lowered.cursor, const AfterAnchorCursor(2));
    });

    test('replace block without a resolver throws', () {
      final edits = [
        const BlockEdit(
          mode: BlockMode.replace,
          anchorLine: 1,
          payloads: ['x'],
        ),
      ];
      expect(
        () => resolveBlockEdits(edits, file, 'a.dart', null),
        throwsA(isA<BlockResolutionException>()),
      );
    });

    test('delete block without a resolver throws', () {
      final edits = [
        const BlockEdit(mode: BlockMode.delete, anchorLine: 1),
      ];
      expect(
        () => resolveBlockEdits(edits, file, 'a.dart', null),
        throwsA(isA<BlockResolutionException>()),
      );
    });
  });

  group('resolveBlockEdits — single-line span', () {
    test('replace on a single-line span throws', () {
      final resolver = FakeBlockResolver(
        const BlockSpan(startLine: 2, endLine: 2),
      );
      final edits = [
        const BlockEdit(
          mode: BlockMode.replace,
          anchorLine: 2,
          payloads: ['x'],
        ),
      ];
      expect(
        () => resolveBlockEdits(edits, file, 'a.dart', resolver),
        throwsA(isA<BlockResolutionException>()),
      );
    });

    test('insertAfter on a single-line span lowers to after that line', () {
      final resolver = FakeBlockResolver(
        const BlockSpan(startLine: 2, endLine: 2),
      );
      final edits = [
        const BlockEdit(
          mode: BlockMode.insertAfter,
          anchorLine: 2,
          payloads: ['  inserted'],
        ),
      ];
      final result = resolveBlockEdits(edits, file, 'a.dart', resolver);
      expect(result.warnings, isEmpty);
      final lowered = result.edits.single as InsertEdit;
      expect(lowered.cursor, const AfterAnchorCursor(2));
    });
  });

  group('resolveBlockEdits — multi-line span', () {
    test('replace expands to replacement inserts + range deletes', () {
      // Resolve the block at line 1 to span lines 1..4 ('fn() {' .. '}').
      final resolver = FakeBlockResolver(
        const BlockSpan(startLine: 1, endLine: 4),
      );
      final edits = [
        const BlockEdit(
          mode: BlockMode.replace,
          anchorLine: 1,
          payloads: ['replaced() {', '  body', '}'],
        ),
      ];
      final result = resolveBlockEdits(edits, file, 'a.dart', resolver);
      // 3 replacement inserts + 4 deletes.
      final inserts = result.edits.whereType<InsertEdit>().toList();
      final deletes = result.edits.whereType<DeleteEdit>().toList();
      expect(inserts, hasLength(3));
      expect(deletes, hasLength(4));
      expect(deletes.map((d) => d.line), [1, 2, 3, 4]);
      expect(
        inserts.every(
          (e) =>
              e.mode == InsertMode.replacement &&
              e.cursor == const BeforeAnchorCursor(1),
        ),
        isTrue,
      );

      // End to end: replacing the whole block leaves the tail.
      final applied = applyEdits(file, result.edits);
      expect(applied.text, 'replaced() {\n  body\n}\ntail');
    });

    test('delete expands to a pure range deletion', () {
      final resolver = FakeBlockResolver(
        const BlockSpan(startLine: 1, endLine: 4),
      );
      final edits = [
        const BlockEdit(mode: BlockMode.delete, anchorLine: 1),
      ];
      final result = resolveBlockEdits(edits, file, 'a.dart', resolver);
      expect(result.edits.whereType<InsertEdit>(), isEmpty);
      expect(
        result.edits.whereType<DeleteEdit>().map((d) => d.line),
        [1, 2, 3, 4],
      );
      final applied = applyEdits(file, result.edits);
      expect(applied.text, 'tail');
    });

    test('insertAfter expands to after-anchor inserts at the block end', () {
      final resolver = FakeBlockResolver(
        const BlockSpan(startLine: 1, endLine: 4),
      );
      final edits = [
        const BlockEdit(
          mode: BlockMode.insertAfter,
          anchorLine: 1,
          payloads: ['x', 'y'],
        ),
      ];
      final result = resolveBlockEdits(edits, file, 'a.dart', resolver);
      final inserts = result.edits.cast<InsertEdit>();
      expect(inserts, hasLength(2));
      expect(
        inserts.every(
          (e) => e.cursor == const AfterAnchorCursor(4) && e.blockStart == 1,
        ),
        isTrue,
      );
      final applied = applyEdits(file, result.edits);
      expect(applied.text, 'fn() {\n  a\n  b\n}\nx\ny\ntail');
    });
  });
}
