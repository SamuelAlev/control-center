import 'package:cc_domain/features/dispatch/domain/edit/block_resolver.dart';
import 'package:cc_domain/features/dispatch/domain/edit/content_hash.dart';
import 'package:cc_domain/features/dispatch/domain/edit/edit.dart';
import 'package:cc_domain/features/dispatch/domain/edit/patcher.dart';
import 'package:test/test.dart';

/// A hand-written [SnapshotStore] backed by a `{path: {hash: text}}` map.
class FakeSnapshotStore implements SnapshotStore {
  final Map<String, Map<String, String>> _byPath = {};

  /// Record [text] for [path] keyed by its content hash.
  void record(String path, String text) {
    final normalized = normalizeContent(text);
    (_byPath[path] ??= {})[computeContentHash(normalized)] = normalized;
  }

  @override
  String? textForHash(String path, String fourHexHash) =>
      _byPath[path]?[fourHexHash];
}

/// A resolver that always returns the configured span.
class FixedBlockResolver implements BlockResolver {
  FixedBlockResolver(this.span);
  final BlockSpan span;

  @override
  BlockSpan? resolveBlock({
    required String path,
    required String text,
    required int line,
  }) =>
      span;
}

/// Builds a `readLive` callback from a `{path: content}` map.
Future<String?> Function(String) readerFor(Map<String, String> files) =>
    (path) async => files[path];

void main() {
  group('Patcher.apply — happy path', () {
    test('single section applies and reports the new content', () async {
      const live = 'a\nb\nc';
      final section = Section(
        path: 'f.dart',
        fileHash: computeContentHash(live),
        edits: const [InsertEdit(cursor: BeforeAnchorCursor(2), text: 'X')],
      );

      const patcher = Patcher();
      final result = await patcher.apply(
        Patch(sections: [section]),
        readLive: readerFor({'f.dart': live}),
      );

      expect(result.allApplied, isTrue);
      final prepared = result.sections.single;
      expect(prepared.isApplied, isTrue);
      expect(prepared.newContent, 'a\nX\nb\nc');
      expect(prepared.firstChangedLine, 2);
      expect(prepared.fileHash, computeContentHash('a\nX\nb\nc'));
      expect(prepared.isNoop, isFalse);
    });

    test('multi-section preflight applies every section', () async {
      const fileA = 'a\nb\nc';
      const fileB = 'x\ny\nz';
      final patch = Patch(
        sections: [
          Section(
            path: 'a.dart',
            fileHash: computeContentHash(fileA),
            edits: const [DeleteEdit(line: 1)],
          ),
          Section(
            path: 'b.dart',
            fileHash: computeContentHash(fileB),
            edits: const [InsertEdit(cursor: EndOfFileCursor(), text: 'w')],
          ),
        ],
      );

      const patcher = Patcher();
      final result = await patcher.apply(
        patch,
        readLive: readerFor({'a.dart': fileA, 'b.dart': fileB}),
      );

      expect(result.allApplied, isTrue);
      expect(result.sections[0].newContent, 'b\nc');
      expect(result.sections[1].newContent, 'x\ny\nz\nw');
    });

    test('detects a noop apply', () async {
      const live = 'a\nb';
      // An empty edit list is the simplest no-op: nothing changes.
      final section = Section(
        path: 'f.dart',
        fileHash: computeContentHash(live),
        edits: const [],
      );

      const patcher = Patcher();
      final result = await patcher.apply(
        Patch(sections: [section]),
        readLive: readerFor({'f.dart': live}),
      );
      expect(result.sections.single.isNoop, isTrue);
      expect(result.sections.single.newContent, live);
    });
  });

  group('Patcher.apply — hash mismatch', () {
    test('rejects with a recognized-hash mismatch when no snapshot', () async {
      const live = 'a\nb\nc';
      const section = Section(
        path: 'f.dart',
        fileHash: 'dead', // not the live hash, never recorded
        edits: [DeleteEdit(line: 1)],
      );

      const patcher = Patcher();
      final result = await patcher.apply(
        const Patch(sections: [section]),
        readLive: readerFor({'f.dart': live}),
      );

      expect(result.allApplied, isFalse);
      final prepared = result.sections.single;
      expect(prepared.isApplied, isFalse);
      expect(prepared.error, isNotNull);
      expect(prepared.error!.expectedFileHash, 'dead');
      expect(prepared.error!.actualFileHash, computeContentHash(live));
      // No snapshot was ever recorded for 'dead'.
      expect(prepared.error!.hashRecognized, isFalse);
    });

    test('recovers via snapshot when the file drifted', () async {
      const snapshot = 'h1\nh2\ntarget\nf1\nf2';
      const live = 'HEADER\nh1\nh2\ntarget\nf1\nf2';
      final store = FakeSnapshotStore()..record('f.dart', snapshot);

      final section = Section(
        path: 'f.dart',
        // Anchor to the snapshot's hash (stale relative to live).
        fileHash: computeContentHash(snapshot),
        edits: const [
          ReplaceEdit(startLine: 3, endLine: 3, lines: ['CHANGED']),
        ],
      );

      final patcher = Patcher(snapshots: store);
      final result = await patcher.apply(
        Patch(sections: [section]),
        readLive: readerFor({'f.dart': live}),
      );

      expect(result.allApplied, isTrue);
      expect(result.sections.single.newContent,
          'HEADER\nh1\nh2\nCHANGED\nf1\nf2');
    });

    test('unrecoverable drift surfaces a recognized-hash mismatch', () async {
      const snapshot = 'x\nTARGET\ny';
      const live = 'completely\ndifferent\nfile';
      final store = FakeSnapshotStore()..record('f.dart', snapshot);

      final section = Section(
        path: 'f.dart',
        fileHash: computeContentHash(snapshot),
        edits: const [
          ReplaceEdit(startLine: 2, endLine: 2, lines: ['NEW']),
        ],
      );

      final patcher = Patcher(snapshots: store);
      final result = await patcher.apply(
        Patch(sections: [section]),
        readLive: readerFor({'f.dart': live}),
      );

      expect(result.allApplied, isFalse);
      final error = result.sections.single.error!;
      // The hash was recorded (snapshot present) but recovery failed → drift.
      expect(error.hashRecognized, isTrue);
      expect(error.expectedFileHash, computeContentHash(snapshot));
    });

    test('one failed section makes the whole patch not-allApplied', () async {
      const fileA = 'a\nb\nc';
      const fileB = 'x\ny\nz';
      final patch = Patch(
        sections: [
          Section(
            path: 'a.dart',
            fileHash: computeContentHash(fileA),
            edits: const [DeleteEdit(line: 1)],
          ),
          const Section(
            path: 'b.dart',
            fileHash: 'beef', // wrong
            edits: [DeleteEdit(line: 1)],
          ),
        ],
      );

      const patcher = Patcher();
      final result = await patcher.apply(
        patch,
        readLive: readerFor({'a.dart': fileA, 'b.dart': fileB}),
      );

      expect(result.allApplied, isFalse);
      // The first section still has its preflight result for the caller.
      expect(result.sections[0].isApplied, isTrue);
      expect(result.sections[0].newContent, 'b\nc');
      expect(result.sections[1].isApplied, isFalse);
    });
  });

  group('Patcher.apply — block edits', () {
    test('replace block expands and applies via the resolver', () async {
      const live = 'fn() {\n  a\n  b\n}\ntail';
      final section = Section(
        path: 'f.dart',
        fileHash: computeContentHash(live),
        edits: const [
          BlockEdit(
            mode: BlockMode.replace,
            anchorLine: 1,
            payloads: ['fn() {', '  c', '}'],
          ),
        ],
      );

      final patcher = Patcher(
        blockResolver: FixedBlockResolver(
          const BlockSpan(startLine: 1, endLine: 4),
        ),
      );
      final result = await patcher.apply(
        Patch(sections: [section]),
        readLive: readerFor({'f.dart': live}),
      );

      expect(result.allApplied, isTrue);
      expect(result.sections.single.newContent, 'fn() {\n  c\n}\ntail');
    });

    test('replace block with no resolver fails the section', () async {
      const live = 'fn() {\n  a\n}\ntail';
      final section = Section(
        path: 'f.dart',
        fileHash: computeContentHash(live),
        edits: const [
          BlockEdit(mode: BlockMode.replace, anchorLine: 1, payloads: ['x']),
        ],
      );

      const patcher = Patcher();
      final result = await patcher.apply(
        Patch(sections: [section]),
        readLive: readerFor({'f.dart': live}),
      );

      expect(result.allApplied, isFalse);
      expect(result.sections.single.error, isNotNull);
    });
  });

  group('Patcher.apply — structural errors', () {
    test('duplicate section paths throw PatchStructureException', () async {
      const patch = Patch(
        sections: [
          Section(path: 'dup.dart', fileHash: 'aaaa', edits: []),
          Section(path: 'dup.dart', fileHash: 'bbbb', edits: []),
        ],
      );
      const patcher = Patcher();
      expect(
        () => patcher.apply(patch, readLive: readerFor({'dup.dart': ''})),
        throwsA(isA<PatchStructureException>()),
      );
    });

    test('a missing live file is treated as empty content', () async {
      // readLive returns null → normalized to '' → hash of empty file.
      final section = Section(
        path: 'missing.dart',
        fileHash: computeContentHash(''),
        edits: const [InsertEdit(cursor: BeginningOfFileCursor(), text: 'x')],
      );
      const patcher = Patcher();
      final result = await patcher.apply(
        Patch(sections: [section]),
        readLive: (_) async => null,
      );
      expect(result.allApplied, isTrue);
      expect(result.sections.single.newContent, 'x');
    });
  });
}
