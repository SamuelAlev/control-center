import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:flutter_test/flutter_test.dart';

PrFile _file(String name, String patch,
        {PrFileStatus status = PrFileStatus.modified,
        PrFileViewedState viewed = PrFileViewedState.unviewed}) =>
    PrFile(
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

PrDiffDocument _doc() => PrDiffDocument(
      lineHeight: 18,
      headerHeight: 28,
      autoCollapseThreshold: 100000,
    );

void main() {
  group('PrDiffDocument.setFiles patch-change invalidation', () {
    test(
        'drops cached structure when a surviving file gains a patch '
        '(empty tree → filled patch)', () {
      final doc = _doc();

      // 1. Tree emission: the file arrives with an empty patch.
      doc.setFiles([_file('a.dart', '')]);
      // The store parses + caches structure from the (empty) patch.
      doc.setStructure(0, buildDiffRawLines(''));
      expect(doc.structureOf(0), isNotNull);

      // 2. Patch emission: the same file now carries the real patch.
      final repatched = doc.setFiles([_file('a.dart', _realPatch)]);

      // The stale empty structure must be dropped so it re-parses, and the
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

  group('PrDiffDocument.setFiles viewed-state collapse', () {
    test('collapses a surviving file when viewerViewedState arrives later', () {
      final doc = _doc();

      // 1. The GitHub source yields the file list first, with no viewed state.
      doc.setFiles([_file('a.dart', _realPatch)]);
      expect(doc.isExpanded(0), isTrue);

      // 2. A second load enriches the same file with viewerViewedState=viewed.
      doc.setFiles([_file('a.dart', _realPatch, viewed: PrFileViewedState.viewed)]);

      // The preserved layout must fold — otherwise the header reads "viewed"
      // over an open diff.
      expect(doc.isExpanded(0), isFalse);
    });

    test('re-expands a surviving file when it becomes un-viewed', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', _realPatch, viewed: PrFileViewedState.viewed)]);
      expect(doc.isExpanded(0), isFalse);

      doc.setFiles([_file('a.dart', _realPatch)]);
      expect(doc.isExpanded(0), isTrue);
    });

    test('a file already viewed on first emission starts collapsed', () {
      final doc = _doc();
      doc.setFiles([_file('a.dart', _realPatch, viewed: PrFileViewedState.viewed)]);
      expect(doc.isExpanded(0), isFalse);
    });

    test('leaves a manual expand untouched when viewed state is unchanged', () {
      final doc = _doc();
      // Viewed (collapsed), then the user manually re-expands it.
      doc.setFiles([_file('a.dart', _realPatch, viewed: PrFileViewedState.viewed)]);
      doc.setExpanded(0, expanded: true);

      // A later load with the same viewed state must not re-collapse it.
      doc.setFiles([_file('a.dart', _realPatch, viewed: PrFileViewedState.viewed)]);
      expect(doc.isExpanded(0), isTrue);
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
      doc.setFiles(
          [_file('a.dart', _removedPatch, status: PrFileStatus.removed)]);
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
      doc.setFiles(
          [_file('a.dart', _realPatch, status: PrFileStatus.renamed)]);
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
}
