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
    _selGranularity = _DiffSelGranularity.character;
    _pivotStart = null;
    _pivotEnd = null;
    markNeedsPaint();
    onSelectionChanged?.call();
  }

  /// Selects the browser-style word under [cell] (double-click).
  void _selectWordAt((int, int, int) cell) {
    final text = _codeLineText(cell.$1, cell.$2);
    if (text == null || text.isEmpty) {
      _selectLineAt(cell);
      return;
    }
    final range = diffWordDisplayRange(text, cell.$3);
    if (range.start == range.end) {
      _selectLineAt(cell);
      return;
    }
    _commitUnitSelection(
      (cell.$1, cell.$2, range.start),
      (cell.$1, cell.$2, range.end),
      _DiffSelGranularity.word,
    );
  }

  /// Selects the whole display row under [cell] (triple-click).
  void _selectLineAt((int, int, int) cell) {
    final width = _document.displayWidthOf(cell.$1, cell.$2);
    _commitUnitSelection(
      (cell.$1, cell.$2, 0),
      (cell.$1, cell.$2, width),
      _DiffSelGranularity.line,
    );
  }

  void _commitUnitSelection(
    (int, int, int) start,
    (int, int, int) end,
    _DiffSelGranularity granularity,
  ) {
    _selAnchor = start;
    _selFocus = end;
    _selGranularity = granularity;
    _pivotStart = start;
    _pivotEnd = end;
    markNeedsPaint();
    onSelectionChanged?.call();
  }

  /// Grows a double-click selection out to the word under [hit].
  void _extendSelectionByWord((int, int, int) hit) {
    final pivotStart = _pivotStart;
    final pivotEnd = _pivotEnd;
    if (pivotStart == null || pivotEnd == null) {
      return;
    }
    final text = _codeLineText(hit.$1, hit.$2);
    if (text == null) {
      return;
    }
    final range = diffWordDisplayRange(text, hit.$3);
    final unitStart = (hit.$1, hit.$2, range.start);
    final unitEnd = (hit.$1, hit.$2, range.end);
    if (_cellBefore(unitStart, pivotStart)) {
      _selAnchor = pivotEnd;
      _selFocus = unitStart;
    } else if (_cellAfter(unitEnd, pivotEnd)) {
      _selAnchor = pivotStart;
      _selFocus = unitEnd;
    } else {
      _selAnchor = pivotStart;
      _selFocus = pivotEnd;
    }
  }

  /// Grows a triple-click selection out to the row under [hit].
  void _extendSelectionByLine((int, int, int) hit) {
    final pivotStart = _pivotStart;
    final pivotEnd = _pivotEnd;
    if (pivotStart == null || pivotEnd == null) {
      return;
    }
    final hitLine = (hit.$1, hit.$2, 0);
    final pivotLine = (pivotStart.$1, pivotStart.$2, 0);
    final pivotEndLine = (pivotEnd.$1, pivotEnd.$2, 0);
    if (_cellBefore(hitLine, pivotLine)) {
      _selAnchor = pivotEnd;
      _selFocus = hitLine;
    } else if (_cellAfter(hitLine, pivotEndLine)) {
      _selAnchor = pivotStart;
      _selFocus = (hit.$1, hit.$2, _document.displayWidthOf(hit.$1, hit.$2));
    } else {
      _selAnchor = pivotStart;
      _selFocus = pivotEnd;
    }
  }

  /// Raw source of a context/addition/deletion display row, or null.
  String? _codeLineText(int file, int displayLine) {
    final raw = _document.structureOf(file);
    if (raw == null) {
      return null;
    }
    final r = _document.rawIndexOf(file, displayLine);
    if (r < 0 || r >= raw.length) {
      return null;
    }
    final kind = raw.kindAt(r);
    if (kind != DiffLineKind.context &&
        kind != DiffLineKind.addition &&
        kind != DiffLineKind.deletion) {
      return null;
    }
    return raw.contents[r];
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
  (int, int, int)? cellAt(
    double mainAxisPosition,
    double crossAxisPosition, {
    bool floorColumn = false,
  }) {
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
    return (
      f,
      line,
      columnAt(crossAxisPosition, f, line, subRow, floorColumn: floorColumn),
    );
  }

  /// Display column under cross-axis x [crossAxisPosition] on `(file, line)`,
  /// clamped to that line's rendered width.
  ///
  /// A drag rounds to the nearest caret. A double- or triple-click floors, so
  /// the character under the pointer is the one that gets selected.
  int columnAt(
    double crossAxisPosition,
    int file,
    int line,
    int subRow, {
    bool floorColumn = false,
  }) {
    final double codeStartX = gutterWidthOf(file) + kDiffCodePadLeft;
    final double local = crossAxisPosition - codeStartX + _effectiveHScroll;
    final int colInRow;
    if (local <= 0) {
      colInRow = 0;
    } else if (floorColumn) {
      colInRow = (local / _monoAdvance).floor();
    } else {
      colInRow = (local / _monoAdvance).round();
    }
    final int base = _config.overflowMode == DiffOverflowMode.wrap
        ? subRow * _colsPerRow
        : 0;
    return (base + colInRow).clamp(0, _document.displayWidthOf(file, line));
  }

  /// Display-column span `[start, end)` to highlight on `(file, displayLine)`,
  /// or `(null, null)` if the row is outside the selection or the span is a
  /// caret.
  ///
  /// An end of `displayWidth + 1` is the line break: VS Code paints that as
  /// one character past the last glyph, not as a bar to the row's right edge.
  /// A selection that merely ends at the last column (the caret is at EOL on
  /// this line) stops on that glyph.
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
    final width = _document.displayWidthOf(file, displayLine);
    final bool atStart = file == sf && displayLine == sl;
    final bool atEnd = file == ef && displayLine == el;
    // A line the selection continues past includes its break. A triple-click
    // does too: VS Code's line selection owns the newline even though the
    // caret stays on this row. A same-line drag that only reaches EOL does not.
    final bool includesBreak =
        !atEnd || _selGranularity == _DiffSelGranularity.line;
    if (atStart && atEnd) {
      final lo = math.min(sc, ec);
      final hi = math.max(sc, ec);
      if (lo == hi) {
        // Nothing selected. An empty row's line selection still shows the
        // break, one character wide — there is no glyph to stop on.
        if (includesBreak && width == 0) {
          return (0, 1);
        }
        return (null, null);
      }
      if (includesBreak && hi >= width) {
        return (lo, width + 1);
      }
      return (lo, hi);
    }
    if (atStart) {
      return (sc, width + 1);
    }
    if (atEnd) {
      if (includesBreak && ec >= width) {
        return (0, width + 1);
      }
      return (0, ec);
    }
    return (0, width + 1);
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

bool _cellBefore((int, int, int) a, (int, int, int) b) {
  if (a.$1 != b.$1) {
    return a.$1 < b.$1;
  }
  if (a.$2 != b.$2) {
    return a.$2 < b.$2;
  }
  return a.$3 < b.$3;
}

bool _cellAfter((int, int, int) a, (int, int, int) b) => _cellBefore(b, a);

/// Maps a raw consecutive-tap count onto the 1–3 action a browser takes on
/// [platform]. Past a triple-click, macOS keeps selecting the row, Windows
/// alternates word and row, and the other platforms cycle.
int diffSelectionTapCount(int rawCount, TargetPlatform platform) {
  switch (platform) {
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
      return rawCount <= 3 ? rawCount : (rawCount % 3 == 0 ? 3 : rawCount % 3);
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return math.min(rawCount, 3);
    case TargetPlatform.windows:
      return rawCount < 2 ? rawCount : 2 + rawCount % 2;
  }
}

/// Display columns `[start, end)` a double-click selects at [displayCol].
///
/// Letters, digits and `_` form a word. `'` and `-` join the words on either
/// side. The whitespace after a word is included, matching a browser. A click
/// on whitespace or other punctuation selects that run by itself.
({int start, int end}) diffWordDisplayRange(String content, int displayCol) {
  if (content.isEmpty) {
    return (start: 0, end: 0);
  }
  final raw = _rawUnitAtDisplayCol(content, displayCol);
  final range = _wordRawRange(content, raw);
  return (
    start: PrDiffDocument.rawColToDisplayCol(content, range.$1),
    end: PrDiffDocument.rawColToDisplayCol(content, range.$2),
  );
}

/// Character whose expanded-tab span contains [displayCol], or the last
/// character when the column is past the end of [content].
int _rawUnitAtDisplayCol(String content, int displayCol) {
  if (displayCol <= 0) {
    return 0;
  }
  var col = 0;
  for (var i = 0; i < content.length; i++) {
    final unit = content.codeUnitAt(i);
    final width = unit == 0x09 ? kDiffTabWidth - (col % kDiffTabWidth) : 1;
    if (displayCol < col + width) {
      return i;
    }
    col += width;
  }
  return content.length - 1;
}

final RegExp _kUnicodeWordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);
final RegExp _kUnicodeSpace = RegExp(r'\p{Z}', unicode: true);

bool _isWordUnit(int unit) {
  if (unit == 0x5F) {
    return true;
  }
  if (unit <= 0x7F) {
    return (unit >= 0x30 && unit <= 0x39) ||
        (unit >= 0x41 && unit <= 0x5A) ||
        (unit >= 0x61 && unit <= 0x7A);
  }
  return _kUnicodeWordChar.hasMatch(String.fromCharCode(unit));
}

bool _isSpaceUnit(int unit) {
  if (unit == 0x09 || unit == 0x20 || unit == 0xA0) {
    return true;
  }
  if (unit <= 0x7F) {
    return false;
  }
  return _kUnicodeSpace.hasMatch(String.fromCharCode(unit));
}

bool _isWordJoiner(int unit) => unit == 0x27 || unit == 0x2D || unit == 0x2019;

(int, int) _wordRawRange(String content, int index) {
  final i = index.clamp(0, content.length - 1);
  final unit = content.codeUnitAt(i);
  if (_isWordUnit(unit) || _joinsWord(content, i)) {
    return _expandWord(content, _isWordUnit(unit) ? i : i - 1);
  }
  if (_isSpaceUnit(unit)) {
    var start = i;
    var end = i + 1;
    while (start > 0 && _isSpaceUnit(content.codeUnitAt(start - 1))) {
      start--;
    }
    while (end < content.length && _isSpaceUnit(content.codeUnitAt(end))) {
      end++;
    }
    return (start, end);
  }
  var start = i;
  var end = i + 1;
  while (start > 0 &&
      !_isWordUnit(content.codeUnitAt(start - 1)) &&
      !_isSpaceUnit(content.codeUnitAt(start - 1))) {
    start--;
  }
  while (end < content.length &&
      !_isWordUnit(content.codeUnitAt(end)) &&
      !_isSpaceUnit(content.codeUnitAt(end))) {
    end++;
  }
  return (start, end);
}

/// A `'` or `-` with a word character on both sides belongs to that word.
bool _joinsWord(String content, int i) {
  if (!_isWordJoiner(content.codeUnitAt(i))) {
    return false;
  }
  return i > 0 &&
      i + 1 < content.length &&
      _isWordUnit(content.codeUnitAt(i - 1)) &&
      _isWordUnit(content.codeUnitAt(i + 1));
}

(int, int) _expandWord(String content, int seed) {
  var start = seed;
  var end = seed + 1;
  while (start > 0 && _isWordUnit(content.codeUnitAt(start - 1))) {
    start--;
  }
  while (end < content.length && _isWordUnit(content.codeUnitAt(end))) {
    end++;
  }
  var grew = true;
  while (grew) {
    grew = false;
    if (start >= 2 &&
        _isWordJoiner(content.codeUnitAt(start - 1)) &&
        _isWordUnit(content.codeUnitAt(start - 2))) {
      start -= 2;
      while (start > 0 && _isWordUnit(content.codeUnitAt(start - 1))) {
        start--;
      }
      grew = true;
    }
    if (end + 1 < content.length &&
        _isWordJoiner(content.codeUnitAt(end)) &&
        _isWordUnit(content.codeUnitAt(end + 1))) {
      end += 2;
      while (end < content.length && _isWordUnit(content.codeUnitAt(end))) {
        end++;
      }
      grew = true;
    }
  }
  while (end < content.length && _isSpaceUnit(content.codeUnitAt(end))) {
    end++;
  }
  return (start, end);
}
