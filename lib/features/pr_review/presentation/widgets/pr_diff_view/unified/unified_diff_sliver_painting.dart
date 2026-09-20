part of 'unified_diff_sliver.dart';

// These methods belong on RenderUnifiedDiffSliver (a RenderSliverMultiBoxAdaptor
// subclass). They live in an extension only to keep the part file split; Dart
// still treats extension members as outside the subclass for @protected.
// ignore_for_file: invalid_use_of_protected_member

/// Layout slot management, sticky-header computation and code-row painting
/// for the unified diff sliver render object.
extension _UnifiedDiffSliverPainting on RenderUnifiedDiffSliver {
  void scheduleLayoutModeTick() {
    if (_layoutModeTickScheduled) {
      return;
    }
    _layoutModeTickScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutModeTickScheduled = false;
      if (attached) {
        onLayoutModeChanged?.call();
      }
    });
  }

  void scheduleDeferredStructureParse() {
    if (_deferredParseScheduled) {
      return;
    }
    _deferredParseScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deferredParseScheduled = false;
      if (attached) {
        markNeedsLayout();
      }
    });
  }

  /// Code area width available for wrapping (gutter + inner padding removed).
  double codeWidthFor(double crossAxisExtent) {
    if (_config.splitMode) {
      final double halfW = math.max(0.0, (crossAxisExtent - 1) / 2);
      return math.max(
        0.0,
        halfW - kDiffSplitGutterWidth - kDiffCodePadLeft - kDiffCodePadRight,
      );
    }
    return math.max(
      0.0,
      crossAxisExtent - kDiffGutterWidth - kDiffCodePadLeft - kDiffCodePadRight,
    );
  }

  /// Visible code viewport width (gutter removed), per side in split mode.
  double codeViewportWidthFor(double crossAxisExtent) {
    if (_config.splitMode) {
      final double halfW = math.max(0.0, (crossAxisExtent - 1) / 2);
      return math.max(0.0, halfW - kDiffSplitGutterWidth);
    }
    return math.max(0.0, crossAxisExtent - kDiffGutterWidth);
  }

  int laidOutCount() {
    var count = 0;
    var child = firstChild;
    while (child != null) {
      count++;
      child = childAfter(child);
    }
    return count;
  }

  void setChildOffset(RenderBox child, int index) {
    (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
        liveSlotOffset(index);
  }

  /// Live document offset of slot [index].
  ///
  /// A slot's [DiffSlot.offset] is a snapshot taken when the host built the
  /// list. On a large PR structure parses land lazily during layout, replacing
  /// estimated file heights with exact ones — which moves every later file —
  /// while code rows always paint from the document's live offsets. Positioning
  /// children by the snapshot painted headers mid-file with a blank band at the
  /// real file boundary until an unrelated rebuild, so every slot offset the
  /// sliver acts on is re-derived from the document instead. Intra-file
  /// geometry is exact at build time (a file only gets body slots once parsed),
  /// so each slot kind can be recomputed directly.
  double liveSlotOffset(int index) {
    final slot = slots[index];
    switch (slot.kind) {
      case DiffSlotKind.header:
        return _document.offsetOfFile(slot.fileIndex);
      case DiffSlotKind.preview:
        return _document.offsetOfFile(slot.fileIndex) + _document.headerHeight;
      case DiffSlotKind.gap:
        return _document.offsetOfLine(slot.fileIndex, slot.anchorDisplayLine);
      case DiffSlotKind.comment:
      case DiffSlotKind.composer:
        final int f = slot.fileIndex;
        final int d = slot.anchorDisplayLine;
        double y =
            _document.offsetOfLine(f, d) +
            _document.visualRowsOf(f, d) * _document.lineHeight;
        // The composer stacks under a thread anchored at the same line,
        // mirroring the host's emission order (thread first, composer after).
        if (slot.kind == DiffSlotKind.composer && index > 0) {
          final prev = slots[index - 1];
          if (prev.kind == DiffSlotKind.comment &&
              prev.fileIndex == f &&
              prev.anchorDisplayLine == d) {
            y += prev.height;
          }
        }
        return y;
    }
  }

  BoxConstraints constraintsFor(int index, double crossAxisExtent) {
    final slot = slots[index];
    switch (slot.kind) {
      case DiffSlotKind.header:
      case DiffSlotKind.gap:
        return BoxConstraints.tightFor(
          width: crossAxisExtent,
          height: slot.height,
        );
      case DiffSlotKind.comment:
      case DiffSlotKind.composer:
      case DiffSlotKind.preview:
        return BoxConstraints(
          minWidth: crossAxisExtent,
          maxWidth: crossAxisExtent,
          maxHeight: double.infinity,
        );
    }
  }

  /// First slot index whose live offset is `>= value` (lower bound). Searches
  /// [liveSlotOffset], never the built-time snapshot: slots are emitted in
  /// document order, so live offsets stay sorted even after parses moved files.
  int firstSlotAtOrAfter(double value) {
    var lo = 0;
    var hi = slots.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (liveSlotOffset(mid) < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Visible slot range `[first, last]` intersecting `[start, end]`, or null.
  ({int first, int last})? visibleSlotRange(double start, double end) {
    if (slots.isEmpty) {
      return null;
    }
    final atOrAfterStart = firstSlotAtOrAfter(start);
    var first = atOrAfterStart;
    if (atOrAfterStart > 0) {
      final prev = slots[atOrAfterStart - 1];
      if (liveSlotOffset(atOrAfterStart - 1) + prev.height > start) {
        first = atOrAfterStart - 1;
      }
    }
    final last = firstSlotAtOrAfter(end) - 1;
    if (last < first) {
      return null;
    }
    return (first: first, last: math.min(last, slots.length - 1));
  }

  void layoutSlotRange(int first, int last, double crossAxisExtent) {
    if (firstChild != null) {
      final curFirst = indexOf(firstChild!);
      final curLast = indexOf(lastChild!);
      if (curLast < first || curFirst > last) {
        collectGarbage(laidOutCount(), 0);
      }
    }

    if (firstChild == null) {
      if (!addInitialChild(index: first, layoutOffset: liveSlotOffset(first))) {
        return;
      }
      firstChild!.layout(
        constraintsFor(first, crossAxisExtent),
        parentUsesSize: true,
      );
      setChildOffset(firstChild!, first);
    }

    while (indexOf(firstChild!) > first) {
      final leading = insertAndLayoutLeadingChild(
        constraintsFor(indexOf(firstChild!) - 1, crossAxisExtent),
        parentUsesSize: true,
      );
      if (leading == null) {
        break;
      }
      setChildOffset(leading, indexOf(leading));
    }

    var child = firstChild!;
    while (true) {
      final idx = indexOf(child);
      child.layout(constraintsFor(idx, crossAxisExtent), parentUsesSize: true);
      setChildOffset(child, idx);
      if (idx >= last) {
        break;
      }
      var next = childAfter(child);
      if (next == null || indexOf(next) != idx + 1) {
        next = insertAndLayoutChild(
          constraintsFor(idx + 1, crossAxisExtent),
          after: child,
          parentUsesSize: true,
        );
        if (next == null) {
          break;
        }
      }
      setChildOffset(next, indexOf(next));
      child = next;
    }

    var leadingGarbage = 0;
    var trailingGarbage = 0;
    RenderBox? c = firstChild;
    while (c != null && indexOf(c) < first) {
      leadingGarbage++;
      c = childAfter(c);
    }
    c = lastChild;
    while (c != null && indexOf(c) > last) {
      trailingGarbage++;
      c = childBefore(c);
    }
    collectGarbage(leadingGarbage, trailingGarbage);
  }

  /// Header slot index for [file], or -1.
  int headerSlotOf(int file) {
    if (file < 0 || file >= _document.fileCount) {
      return -1;
    }
    final idx = firstSlotAtOrAfter(_document.offsetOfFile(file));
    return (idx < slots.length &&
            slots[idx].fileIndex == file &&
            slots[idx].kind == DiffSlotKind.header)
        ? idx
        : -1;
  }

  void computeSticky(SliverConstraints constraints) {
    _stickyFile = _document.fileAtOffset(constraints.scrollOffset);
    _stickySlotIndex = headerSlotOf(_stickyFile);
  }

  /// Computes the sticky header's main-axis offset in paint.
  double stickyMainAxis(double originY) {
    if (_stickySlotIndex < 0) {
      _stickyPinned = false;
      return 0;
    }
    final double scrollOffset = constraints.scrollOffset;
    final double topInset = _config.topInset;
    final double naturalScreenY =
        originY + (_document.offsetOfFile(_stickyFile) - scrollOffset);
    if (naturalScreenY > topInset) {
      _stickyPinned = false;
      return naturalScreenY - originY;
    }
    final double nextScreenY = _stickyFile + 1 < _document.fileCount
        ? originY + (_document.offsetOfFile(_stickyFile + 1) - scrollOffset)
        : double.infinity;
    final double pinnedScreenY = math.min(
      topInset,
      nextScreenY - _document.headerHeight,
    );
    _stickyPinned = true;
    return pinnedScreenY - originY;
  }

  UnifiedRowPainter makeRowPainter({
    required double gutterWidth,
    required bool hideOldGutter,
    required bool hideNewGutter,
  }) {
    return UnifiedRowPainter(
      cache: lineCache,
      brightness: _config.brightness,
      baseStyle: _config.baseStyle,
      gutterWidth: gutterWidth,
      hideOldGutter: hideOldGutter,
      hideNewGutter: hideNewGutter,
      horizontalScrollOffset: _effectiveHScroll,
      overflowMode: _config.overflowMode,
      colsPerRow: _colsPerRow,
      gutterBgColor: _config.gutterBgColor,
      gutterBorderColor: _config.gutterBorderColor,
      expandGapBgColor: _config.expandGapBgColor,
      expandGapBorderColor: _config.expandGapBorderColor,
      expandGapTextColor: _config.expandGapTextColor,
      commentHighlightColor: _config.commentHighlightColor,
      commentHighlightActiveColor: _config.commentHighlightActiveColor,
      gotoUnderlineColor: _config.gotoUnderlineColor,
    );
  }

  /// Paints the visible code rows of every expanded file in
  /// `[bandTop, bandBottom]`.
  void paintCode(
    Canvas canvas,
    UnifiedRowPainter Function(int file) painterFor,
    double scrollOffset,
    double bandTop,
    double bandBottom,
    double width, {
    DiffLineKind? skipKind,
  }) {
    final double headerHeight = _document.headerHeight;
    var f = _document.fileAtOffset(math.max(0, bandTop));
    while (f < _document.fileCount) {
      final double fileTop = _document.offsetOfFile(f);
      if (fileTop >= bandBottom) {
        break;
      }
      if (_document.isExpanded(f) && !_document.isPreviewing(f)) {
        final raw = _document.structureOf(f);
        if (raw != null && raw.length > 0) {
          final painter = painterFor(f);
          final double bodyTop = fileTop + headerHeight;
          final double fileBottom = fileTop + _document.heightOfFile(f);
          final double segTop = math.max(bandTop, bodyTop);
          final double segBottom = math.min(bandBottom, fileBottom);
          if (segBottom > segTop) {
            final int firstLine = _document.lineAtFileLocalY(
              f,
              segTop - fileTop,
            );
            final int lastLine = _document.lineAtFileLocalY(
              f,
              segBottom - fileTop,
            );
            final int displayCount = _document.lineCountOf(f);
            final tokens = _store.tokensOf(f);
            for (
              var displayLine = firstLine;
              displayLine <= lastLine && displayLine < displayCount;
              displayLine++
            ) {
              final int rawIndex = _document.rawIndexOf(f, displayLine);
              final kind = raw.kindAt(rawIndex);
              if (kind == DiffLineKind.expandGap || kind == skipKind) {
                continue;
              }
              final double y =
                  _document.offsetOfLine(f, displayLine) - scrollOffset;
              final bool isSearchHit =
                  _config.searchFile == f && _config.searchRawIndex == rawIndex;
              final (int?, int?) sel = _config.splitMode
                  ? (null, null)
                  : selectionColsFor(f, displayLine);
              final hl = _config.splitMode
                  ? null
                  : _commentHighlights[f]?[displayLine];
              final goto = _config.splitMode ? null : _gotoUnderline;
              final gotoHit =
                  goto != null &&
                  goto.fileIndex == f &&
                  goto.displayLine == displayLine;
              final landing = _gotoLanding;
              final landingHit =
                  landing != null &&
                  landing.fileIndex == f &&
                  landing.displayLine == displayLine;
              painter.paintRow(
                canvas: canvas,
                y: y,
                raw: raw,
                fileIndex: f,
                line: rawIndex,
                tokens: tokens,
                width: width,
                visualRows: _document.visualRowsOf(f, displayLine),
                displayWidth: _document.displayWidthOf(f, displayLine),
                searchMatch: isSearchHit,
                selStartCol: sel.$1,
                selEndCol: sel.$2,
                commentStartCol: hl?.startCol,
                commentEndCol: hl?.endCol,
                commentActive:
                    (hl?.active ?? false) ||
                    (hl?.groupId != null &&
                        hl!.groupId == _hoveredCommentGroup),
                gotoStartCol: gotoHit ? goto.startCol : null,
                gotoEndCol: gotoHit ? goto.endCol : null,
                landingStartCol: landingHit ? landing.startCol : null,
                landingEndCol: landingHit ? landing.endCol : null,
              );
            }
          }
        }
      }
      if (_document.isExpanded(f)) {
        final double contentBottom =
            fileTop + _document.heightOfFile(f) - _document.fileSeparator;
        if (contentBottom >= bandTop && contentBottom <= bandBottom) {
          final double y = contentBottom - scrollOffset;
          canvas.drawLine(
            Offset(0, y),
            Offset(width, y),
            Paint()
              ..color = _config.gutterBorderColor
              ..strokeWidth = 1,
          );
        }
      }
      f++;
    }
  }
}
