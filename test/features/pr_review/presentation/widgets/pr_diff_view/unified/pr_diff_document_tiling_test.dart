import 'dart:ui' show Canvas, PictureRecorder;

import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';

import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_row_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const double _lineH = 18.75;
const double _headerH = 30;

/// A PHP-shaped new file: content lines separated by BLANK lines, which is
/// where the reported row gaps showed up.
const _phpPatch =
    '@@ -0,0 +1,7 @@\n'
    '+<?php\n'
    '+\n'
    '+/* (c) Copyright */\n'
    '+\n'
    '+namespace ControlCenter\\Endpoint;\n'
    '+\n'
    '+final class BrandCheckerEndpoint extends Endpoint';

PrDiffDocument _doc({String patch = _phpPatch}) =>
    PrDiffDocument(lineHeight: _lineH, headerHeight: _headerH)..setFiles([
      PrFile(
        filename: 'a.php',
        status: PrFileStatus.added,
        additions: 7,
        deletions: 0,
        patch: patch,
      ),
    ]);

void main() {
  group('code rows tile without gaps', () {
    for (final mode in DiffOverflowMode.values) {
      test('every row starts exactly where the previous one ends — $mode', () {
        final doc = _doc()..setLayoutMode(mode, 120);
        doc.setStructure(0, buildDiffRawLines(doc.files[0].patch));
        final count = doc.lineCountOf(0);
        expect(count, greaterThan(3));

        for (var d = 0; d < count - 1; d++) {
          final top = doc.offsetOfLine(0, d);
          final next = doc.offsetOfLine(0, d + 1);
          // The painter fills `visualRowsOf * lineHeight` from `offsetOfLine`.
          // Any disagreement here is an unpainted horizontal band — the "weird
          // row gap" — and a blank line is the case that exposes it, because
          // its width is 0 and the wrap math has to special-case that.
          expect(
            next - top,
            closeTo(doc.visualRowsOf(0, d) * _lineH, 0.001),
            reason: 'row $d leaves a gap before row ${d + 1}',
          );
        }
      });

      test('a blank line is a full row, not a collapsed one — $mode', () {
        final doc = _doc()..setLayoutMode(mode, 120);
        doc.setStructure(0, buildDiffRawLines(doc.files[0].patch));

        // Display lines 1, 3 and 5 are the blank ones.
        for (final blank in const [1, 3, 5]) {
          expect(
            doc.visualRowsOf(0, blank),
            1,
            reason: 'blank display line $blank must occupy one row',
          );
        }
      });

      test('the paint loop can resolve every row from its own Y — $mode', () {
        // The sliver derives the rows to paint by asking for the line at the
        // top and bottom of the visible band and iterating between them. A row
        // that does not answer with itself at its own Y is a row the loop can
        // step straight over, leaving it unpainted.
        final doc = _doc()..setLayoutMode(mode, 120);
        doc.setStructure(0, buildDiffRawLines(doc.files[0].patch));
        final count = doc.lineCountOf(0);

        for (var d = 0; d < count; d++) {
          final top = doc.lineTopInFile(0, d);
          expect(
            doc.lineAtFileLocalY(0, top + 0.5),
            d,
            reason: 'row $d is unreachable from its own top',
          );
          expect(
            doc.lineAtFileLocalY(
              0,
              top + doc.visualRowsOf(0, d) * _lineH - 0.5,
            ),
            d,
            reason: 'row $d is unreachable from its own bottom',
          );
        }
      });
    }

    testWidgets('row backgrounds are painted aliased, so they meet', (
      tester,
    ) async {
      // The rows tile exactly (above), but `kDiffLineHeight` is fractional, so
      // at a 2x device pixel ratio every other boundary lands on a half
      // physical pixel. Two ANTIALIASED rects each covering that pixel 50%
      // composite to ~75% and the surface shows through as a thin band — the
      // reported "weird row gap". Aliased fills snap to whole pixels instead.
      expect(_lineH * 2 % 1, 0.5, reason: 'the boundary is a half pixel at 2x');

      final painter = UnifiedRowPainter(
        cache: UnifiedLineCache(),
        brightness: Brightness.dark,
        baseStyle: const TextStyle(fontSize: 12),
        gutterWidth: 60,
        hideOldGutter: false,
        hideNewGutter: false,
        horizontalScrollOffset: 0,
        overflowMode: DiffOverflowMode.scroll,
        colsPerRow: 1 << 30,
        gutterBgColor: const Color(0xFF101010),
        gutterBorderColor: const Color(0xFF202020),
        expandGapBgColor: const Color(0xFF101010),
        expandGapBorderColor: const Color(0xFF202020),
        expandGapTextColor: const Color(0xFF808080),
        commentHighlightColor: const Color(0x33FFD33D),
        commentHighlightActiveColor: const Color(0x66FFD33D),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final doc = _doc()..setLayoutMode(DiffOverflowMode.scroll, 1 << 30);
      doc.setStructure(0, buildDiffRawLines(doc.files[0].patch));
      final raw = doc.structureOf(0)!;
      for (var d = 0; d < doc.lineCountOf(0); d++) {
        painter.paintRow(
          canvas: canvas,
          y: d * _lineH,
          raw: raw,
          fileIndex: 0,
          line: doc.rawIndexOf(0, d),
          tokens: null,
          width: 400,
          visualRows: 1,
          displayWidth: 40,
        );
      }
      recorder.endRecording().dispose();

      // Every fill the painter used for a tiling surface must be aliased. A
      // `Paint()` default is antialiased, so this is the kind of thing that
      // regresses the moment someone adds a background without thinking.
      expect(painter.debugFillPaints, isNotEmpty, reason: 'nothing pinned');
      for (final paint in painter.debugFillPaints) {
        expect(paint.isAntiAlias, isFalse);
      }
    });

    test('a wrapped line still tiles with its neighbours', () {
      final doc = _doc(
        patch:
            '@@ -0,0 +1,3 @@\n'
            '+short\n'
            '+${'x' * 300}\n'
            '+short again',
      )..setLayoutMode(DiffOverflowMode.wrap, 40);
      doc.setStructure(0, buildDiffRawLines(doc.files[0].patch));

      expect(doc.visualRowsOf(0, 1), greaterThan(1));
      for (var d = 0; d < doc.lineCountOf(0) - 1; d++) {
        expect(
          doc.offsetOfLine(0, d + 1) - doc.offsetOfLine(0, d),
          closeTo(doc.visualRowsOf(0, d) * _lineH, 0.001),
        );
      }
    });
  });
}
