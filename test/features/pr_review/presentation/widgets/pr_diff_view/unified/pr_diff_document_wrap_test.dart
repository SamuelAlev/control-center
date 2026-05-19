import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/shared/utils/diff_parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a context-only structure (no hunk headers / gaps) from raw line
/// contents, so display lines map 1:1 to structure rows.
DiffRawLines _rawFromContents(List<String> contents) {
  final n = contents.length;
  return DiffRawLines(
    kinds: List.filled(n, DiffLineKind.context.index),
    contents: contents,
    oldLines: List.generate(n, (i) => i + 1),
    newLines: List.generate(n, (i) => i + 1),
    hunkHeaders: List.filled(n, null),
    gapOldEnds: List.filled(n, null),
    gapNewEnds: List.filled(n, null),
    maxLineChars: contents.fold(0, (m, s) => s.length > m ? s.length : m),
  );
}

void main() {
  const double lineH = 18.75;
  const double headerH = 30;
  const double sep = 10; // PrDiffDocument default fileSeparator

  late PrDiffDocument doc;

  setUp(() {
    doc = PrDiffDocument(
      lineHeight: lineH,
      headerHeight: headerH,
      autoCollapseThreshold: 1 << 20,
    )..setFiles([
        PrFile(
          filename: 'a.dart',
          status: PrFileStatus.added,
          additions: 3,
          deletions: 0,
          patch: '+aaa\n+bbb\n+ccc',
        ),
      ]);
    // Widths: 10, 100, 5.
    doc.setStructure(0, _rawFromContents(['a' * 10, 'b' * 100, 'c' * 5]));
  });

  group('scroll mode (default)', () {
    test('one visual row per line; extent is width-independent', () {
      expect(doc.totalExtent, closeTo(headerH + 3 * lineH + sep, 0.001));
      expect(doc.visualRowsOf(0, 1), 1);
      expect(doc.offsetOfLine(0, 2), closeTo(headerH + 2 * lineH, 0.001));
      expect(doc.lineAtFileLocalY(0, headerH + 2 * lineH + 1), 2);
      expect(doc.maxDisplayColsOfExpanded(), 100);
    });
  });

  group('wrap mode', () {
    test('lines occupy ceil(width / colsPerRow) visual rows', () {
      expect(doc.setLayoutMode(DiffOverflowMode.wrap, 40), isTrue);
      // 10->1, 100->3, 5->1 == 5 total visual rows.
      expect(doc.visualRowsOf(0, 0), 1);
      expect(doc.visualRowsOf(0, 1), 3);
      expect(doc.visualRowsOf(0, 2), 1);
      expect(doc.totalExtent, closeTo(headerH + 5 * lineH + sep, 0.001));
    });

    test('offsetOfLine accounts for wrapped rows above', () {
      doc.setLayoutMode(DiffOverflowMode.wrap, 40);
      expect(doc.offsetOfLine(0, 1), closeTo(headerH + 1 * lineH, 0.001));
      expect(doc.offsetOfLine(0, 2), closeTo(headerH + 4 * lineH, 0.001));
    });

    test('lineAtFileLocalY inverts across every sub-row of a wrapped line', () {
      doc.setLayoutMode(DiffOverflowMode.wrap, 40);
      expect(doc.lineAtFileLocalY(0, headerH + 0 * lineH + 1), 0);
      // Line 1 spans visual rows 1, 2 and 3.
      expect(doc.lineAtFileLocalY(0, headerH + 1 * lineH + 1), 1);
      expect(doc.lineAtFileLocalY(0, headerH + 3 * lineH + 1), 1);
      expect(doc.lineAtFileLocalY(0, headerH + 4 * lineH + 1), 2);
    });

    test('toggling back to scroll restores the single-row layout', () {
      doc.setLayoutMode(DiffOverflowMode.wrap, 40);
      expect(doc.setLayoutMode(DiffOverflowMode.scroll, 1 << 30), isTrue);
      expect(doc.visualRowsOf(0, 1), 1);
      expect(doc.totalExtent, closeTo(headerH + 3 * lineH + sep, 0.001));
    });

    test('setLayoutMode is a no-op when nothing changed', () {
      doc.setLayoutMode(DiffOverflowMode.wrap, 40);
      expect(doc.setLayoutMode(DiffOverflowMode.wrap, 40), isFalse);
    });
  });
}
