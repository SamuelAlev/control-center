import 'dart:io';

import 'package:cc_domain/features/dispatch/domain/edit/hashline.dart';
import 'package:cc_infra/src/edit/file_edit_service.dart';
import 'package:cc_infra/src/edit/tree_sitter_block_resolver.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FileEditService', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('file_edit_service_test');
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    String pathFor(String name) => p.join(root.path, name);

    File write(String name, String content) {
      final file = File(pathFor(name))..parent.createSync(recursive: true);
      file.writeAsStringSync(content);
      return file;
    }

    test('happy path: applies an edit and updates the file', () async {
      const live = 'a\nb\nc';
      final file = write('f.dart', live);
      final service = FileEditService();

      final section = Section(
        path: file.path,
        fileHash: service.computeHashFor(live),
        edits: const [InsertEdit(cursor: BeforeAnchorCursor(2), text: 'X')],
      );

      final result = await service.apply(Patch(sections: [section]));

      expect(result.applied, isTrue);
      expect(result.failures, isEmpty);
      expect(file.readAsStringSync(), 'a\nX\nb\nc');
      final change = result.changes.single;
      expect(change.path, file.path);
      expect(change.firstChangedLine, 2);
    });

    test('stale rejection: no snapshot for the anchored hash leaves the file '
        'untouched', () async {
      const onDisk = 'a\nb\nc\nd';
      final file = write('f.dart', onDisk);
      final service = FileEditService();

      // Anchor to an OLD hash that no snapshot was ever recorded for.
      final section = Section(
        path: file.path,
        fileHash: service.computeHashFor('a\nb\nc'),
        edits: const [DeleteEdit(line: 1)],
      );

      final result = await service.apply(Patch(sections: [section]));

      expect(result.applied, isFalse);
      // File is untouched.
      expect(file.readAsStringSync(), onDisk);
      final failure = result.failures.single;
      expect(failure.path, file.path);
      expect(failure.expectedHash, service.computeHashFor('a\nb\nc'));
      expect(failure.actualHash, service.computeHashFor(onDisk));
      expect(failure.hashRecognized, isFalse);
      expect(result.summary, contains('no files were written'));
    });

    test('3-way merge recovery: file drifts on disk, edit anchored to the '
        'recorded snapshot recovers both', () async {
      // v1 is the version the agent read; the edit targets line 3 ("target").
      const v1 = 'h1\nh2\ntarget\nf1\nf2';
      // The file drifts on disk: an UNRELATED header line is prepended.
      const v2 = 'HEADER\nh1\nh2\ntarget\nf1\nf2';
      final file = write('f.dart', v2);

      final service = FileEditService()..recordSnapshot(file.path, v1);

      final section = Section(
        path: file.path,
        // Anchored to v1's hash (stale relative to the drifted v2 on disk).
        fileHash: service.computeHashFor(v1),
        edits: const [
          ReplaceEdit(startLine: 3, endLine: 3, lines: ['CHANGED']),
        ],
      );

      final result = await service.apply(Patch(sections: [section]));

      expect(result.applied, isTrue);
      // Both the drift (HEADER) and the edit (CHANGED) are present.
      expect(file.readAsStringSync(), 'HEADER\nh1\nh2\nCHANGED\nf1\nf2');
      // Recovery emits a warning.
      expect(result.changes.single.warnings, isNotEmpty);
    });

    test('atomic multi-section: one unrecoverable section writes neither file',
        () async {
      const fileAContent = 'a\nb\nc';
      const fileBOnDisk = 'completely\ndifferent\nfile';
      final fileA = write('a.dart', fileAContent);
      final fileB = write('b.dart', fileBOnDisk);

      final service = FileEditService()
        // Record a snapshot for B that does NOT three-way-merge onto its
        // drifted on-disk content, so recovery fails.
        ..recordSnapshot(fileB.path, 'x\nTARGET\ny');

      final patch = Patch(
        sections: [
          // Section 1 is perfectly valid.
          Section(
            path: fileA.path,
            fileHash: service.computeHashFor(fileAContent),
            edits: const [DeleteEdit(line: 1)],
          ),
          // Section 2 is stale and unrecoverable.
          Section(
            path: fileB.path,
            fileHash: service.computeHashFor('x\nTARGET\ny'),
            edits: const [
              ReplaceEdit(startLine: 2, endLine: 2, lines: ['NEW']),
            ],
          ),
        ],
      );

      final result = await service.apply(patch);

      expect(result.applied, isFalse);
      // NEITHER file was written.
      expect(fileA.readAsStringSync(), fileAContent);
      expect(fileB.readAsStringSync(), fileBOnDisk);
      // The valid section was held back; the invalid one is reported.
      expect(result.heldBack, contains(fileA.path));
      expect(result.failures.single.path, fileB.path);
      expect(result.failures.single.hashRecognized, isTrue);
    });

    test('missing file is treated as empty and can be created', () async {
      final service = FileEditService();
      final target = pathFor('nested/new.dart');

      final section = Section(
        path: target,
        fileHash: service.computeHashFor(''),
        edits: const [InsertEdit(cursor: BeginningOfFileCursor(), text: 'x')],
      );

      final result = await service.apply(Patch(sections: [section]));

      expect(result.applied, isTrue);
      expect(File(target).readAsStringSync(), 'x');
    });

    test('live read seeds the cache for follow-up recovery', () async {
      const v1 = 'one\ntwo\nthree';
      final file = write('f.dart', v1);
      final service = FileEditService();

      // First apply reads the live file, seeding the cache with v1.
      final firstSection = Section(
        path: file.path,
        fileHash: service.computeHashFor(v1),
        edits: const [InsertEdit(cursor: EndOfFileCursor(), text: 'four')],
      );
      final first = await service.apply(Patch(sections: [firstSection]));
      expect(first.applied, isTrue);
      const afterFirst = 'one\ntwo\nthree\nfour';
      expect(file.readAsStringSync(), afterFirst);

      // The successful write updates the cache to the new content, so an edit
      // anchored to it applies verbatim.
      final secondSection = Section(
        path: file.path,
        fileHash: service.computeHashFor(afterFirst),
        edits: const [DeleteEdit(line: 1)],
      );
      final second = await service.apply(Patch(sections: [secondSection]));
      expect(second.applied, isTrue);
      expect(file.readAsStringSync(), 'two\nthree\nfour');
    });

    test('textForHash returns cached text only when the hash matches', () {
      final service = FileEditService()..recordSnapshot('/x.dart', 'hello');
      final hash = service.computeHashFor('hello');
      expect(service.textForHash('/x.dart', hash), 'hello');
      expect(service.textForHash('/x.dart', '0000'), isNull);
      expect(service.textForHash('/missing.dart', hash), isNull);
    });
  });

  group('TreeSitterBlockResolver', () {
    test('returns null gracefully when the loader is unavailable', () {
      // A loader pointed at bogus paths never reports availability.
      final loader = TreeSitterLoader(
        runtimePath: '/nonexistent/libtree-sitter.dylib',
        grammarPaths: const {
          'dart': '/nonexistent/libtree-sitter-dart.dylib',
        },
      );
      expect(loader.isAvailable, isFalse);

      final resolver = TreeSitterBlockResolver(
        parser: TreeSitterParser(loader),
        loader: loader,
      );

      final span = resolver.resolveBlock(
        path: 'f.dart',
        text: 'void main() {\n  print(1);\n}\n',
        line: 1,
      );
      expect(span, isNull);
    });

    test('returns null for an unrecognized extension', () {
      final loader = TreeSitterLoader(
        runtimePath: '/nonexistent/libtree-sitter.dylib',
      );
      final resolver = TreeSitterBlockResolver(
        parser: TreeSitterParser(loader),
        loader: loader,
      );

      final span = resolver.resolveBlock(
        path: 'notes.txt',
        text: 'just some text',
        line: 1,
      );
      expect(span, isNull);
    });
  });
}
