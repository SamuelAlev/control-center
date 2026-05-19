import 'dart:collection';
import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart'
    show kDiffTabWidth, kEofGapSentinel;
import 'package:flutter/material.dart';

/// Fixed logical-pixel height of a single diff line. Canonical for the unified
/// viewer; the document, sliver, and painter all share it.
const double kDiffLineHeight = 18.75;

/// Width reserved at the left of the gutter for the hover "+" pill.
const double kDiffGutterPillSlot = 24;

/// Full gutter width (pill slot + old/new line-number columns + padding).
const double kDiffGutterWidth = 116;

/// Gutter width when only one line-number column is shown. Added files have no
/// old numbers and removed files have no new numbers, so the empty column is
/// dropped: pill slot + a single 44px column + the same 4px trailing pad as
/// [kDiffGutterWidth] (116 − one 44px column).
const double kDiffSingleGutterWidth = kDiffGutterPillSlot + 44 + 4; // 72

/// Horizontal padding between the gutter and the start of code text.
const double kDiffCodePadLeft = 8;

/// Trailing padding after the longest code line.
const double kDiffCodePadRight = 16;

/// Per-line `TextPainter` cache for the unified viewer, keyed by
/// `(fileIndex, lineIndex)` so lines from different files never collide. Each
/// entry remembers the token list it was built from; if a line's tokens change
/// identity (colour faded in, or word-diff applied) the painter rebuilds — so
/// we get free reuse during scroll and automatic invalidation when colour
/// lands, without the caller tracking ranges.
class UnifiedLineCache {
  /// Creates a cache capped at [maxEntries] painters (LRU eviction).
  UnifiedLineCache({this.maxEntries = 4096});

  /// Maximum resident painters.
  int maxEntries;

  final LinkedHashMap<(int, int), _CachedLine> _painters =
      LinkedHashMap<(int, int), _CachedLine>();

  /// Returns the painter for `(fileIndex, lineIndex)`, rebuilding via [builder]
  /// on a miss or when [tokens] differs (by identity) from the cached build.
  TextPainter get(
    int fileIndex,
    int lineIndex,
    List<DiffToken>? tokens,
    TextPainter Function() builder,
  ) {
    final key = (fileIndex, lineIndex);
    final existing = _painters.remove(key);
    if (existing != null && identical(existing.tokens, tokens)) {
      _painters[key] = existing; // touch (MRU)
      return existing.painter;
    }
    existing?.painter.dispose();
    final fresh = builder();
    _painters[key] = _CachedLine(fresh, tokens);
    while (_painters.length > maxEntries) {
      final oldest = _painters.keys.first;
      _painters.remove(oldest)?.painter.dispose();
    }
    return fresh;
  }

  /// Drops every cached painter (e.g. on theme change or font resize).
  void clear() {
    for (final c in _painters.values) {
      c.painter.dispose();
    }
    _painters.clear();
  }
}

class _CachedLine {
  _CachedLine(this.painter, this.tokens);
  final TextPainter painter;
  final List<DiffToken>? tokens;
}

/// Stateless-per-frame painter for a single diff row. Construct once at the
/// start of a paint pass (cheap — a handful of [Paint] objects), then call
/// [paintRow] for every visible row across every file. Holds a reference to a
/// persistent [UnifiedLineCache] so text layout is reused across frames.
///
/// This is the per-row logic lifted out of the old per-file `FastDiffPainter`,
/// so the unified single-canvas sliver renders pixel-identical rows.
class UnifiedRowPainter {
  /// Creates a pass painter. Colours are resolved once from [brightness].
  UnifiedRowPainter({
    required this.cache,
    required this.brightness,
    required this.baseStyle,
    required this.gutterWidth,
    required this.hideOldGutter,
    required this.hideNewGutter,
    required this.horizontalScrollOffset,
    required this.overflowMode,
    required this.colsPerRow,
    required this.gutterBgColor,
    required this.gutterBorderColor,
    required this.expandGapBgColor,
    required this.expandGapBorderColor,
    required this.expandGapTextColor,
    required this.commentHighlightColor,
    required this.commentHighlightActiveColor,
  }) : _addBgPaint = Paint()
         ..color = DiffPalette.forBrightness(brightness).additionBg,
       _delBgPaint = Paint()
         ..color = DiffPalette.forBrightness(brightness).deletionBg,
       _dragPaint = Paint()
         ..color = DiffPalette.forBrightness(brightness).dragSelectionBg,
       _commentPaint = Paint()..color = commentHighlightColor,
       _commentActivePaint = Paint()..color = commentHighlightActiveColor,
       _searchPaint = Paint()
         ..color = DiffPalette.forBrightness(
           brightness,
         ).currentSearchMatchBg.withValues(alpha: 0.38) {
    final dark = brightness == Brightness.dark;
    _hunkBgPaint = Paint()
      ..color = dark ? const Color(0xFF1A1F26) : const Color(0xFFF1F3F5);
    _indentGuidePaint = Paint()
      ..color = dark ? const Color(0xFF2D333B) : const Color(0xFFEFF2F5);
    _hoverBgPaint = Paint()
      ..color = dark ? const Color(0xFF1C2128) : const Color(0xFFF6F8FA);
    _hunkHeaderColor = dark ? const Color(0xFF8B949E) : const Color(0xFF6E7781);
    final gutterColor = dark
        ? const Color(0xFF6E7681)
        : const Color(0xFF8C959F);
    _gutterStyle = baseStyle.copyWith(
      color: gutterColor,
      fontSize: (baseStyle.fontSize ?? 13) - 0.5,
    );
    _gutterBgPaint = Paint()..color = gutterBgColor;
    _gutterBorderPaint = Paint()
      ..color = gutterBorderColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
  }

  /// Persistent line-layout cache.
  final UnifiedLineCache cache;

  /// Active theme brightness.
  final Brightness brightness;

  /// Base monospace text style.
  final TextStyle baseStyle;

  /// Effective gutter width (narrower when only one line-number column shows).
  final double gutterWidth;

  /// Hide the old/new line-number column (added/deleted files, split mode).
  final bool hideOldGutter;

  /// Hide the new line-number column.
  final bool hideNewGutter;

  /// Horizontal scroll offset; the gutter is pinned while code scrolls.
  final double horizontalScrollOffset;

  /// Whether long lines wrap or scroll horizontally.
  final DiffOverflowMode overflowMode;

  /// Code columns per visual row (wrap mode). Drives manual character wrapping
  /// and the multi-rect highlight math. Effectively infinite in scroll mode.
  final int colsPerRow;

  /// Opaque gutter background colour.
  final Color gutterBgColor;

  /// Gutter/code divider colour.
  final Color gutterBorderColor;

  /// Expand-gap row background colour.
  final Color expandGapBgColor;

  /// Expand-gap row top/bottom border colour.
  final Color expandGapBorderColor;

  /// Expand-gap "▾ N unmodified lines" label colour.
  final Color expandGapTextColor;

  /// Google-Docs-style background drawn over a commented range.
  final Color commentHighlightColor;

  /// Background drawn over the commented range whose thread is focused.
  final Color commentHighlightActiveColor;

  final Paint _addBgPaint;
  final Paint _delBgPaint;
  final Paint _dragPaint;
  final Paint _commentPaint;
  final Paint _commentActivePaint;
  final Paint _searchPaint;
  late final Paint _hunkBgPaint;
  late final Paint _indentGuidePaint;
  late final Paint _hoverBgPaint;
  late final Color _hunkHeaderColor;
  late final TextStyle _gutterStyle;
  late final Paint _gutterBgPaint;
  late final Paint _gutterBorderPaint;

  static const Color _wsHintColor = Color(0x80808080);
  static const double _monoAdvanceFallback = 7.6;

  /// Real monospace advance for [baseStyle] — turns a display column into a
  /// pixel x for whitespace markers and the selection highlight. The selection
  /// columns are resolved against the same value in the sliver, so they line
  /// up. Measured once per paint pass (cheap; the painter is short-lived).
  late final double _monoAdvance = measureMonoAdvanceWidth(baseStyle);

  /// Single-glyph painters for the whitespace hints, drawn *over* the real
  /// space/tab characters (which are now in the text and selectable) rather
  /// than replacing them. Built lazily, painted at many offsets, and released
  /// by [dispose] at the end of the paint pass.
  TextPainter? _dotMarkerPainter;
  TextPainter? _arrowMarkerPainter;

  TextPainter get _dotMarker => _dotMarkerPainter ??= _markerPainter('·');
  TextPainter get _arrowMarker => _arrowMarkerPainter ??= _markerPainter('→');

  TextPainter _markerPainter(String glyph) => TextPainter(
    text: TextSpan(
      text: glyph,
      style: baseStyle.copyWith(color: _wsHintColor),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();

  /// Releases the marker painters built during this pass. Call once after the
  /// paint loop; the line-text painters are owned (and disposed) by [cache].
  void dispose() {
    _dotMarkerPainter?.dispose();
    _arrowMarkerPainter?.dispose();
    _dotMarkerPainter = null;
    _arrowMarkerPainter = null;
  }

  /// Paints one diff row of file [fileIndex] at canvas Y [y]. [raw] is the
  /// file's structure, [line] the row index, [tokens] the optional syntax
  /// tokens for the file (`null` ⇒ plain text), [width] the row width.
  void paintRow({
    required Canvas canvas,
    required double y,
    required DiffRawLines raw,
    required int fileIndex,
    required int line,
    required Map<int, List<DiffToken>>? tokens,
    required double width,
    required int visualRows,
    required int displayWidth,
    bool hovered = false,
    bool searchMatch = false,
    int? selStartCol,
    int? selEndCol,
    int? commentStartCol,
    int? commentEndCol,
    bool commentActive = false,
  }) {
    final kind = raw.kindAt(line);
    final isHunkHeader = kind == DiffLineKind.hunkHeader;
    final isExpandGap = kind == DiffLineKind.expandGap;
    final double blockHeight = visualRows * kDiffLineHeight;
    final double hScroll = horizontalScrollOffset;
    final double codeStartX = gutterWidth + kDiffCodePadLeft;

    // ── 1. Full-width row backgrounds (pinned; never scroll). The gutter
    //    paints its own opaque background over [0, gutterWidth] last, so the
    //    add/del tint only shows in the code area. ─────────────────────────
    if (isExpandGap) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, width, blockHeight),
        Paint()..color = expandGapBgColor,
      );
      final borderPaint = Paint()
        ..color = expandGapBorderColor
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas
        ..drawLine(Offset(0, y + 0.25), Offset(width, y + 0.25), borderPaint)
        ..drawLine(
          Offset(0, y + blockHeight - 0.25),
          Offset(width, y + blockHeight - 0.25),
          borderPaint,
        );
    }
    if (isHunkHeader) {
      canvas.drawRect(Rect.fromLTWH(0, y, width, blockHeight), _hunkBgPaint);
    } else if (kind == DiffLineKind.addition) {
      canvas.drawRect(Rect.fromLTWH(0, y, width, blockHeight), _addBgPaint);
    } else if (kind == DiffLineKind.deletion) {
      canvas.drawRect(Rect.fromLTWH(0, y, width, blockHeight), _delBgPaint);
    }
    if (searchMatch) {
      canvas.drawRect(Rect.fromLTWH(0, y, width, blockHeight), _searchPaint);
    }

    // ── 2. Code content — column-anchored highlights, indent guides, text and
    //    whitespace markers. Clipped to the code area and translated by
    //    -hScroll so the code scrolls under the pinned gutter (hScroll == 0 in
    //    wrap mode). ────────────────────────────────────────────────────────
    if (!isHunkHeader && !isExpandGap) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTWH(
          gutterWidth,
          y,
          math.max(0.0, width - gutterWidth),
          blockHeight,
        ),
      );
      if (hScroll != 0) {
        canvas.translate(-hScroll, 0);
      }
      if (commentStartCol != null) {
        // Persistent Google-Docs-style highlight over a commented range; a null
        // end means "to the right edge" (a fully-covered interior line).
        _paintColSpan(
          canvas: canvas,
          y: y,
          startCol: commentStartCol,
          endCol: commentEndCol,
          displayWidth: displayWidth,
          visualRows: visualRows,
          width: width,
          paint: commentActive ? _commentActivePaint : _commentPaint,
        );
      }
      if (selStartCol != null) {
        // Character-precise selection: [selStartCol, selEndCol) in display
        // columns, one rect per wrapped sub-row. A null end means "to the right
        // edge" (interior fully selected — reads as the newline selected).
        _paintColSpan(
          canvas: canvas,
          y: y,
          startCol: selStartCol,
          endCol: selEndCol,
          displayWidth: displayWidth,
          visualRows: visualRows,
          width: width,
          paint: _dragPaint,
        );
      }
      _paintIndentGuides(
        canvas: canvas,
        y: y,
        blockHeight: blockHeight,
        content: raw.contents[line],
        codeStartX: codeStartX,
      );
      final lineTokens = tokens?[line];
      final painter = cache.get(
        fileIndex,
        line,
        lineTokens,
        () => _buildLineTextPainter(
          tokens: lineTokens,
          rawContent: raw.contents[line],
        ),
      );
      // Wrapped lines lay out at a uniform line height (== kDiffLineHeight) and
      // paint from the block top so each sub-row lands on a row boundary;
      // single-line scroll-mode text keeps its tight vertical centring.
      final double textY = overflowMode == DiffOverflowMode.wrap
          ? y
          : y + (kDiffLineHeight - painter.height) / 2;
      painter.paint(canvas, Offset(codeStartX, textY));
      _paintLeadingWhitespaceMarkers(
        canvas: canvas,
        linePainter: painter,
        content: raw.contents[line],
        codeStartX: codeStartX,
        y: y,
      );
      canvas.restore();
    }

    // ── 3. Hunk header text — pinned (does not scroll horizontally) ─────────
    if (isHunkHeader) {
      final hp = _gutterPainter(
        raw.hunkHeaders[line] ?? '',
        _gutterStyle.copyWith(color: _hunkHeaderColor),
      )..layout(maxWidth: width - gutterWidth - 16);
      hp.paint(
        canvas,
        Offset(gutterWidth + 8, y + (kDiffLineHeight - hp.height) / 2),
      );
      return; // hunk headers have no gutter/line numbers
    }

    // ── 4. Pinned gutter — painted last so it overlays the scrolled code ────
    canvas
      ..drawRect(Rect.fromLTWH(0, y, gutterWidth, blockHeight), _gutterBgPaint)
      ..drawLine(
        Offset(gutterWidth, y),
        Offset(gutterWidth, y + blockHeight),
        _gutterBorderPaint,
      );

    if (isExpandGap) {
      final oldStart = raw.oldLines[line] ?? 0;
      final oldEnd = raw.gapOldEnds[line] ?? oldStart;
      final String label;
      if (oldEnd == kEofGapSentinel) {
        label = 'Show end of file';
      } else {
        final missing = (oldEnd - oldStart + 1).clamp(0, 1 << 20);
        label = 'Show $missing ${missing == 1 ? 'line' : 'lines'}';
      }
      final lp = TextPainter(
        text: TextSpan(
          text: label,
          style: _gutterStyle.copyWith(color: expandGapTextColor),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: width - 16);
      lp.paint(canvas, Offset(16, y + (kDiffLineHeight - lp.height) / 2));
      return;
    }

    if (hovered) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, gutterWidth, blockHeight),
        _hoverBgPaint,
      );
    }
    _paintGutter(
      canvas: canvas,
      y: y,
      oldLine: raw.oldLines[line],
      newLine: raw.newLines[line],
    );
  }

  /// Paints a display-column span `[startCol, endCol)` as one rect per wrapped
  /// sub-row (a single rect in scroll mode / for non-wrapping lines). A null
  /// [endCol] means "to the row's right edge": the viewport edge ([width]) for
  /// a single visual row, or the line's full [displayWidth] across its wrapped
  /// sub-rows. The canvas is already translated to content space.
  void _paintColSpan({
    required Canvas canvas,
    required double y,
    required int startCol,
    required int? endCol,
    required int displayWidth,
    required int visualRows,
    required double width,
    required Paint paint,
  }) {
    final double codeStartX = gutterWidth + kDiffCodePadLeft;
    if (overflowMode != DiffOverflowMode.wrap || visualRows <= 1) {
      final double left = codeStartX + startCol * _monoAdvance;
      final double right = endCol == null
          ? width
          : codeStartX + endCol * _monoAdvance;
      if (right > left) {
        canvas.drawRect(
          Rect.fromLTWH(left, y, right - left, kDiffLineHeight),
          paint,
        );
      }
      return;
    }
    final int end =
        endCol ?? (displayWidth > startCol ? displayWidth : startCol + 1);
    final int firstRow = startCol ~/ colsPerRow;
    final int lastRow = end <= startCol ? firstRow : (end - 1) ~/ colsPerRow;
    for (var row = firstRow; row <= lastRow; row++) {
      final int rowStartCol = row == firstRow ? startCol % colsPerRow : 0;
      final int rowEndCol = row == lastRow
          ? ((end - 1) % colsPerRow) + 1
          : colsPerRow;
      final double left = codeStartX + rowStartCol * _monoAdvance;
      final double right = codeStartX + rowEndCol * _monoAdvance;
      final double ry = y + row * kDiffLineHeight;
      if (right > left) {
        canvas.drawRect(
          Rect.fromLTWH(left, ry, right - left, kDiffLineHeight),
          paint,
        );
      }
    }
  }

  void _paintGutter({
    required Canvas canvas,
    required double y,
    required int? oldLine,
    required int? newLine,
  }) {
    const colWidth = 44.0;
    const baseX = kDiffGutterPillSlot;
    if (!hideOldGutter) {
      final tp = _gutterPainter(oldLine?.toString() ?? '', _gutterStyle)
        ..layout(maxWidth: colWidth - 6);
      tp.paint(
        canvas,
        Offset(
          baseX + colWidth - 6 - tp.width,
          y + (kDiffLineHeight - tp.height) / 2,
        ),
      );
    }
    if (!hideNewGutter) {
      final tp = _gutterPainter(newLine?.toString() ?? '', _gutterStyle)
        ..layout(maxWidth: colWidth - 6);
      final colX = baseX + (hideOldGutter ? 0.0 : colWidth);
      tp.paint(
        canvas,
        Offset(
          colX + colWidth - 6 - tp.width,
          y + (kDiffLineHeight - tp.height) / 2,
        ),
      );
    }
  }

  void _paintIndentGuides({
    required Canvas canvas,
    required double y,
    required double blockHeight,
    required String content,
    required double codeStartX,
  }) {
    final level = _indentLevel(content);
    if (level < 2) {
      return;
    }
    for (var stop = 2; stop < level; stop += 2) {
      final x = codeStartX + stop * _monoAdvanceFallback;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + blockHeight),
        _indentGuidePaint,
      );
    }
  }

  static int _indentLevel(String content) {
    var col = 0;
    for (var i = 0; i < content.length; i++) {
      final c = content[i];
      if (c == '\t') {
        col += kDiffTabWidth - (col % kDiffTabWidth);
      } else if (c == ' ') {
        col++;
      } else {
        return col;
      }
    }
    return 0;
  }

  TextPainter _gutterPainter(String text, TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    textAlign: TextAlign.right,
  );

  TextPainter _buildLineTextPainter({
    required List<DiffToken>? tokens,
    required String rawContent,
  }) {
    final bool wrap = overflowMode == DiffOverflowMode.wrap;
    final int wrapCols = wrap ? colsPerRow : 0;
    final TextSpan span;
    if (tokens == null || tokens.isEmpty) {
      span = TextSpan(
        style: baseStyle,
        children: _buildRawSpans(rawContent, wrapCols),
      );
    } else {
      span = TextSpan(
        style: baseStyle,
        children: _buildTokenSpans(tokens, wrapCols),
      );
    }
    if (wrap) {
      // The spans already carry hard '\n's at every colsPerRow boundary (manual
      // character wrap), so the line count is exactly ceil(displayWidth /
      // colsPerRow) — matching the document's integer height model with no
      // clipping. A uniform line height (no first-ascent/last-descent trim) so
      // every sub-row is exactly kDiffLineHeight tall.
      return TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
    }
    return TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textWidthBasis: TextWidthBasis.longestLine,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    )..layout();
  }

  // Spans carry the *real* source text (tabs expanded to spaces so the line
  // lays out at tab-width and stays monospace). The `→`/`·` hints are no longer
  // baked into the text — they're painted as decoration over the real
  // whitespace by [_paintLeadingWhitespaceMarkers] — so what the user selects
  // and copies is the genuine space/tab, never a marker glyph.
  List<TextSpan> _buildTokenSpans(List<DiffToken> tokens, int wrapCols) {
    final spans = <TextSpan>[];
    var col = 0;
    for (final t in tokens) {
      final (expanded, nextCol) = _expandAndWrap(t.text, col, wrapCols);
      col = nextCol;
      spans.add(TextSpan(text: expanded, style: _styleForToken(t, baseStyle)));
    }
    return spans;
  }

  List<TextSpan> _buildRawSpans(String rawContent, int wrapCols) => [
    TextSpan(
      text: _expandAndWrap(rawContent, 0, wrapCols).$1,
      style: baseStyle,
    ),
  ];

  /// Expands every `\t` in [text] to spaces up to the next [kDiffTabWidth] stop,
  /// starting at display column [startCol]. When [wrapCols] > 0, also inserts a
  /// hard `\n` at every [wrapCols]-column boundary — manual character soft-wrap
  /// so the painted row count is exactly `ceil(displayWidth / wrapCols)`,
  /// matching the document's integer height model (no clipping, no measuring).
  /// Returns the expanded text and the resulting display column, so spans lay
  /// out left-to-right with correct tab stops and wrap points across token
  /// boundaries.
  static (String, int) _expandAndWrap(String text, int startCol, int wrapCols) {
    if (wrapCols <= 0 && !text.contains('\t')) {
      return (text, startCol + text.length);
    }
    final buf = StringBuffer();
    var col = startCol;
    void emit(String ch) {
      if (wrapCols > 0 && col > 0 && col % wrapCols == 0) {
        buf.write('\n');
      }
      buf.write(ch);
      col++;
    }

    for (var i = 0; i < text.length; i++) {
      if (text[i] == '\t') {
        final n = kDiffTabWidth - (col % kDiffTabWidth);
        for (var k = 0; k < n; k++) {
          emit(' ');
        }
      } else {
        emit(text[i]);
      }
    }
    return (buf.toString(), col);
  }

  static TextStyle _styleForToken(DiffToken t, TextStyle base) {
    if (t.colorValue == null && t.backgroundColorValue == null) {
      return base;
    }
    return base.copyWith(
      color: t.colorValue == null ? null : Color(t.colorValue!),
      backgroundColor: t.backgroundColorValue == null
          ? null
          : Color(t.backgroundColorValue!),
    );
  }

  /// Draws the `·` (space) / `→` (tab) hints over the *leading* whitespace,
  /// positioned by the line's own [TextPainter] so they sit exactly on top of
  /// the real characters without being part of the selectable text. The display
  /// column (tabs expanded) is the index into the expanded text the painter
  /// laid out, so its caret offset is the exact glyph x.
  void _paintLeadingWhitespaceMarkers({
    required Canvas canvas,
    required TextPainter linePainter,
    required String content,
    required double codeStartX,
    required double y,
  }) {
    var col = 0;
    for (var i = 0; i < content.length; i++) {
      final c = content[i];
      if (c != '\t' && c != ' ') {
        break; // leading whitespace only
      }
      final marker = c == '\t' ? _arrowMarker : _dotMarker;
      // The caret offset carries both the within-row x (.dx) and the sub-row
      // baseline (.dy) for a wrapped paragraph; .dy is 0 for single-line text
      // and for leading whitespace on row 0, so this is correct in both modes.
      final caret = linePainter.getOffsetForCaret(
        TextPosition(offset: col),
        Rect.zero,
      );
      final double x = codeStartX + caret.dx;
      marker.paint(
        canvas,
        Offset(x, y + caret.dy + (kDiffLineHeight - marker.height) / 2),
      );
      col += c == '\t' ? kDiffTabWidth - (col % kDiffTabWidth) : 1;
    }
  }

  /// Whether a repaint is needed when replacing [old] with this painter.
  bool differsFrom(UnifiedRowPainter old) {
    return old.brightness != brightness ||
        old.gutterWidth != gutterWidth ||
        old.hideOldGutter != hideOldGutter ||
        old.hideNewGutter != hideNewGutter ||
        old.horizontalScrollOffset != horizontalScrollOffset ||
        old.overflowMode != overflowMode ||
        old.colsPerRow != colsPerRow ||
        old.gutterBgColor != gutterBgColor ||
        old.gutterBorderColor != gutterBorderColor ||
        old.expandGapBgColor != expandGapBgColor ||
        old.expandGapBorderColor != expandGapBorderColor ||
        old.expandGapTextColor != expandGapTextColor ||
        old.baseStyle != baseStyle;
  }
}

/// Exact advance width of one monospace glyph in [baseStyle]. Used to map a
/// cross-axis x to a display column (selection hit-testing) and back to a pixel
/// x (selection highlight); both sides must use the same value, and it must
/// match the laid-out glyph stride, so it's measured precisely with no margin.
double measureMonoAdvanceWidth(TextStyle baseStyle) {
  final painter = TextPainter(
    text: TextSpan(text: 'M' * 80, style: baseStyle),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = painter.width / 80;
  painter.dispose();
  return width;
}
