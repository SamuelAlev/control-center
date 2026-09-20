part of 'unified_diff_sliver.dart';

/// Selection, hit-testing and pointer-scroll handling for the unified diff
/// sliver render object.
extension UnifiedDiffSliverInput on RenderUnifiedDiffSliver {
  /// Raw source text of the current selection, or null if none.
  String? copySelectionText() {
    final a = _selAnchor;
    final f = _selFocus;
    if (a == null || f == null) {
      return null;
    }
    final text = _document.copyTextBetween(a.$1, a.$2, a.$3, f.$1, f.$2, f.$3);
    return text.isEmpty ? null : text;
  }

  /// Clears the active selection and repaints.
  void clearSelection() {
    if (_selAnchor == null && _selFocus == null) {
      return;
    }
    _selAnchor = null;
    _selFocus = null;
    markNeedsPaint();
    onSelectionChanged?.call();
  }

  /// Active selection as a normalised range in display space, or null.
  ({int file, int startLine, int startCol, int endLine, int endCol})?
  selectionRange() {
    final a = _selAnchor;
    final f = _selFocus;
    if (a == null || f == null) {
      return null;
    }
    final file = f.$1;
    var sl = a.$1 == file ? a.$2 : 0;
    var sc = a.$1 == file ? a.$3 : 0;
    var el = f.$2;
    var ec = f.$3;
    if (el < sl || (el == sl && ec < sc)) {
      final tl = sl, tc = sc;
      sl = el;
      sc = ec;
      el = tl;
      ec = tc;
    }
    return (file: file, startLine: sl, startCol: sc, endLine: el, endCol: ec);
  }

  /// Resolves the `(file, displayLine, displayColumn)` cell at viewport
  /// position `(mainAxisPosition, crossAxisPosition)`.
  (int, int, int)? cellAt(double mainAxisPosition, double crossAxisPosition) {
    if (coversStickyHeader(mainAxisPosition)) {
      return null;
    }
    final double scrollPos = constraints.scrollOffset + mainAxisPosition;
    if (scrollPos < 0 || _document.totalExtent <= 0) {
      return null;
    }
    final clamped = scrollPos.clamp(0.0, _document.totalExtent - 0.001);
    final int f = _document.fileAtOffset(clamped);
    if (_document.isPreviewing(f)) {
      return null;
    }
    if (!_document.isExpanded(f)) {
      return (f, 0, 0);
    }
    final double yLocal = clamped - _document.offsetOfFile(f);
    final int line = yLocal < _document.headerHeight
        ? 0
        : _document.lineAtFileLocalY(f, yLocal);
    final double lineTop = _document.lineTopInFile(f, line);
    final int subRow = ((yLocal - lineTop) / kDiffLineHeight).floor().clamp(
      0,
      1 << 20,
    );
    return (f, line, columnAt(crossAxisPosition, f, line, subRow));
  }

  /// Display column under cross-axis x [crossAxisPosition] on `(file, line)`,
  /// clamped to that line's rendered width.
  int columnAt(double crossAxisPosition, int file, int line, int subRow) {
    final double codeStartX = gutterWidthOf(file) + kDiffCodePadLeft;
    final double local = crossAxisPosition - codeStartX + _effectiveHScroll;
    final int colInRow = local <= 0 ? 0 : (local / _monoAdvance).round();
    final int base = _config.overflowMode == DiffOverflowMode.wrap
        ? subRow * _colsPerRow
        : 0;
    return (base + colInRow).clamp(0, _document.displayWidthOf(file, line));
  }

  /// Display-column span `[start, end)` to highlight on `(file, displayLine)`,
  /// or `(null, null)` if the row is outside the selection.
  (int?, int?) selectionColsFor(int file, int displayLine) {
    final a = _selAnchor;
    final f = _selFocus;
    if (a == null || f == null) {
      return (null, null);
    }
    var sf = a.$1, sl = a.$2, sc = a.$3;
    var ef = f.$1, el = f.$2, ec = f.$3;
    final aAfterB = ef < sf || (ef == sf && (el < sl || (el == sl && ec < sc)));
    if (aAfterB) {
      final tf = sf, tl = sl, tc = sc;
      sf = ef;
      sl = el;
      sc = ec;
      ef = tf;
      el = tl;
      ec = tc;
    }
    if (file < sf || (file == sf && displayLine < sl)) {
      return (null, null);
    }
    if (file > ef || (file == ef && displayLine > el)) {
      return (null, null);
    }
    final bool atStart = file == sf && displayLine == sl;
    final bool atEnd = file == ef && displayLine == el;
    if (atStart && atEnd) {
      return (math.min(sc, ec), math.max(sc, ec));
    }
    if (atStart) {
      return (sc, null);
    }
    if (atEnd) {
      return (0, ec);
    }
    return (0, null);
  }

  /// Resolves the context/addition/deletion code row at [mainAxisPosition],
  /// or null if that Y isn't on a code row.
  (int, int)? codeRowAt(double mainAxisPosition) {
    if (coversStickyHeader(mainAxisPosition)) {
      return null;
    }
    final double scrollPos = constraints.scrollOffset + mainAxisPosition;
    if (scrollPos < 0 || scrollPos >= _document.totalExtent) {
      return null;
    }
    final int f = _document.fileAtOffset(scrollPos);
    if (!_document.isExpanded(f) || _document.isPreviewing(f)) {
      return null;
    }
    final raw = _document.structureOf(f);
    if (raw == null) {
      return null;
    }
    final double yLocal = scrollPos - _document.offsetOfFile(f);
    if (yLocal < _document.headerHeight) {
      return null;
    }
    final int displayLine = _document.lineAtFileLocalY(f, yLocal);
    final int rawIndex = _document.rawIndexOf(f, displayLine);
    if (rawIndex < 0 || rawIndex >= raw.length) {
      return null;
    }
    final kind = raw.kindAt(rawIndex);
    if (kind == DiffLineKind.context ||
        kind == DiffLineKind.addition ||
        kind == DiffLineKind.deletion) {
      return (f, rawIndex);
    }
    return null;
  }

  /// `(fileIndex, displayLine)` for the code row at [mainAxisPosition], or null
  /// when the position is not over one.
  (int, int)? displayRowAt(double mainAxisPosition) {
    if (coversStickyHeader(mainAxisPosition)) {
      return null;
    }
    final double scrollPos = constraints.scrollOffset + mainAxisPosition;
    if (scrollPos < 0 || scrollPos >= _document.totalExtent) {
      return null;
    }
    final int f = _document.fileAtOffset(scrollPos);
    if (!_document.isExpanded(f) || _document.isPreviewing(f)) {
      return null;
    }
    final double yLocal = scrollPos - _document.offsetOfFile(f);
    if (yLocal < _document.headerHeight) {
      return null;
    }
    return (f, _document.lineAtFileLocalY(f, yLocal));
  }

  /// Pans the code horizontally on a trackpad horizontal swipe (or shift+wheel)
  /// in scroll mode.
  void handlePointerScroll(PointerScrollEvent event) {
    if (_config.overflowMode != DiffOverflowMode.scroll) {
      return;
    }
    final double maxX = maxHorizontalScrollExtent;
    if (maxX <= 0) {
      return;
    }
    var dx = event.scrollDelta.dx;
    if (dx == 0 && HardwareKeyboard.instance.isShiftPressed) {
      dx = event.scrollDelta.dy;
    }
    if (dx == 0) {
      return;
    }
    final double current = _effectiveHScroll;
    final double next = (current + dx).clamp(0.0, maxX);
    if (next == current) {
      return;
    }
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      applyHorizontalPan(next);
    });
  }

  /// Applies a pan to the code column's horizontal scroll offset.
  void applyHorizontalPan(double offset) {
    final double clamped = offset.clamp(0.0, maxHorizontalScrollExtent);
    if (clamped == _horizontalScrollOffset) {
      return;
    }
    _horizontalScrollOffset = clamped;
    markNeedsPaint();
  }
}
