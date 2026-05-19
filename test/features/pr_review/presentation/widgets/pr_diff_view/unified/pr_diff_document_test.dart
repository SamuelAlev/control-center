import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:flutter_test/flutter_test.dart';

PrFile _file(
  String name,
  String patch, {
  PrFileStatus status = PrFileStatus.modified,
  PrFileViewedState viewed = PrFileViewedState.unviewed,
}) => PrFile(
  filename: name,
  status: status,
  additions: 1,
  deletions: 1,
  patch: patch,
  viewerViewedState: viewed,
);

const _realPatch = '@@ -1,2 +1,2 @@\n-old line\n+new line\n context\n';
const _addedPatch = '@@ -0,0 +1,2 @@\n+line one\n+line two\n';
const _removedPatch = '@@ -1,2 +0,0 @@\n-line one\n-line two\n';

PrDiffDocument _doc() => PrDiffDocument(lineHeight: 18, headerHeight: 28);

void main() {
  group('PrDiffDocument.setFiles patch-change invalidation', () {
    test('drops cached structure when a surviving file gains a patch '
        '(empty tree → filled patch)', () {
      final doc = _doc();

      // 1. Tree emission: the file arrives with an empty patch.
      doc.setFiles([_file('a.dart', '')]);
      // The store parses + caches structure from the (empty) patch.
      doc.setStructure(0, buildDiffRawLines(''));
      expect(doc.structureOf(0), isNotNull);

      // 2. Patch emission: the same file now carries the real patch.
      final repatched = doc.setFiles([_file('a.dart', _realPatch)]);

      // The stale empty structure must be dropped so it re-parses and the
      // index reported so the caller can invalidate derived caches.
      expect(repatched, [0]);
      expect(doc.structureOf(0), isNull);
    });

    test('keeps cached structure when the patch is unchanged', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', _realPatch)]);
      doc.setStructure(0, buildDiffRawLines(_realPatch));
      expect(doc.structureOf(0), isNotNull);

      final repatched = doc.setFiles([_file('a.dart', _realPatch)]);

      expect(repatched, isEmpty);
      expect(doc.structureOf(0), isNotNull);
    });

    test('preserves the user expand state across a patch change', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', '')]);
      doc.setStructure(0, buildDiffRawLines(''));
      doc.setExpanded(0, expanded: false);

      doc.setFiles([_file('a.dart', _realPatch)]);

      expect(doc.isExpanded(0), isFalse);
      expect(doc.structureOf(0), isNull);
    });

    test('reports no repatched indices for brand-new files', () {
      final doc = _doc();
      final repatched = doc.setFiles([_file('a.dart', _realPatch)]);
      expect(repatched, isEmpty);
    });
  });

  group('PrDiffDocument.setFiles viewed-state expansion', () {
    test('keeps a surviving file open when viewed state arrives later', () {
      final doc = _doc();

      // 1. The GitHub source yields the file list first, with no viewed state.
      doc.setFiles([_file('a.dart', _realPatch)]);
      expect(doc.isExpanded(0), isTrue);

      // 2. A second load enriches the same file with viewerViewedState=viewed.
      doc.setFiles([
        _file('a.dart', _realPatch, viewed: PrFileViewedState.viewed),
      ]);

      expect(doc.isExpanded(0), isTrue);
    });

    test('keeps a manual collapse when viewed state changes', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', _realPatch)]);
      doc.setExpanded(0, expanded: false);

      doc.setFiles([
        _file('a.dart', _realPatch, viewed: PrFileViewedState.viewed),
      ]);
      expect(doc.isExpanded(0), isFalse);

      doc.setFiles([_file('a.dart', _realPatch)]);
      expect(doc.isExpanded(0), isFalse);
    });

    test('a file already viewed on first emission starts expanded', () {
      final doc = _doc();
      doc.setFiles([
        _file('a.dart', _realPatch, viewed: PrFileViewedState.viewed),
      ]);
      expect(doc.isExpanded(0), isTrue);
    });
  });

  group('PrDiffDocument.setFiles initial expansion', () {
    test('files of every status start expanded', () {
      final doc = _doc();
      doc.setFiles([
        _file('gone.dart', _removedPatch, status: PrFileStatus.removed),
        _file('moved.dart', '', status: PrFileStatus.renamed),
        _file('new.dart', _addedPatch, status: PrFileStatus.added),
        _file('edited.dart', _realPatch),
        _file('same.dart', '', status: PrFileStatus.unchanged),
      ]);
      for (var i = 0; i < doc.fileCount; i++) {
        expect(doc.isExpanded(i), isTrue);
      }
    });

    test('a large file starts expanded', () {
      final doc = _doc();
      final patch = List.filled(1000, '+changed line').join('\n');
      doc.setFiles([_file('large.dart', '@@ -0,0 +1,1000 @@\n$patch')]);
      expect(doc.isExpanded(0), isTrue);
    });

    test('common dependency lockfiles start collapsed', () {
      final doc = _doc();
      const paths = [
        'pnpm-lock.yaml',
        'frontend/package-lock.json',
        'frontend/npm-shrinkwrap.json',
        'composer.lock',
        'packages/app/pubspec.lock',
        'yarn.lock',
        'Cargo.lock',
        'Gemfile.lock',
        'Podfile.lock',
        'Package.resolved',
        'packages.lock.json',
        'Pipfile.lock',
        'poetry.lock',
        'uv.lock',
        'mix.lock',
        'bun.lock',
        'bun.lockb',
      ];
      doc.setFiles([for (final path in paths) _file(path, _realPatch)]);

      for (var i = 0; i < doc.fileCount; i++) {
        expect(doc.isExpanded(i), isFalse, reason: paths[i]);
      }
    });

    test('non-lockfiles and unknown .lock files start expanded', () {
      final doc = _doc();
      const paths = [
        'package.json',
        'composer.json',
        'pubspec.yaml',
        '.dependency-cruiser-known-violations.json',
        'config/custom.lock',
      ];
      doc.setFiles([for (final path in paths) _file(path, _realPatch)]);

      for (var i = 0; i < doc.fileCount; i++) {
        expect(doc.isExpanded(i), isTrue, reason: paths[i]);
      }
    });

    test('a manual expansion of a lockfile survives a refresh', () {
      final doc = _doc();
      doc.setFiles([_file('pnpm-lock.yaml', _realPatch)]);
      expect(doc.isExpanded(0), isFalse);

      doc.setExpanded(0, expanded: true);
      doc.setFiles([_file('pnpm-lock.yaml', _realPatch)]);

      expect(doc.isExpanded(0), isTrue);
    });

    test('a manual collapse survives a refresh', () {
      final doc = _doc();
      doc.setFiles([
        _file('gone.dart', _removedPatch, status: PrFileStatus.removed),
      ]);
      doc.setExpanded(0, expanded: false);
      doc.setFiles([
        _file('gone.dart', _removedPatch, status: PrFileStatus.removed),
      ]);
      expect(doc.isExpanded(0), isFalse);
    });
  });

  group('PrDiffDocument.setFiles duplicate filenames (staged + unstaged)', () {
    // The Source control tab renders staged + unstaged as ONE list, so a
    // partially staged file legitimately appears twice with different patches
    // (index vs HEAD, then worktree vs index).
    const stagedPatch = '@@ -1,2 +1,2 @@\n-staged old\n+staged new\n context\n';
    const unstagedPatch =
        '@@ -5,2 +5,2 @@\n-worktree old\n+worktree new\n context\n';

    test(
      'a poll refresh preserves each entry\'s own structure (no aliasing)',
      () {
        final doc = _doc();
        doc.setFiles([
          _file('a.dart', stagedPatch),
          _file('a.dart', unstagedPatch),
        ]);
        doc.setStructure(0, buildDiffRawLines(stagedPatch));
        doc.setStructure(1, buildDiffRawLines(unstagedPatch));

        // The Source control tab re-fetches every few seconds; an identical
        // refresh must match prior state per occurrence, not per filename —
        // a filename-keyed match hands BOTH entries the last occurrence's
        // layout, so one patch's content renders under the other's header.
        final repatched = doc.setFiles([
          _file('a.dart', stagedPatch),
          _file('a.dart', unstagedPatch),
        ]);

        expect(repatched, isEmpty);
        expect(doc.structureOf(0)!.contents, contains('staged old'));
        expect(doc.structureOf(0)!.contents, isNot(contains('worktree old')));
        expect(doc.structureOf(1)!.contents, contains('worktree old'));
        expect(doc.structureOf(1)!.contents, isNot(contains('staged old')));
      },
    );

    test('collapsing one duplicate entry leaves the other expanded', () {
      final doc = _doc();
      doc.setFiles([
        _file('a.dart', stagedPatch),
        _file('a.dart', unstagedPatch),
      ]);
      // Poll refresh — layouts must stay distinct objects afterwards.
      doc.setFiles([
        _file('a.dart', stagedPatch),
        _file('a.dart', unstagedPatch),
      ]);

      doc.setExpanded(0, expanded: false);

      expect(doc.isExpanded(0), isFalse);
      expect(doc.isExpanded(1), isTrue);
    });

    test('a changed unstaged patch repatches only that entry', () {
      final doc = _doc();
      doc.setFiles([
        _file('a.dart', stagedPatch),
        _file('a.dart', unstagedPatch),
      ]);
      doc.setStructure(0, buildDiffRawLines(stagedPatch));
      doc.setStructure(1, buildDiffRawLines(unstagedPatch));

      // An agent edits the file: the worktree diff changes, the staged one
      // doesn't.
      const editedPatch =
          '@@ -5,2 +5,2 @@\n-worktree old\n+worktree edited\n context\n';
      final repatched = doc.setFiles([
        _file('a.dart', stagedPatch),
        _file('a.dart', editedPatch),
      ]);

      expect(repatched, [1]);
      expect(doc.structureOf(0), isNotNull);
      expect(doc.structureOf(1), isNull);
    });
  });

  group('PrDiffDocument.gutterModeOf', () {
    test('collapses an added file to the new-line column only', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', _addedPatch, status: PrFileStatus.added)]);
      doc.setStructure(0, buildDiffRawLines(_addedPatch));
      expect(doc.gutterModeOf(0), DiffGutterMode.newOnly);
    });

    test('collapses a removed file to the old-line column only', () {
      final doc = _doc();
      doc.setFiles([
        _file('a.dart', _removedPatch, status: PrFileStatus.removed),
      ]);
      doc.setStructure(0, buildDiffRawLines(_removedPatch));
      expect(doc.gutterModeOf(0), DiffGutterMode.oldOnly);
    });

    test('keeps both columns for a two-sided (modified) diff', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', _realPatch)]);
      doc.setStructure(0, buildDiffRawLines(_realPatch));
      expect(doc.gutterModeOf(0), DiffGutterMode.both);
    });

    test('keeps both columns for a rename with edits (two-sided body)', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', _realPatch, status: PrFileStatus.renamed)]);
      doc.setStructure(0, buildDiffRawLines(_realPatch));
      expect(doc.gutterModeOf(0), DiffGutterMode.both);
    });

    test('falls back to file status before the structure is parsed', () {
      final doc = _doc();
      doc.setFiles([
        _file('added.dart', _addedPatch, status: PrFileStatus.added),
        _file('removed.dart', _removedPatch, status: PrFileStatus.removed),
        _file('mod.dart', _realPatch),
      ]);
      // No setStructure yet — width must be stable from the file status alone.
      expect(doc.gutterModeOf(0), DiffGutterMode.newOnly);
      expect(doc.gutterModeOf(1), DiffGutterMode.oldOnly);
      expect(doc.gutterModeOf(2), DiffGutterMode.both);
    });

    test('re-derives the mode after a patch change drops the structure', () {
      final doc = _doc();
      // Arrives as a two-sided modified diff…
      doc.setFiles([_file('a.dart', _realPatch)]);
      doc.setStructure(0, buildDiffRawLines(_realPatch));
      expect(doc.gutterModeOf(0), DiffGutterMode.both);

      // …then the same path is re-emitted as an added file. The cached mode is
      // cleared with the structure and the status fallback takes over.
      doc.setFiles([_file('a.dart', _addedPatch, status: PrFileStatus.added)]);
      expect(doc.gutterModeOf(0), DiffGutterMode.newOnly);
      doc.setStructure(0, buildDiffRawLines(_addedPatch));
      expect(doc.gutterModeOf(0), DiffGutterMode.newOnly);
    });
  });

  group('PrDiffDocument preview', () {
    const headerHeight = 28.0; // matches _doc()
    const fileSeparator = 10.0; // matches PrDiffDocument default

    test('previewing height reserves previewHeight and ignores code rows', () {
      final doc = _doc()
        ..setFiles([
          _file('README.md', _realPatch),
          _file('b.dart', _realPatch),
        ]);
      expect(doc.isExpanded(0), isTrue);
      expect(doc.isPreviewing(0), isFalse);

      final diffHeight = doc.heightOfFile(0);
      expect(doc.offsetOfFile(1), diffHeight);

      expect(doc.setPreviewing(0, previewing: true), isTrue);
      doc.setPreviewHeight(0, 300);

      expect(doc.heightOfFile(0), headerHeight + 300 + fileSeparator);
      // The next file shifts down to sit below the preview-sized first file.
      expect(doc.offsetOfFile(1), headerHeight + 300 + fileSeparator);
    });

    test('toggling preview back restores the diff body height', () {
      final doc = _doc()
        ..setFiles([
          _file('README.md', _realPatch),
          _file('b.dart', _realPatch),
        ]);
      final diffHeight = doc.heightOfFile(0);

      doc
        ..setPreviewing(0, previewing: true)
        ..setPreviewHeight(0, 300);
      expect(doc.heightOfFile(0), isNot(diffHeight));

      expect(doc.setPreviewing(0, previewing: false), isTrue);
      expect(doc.heightOfFile(0), diffHeight);
      expect(doc.offsetOfFile(1), diffHeight);
    });

    test('setPreviewing returns false when unchanged', () {
      final doc = _doc()..setFiles([_file('README.md', _realPatch)]);
      expect(doc.setPreviewing(0, previewing: false), isFalse);
      doc.setPreviewing(0, previewing: true);
      expect(doc.setPreviewing(0, previewing: true), isFalse);
    });

    test('setPreviewHeight ignores sub-pixel changes', () {
      final doc = _doc()..setFiles([_file('README.md', _realPatch)]);
      doc
        ..setPreviewing(0, previewing: true)
        ..setPreviewHeight(0, 300);
      final h = doc.heightOfFile(0);
      doc.setPreviewHeight(0, 300.2); // below the 0.5px threshold
      expect(doc.heightOfFile(0), h);
      doc.setPreviewHeight(0, 350); // above the threshold
      expect(doc.heightOfFile(0), headerHeight + 350 + fileSeparator);
    });

    test('previewing state survives a same-filename refresh', () {
      final doc = _doc()
        ..setFiles([
          _file('README.md', _realPatch),
          _file('b.dart', _realPatch),
        ]);
      doc
        ..setPreviewing(0, previewing: true)
        ..setPreviewHeight(0, 300);

      doc.setFiles([
        _file('README.md', _realPatch),
        _file('b.dart', _realPatch),
      ]);
      expect(doc.isPreviewing(0), isTrue);
      expect(doc.heightOfFile(0), headerHeight + 300 + fileSeparator);
    });
  });
}
