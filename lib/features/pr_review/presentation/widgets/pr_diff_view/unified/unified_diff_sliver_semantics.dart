part of 'unified_diff_sliver.dart';

/// Builds the screen-reader label of one painted code row from its kind, its
/// pre/post-image line numbers and its text (the hunk header for a hunk row).
typedef DiffLineSemanticsLabel =
    String Function(DiffLineKind kind, int? oldLine, int? newLine, String text);

/// Screen-reader nodes for the painted code rows.
///
/// Code rows are painted straight onto the canvas, so without these a screen
/// reader sees the file headers and comment cards and nothing in between. One
/// node per display row is synthesized for the rows in the cache band; the
/// ones outside the viewport are marked hidden, so the screen reader can step
/// onto them and ask the scrollable to bring them in.
extension _UnifiedDiffSliverSemantics on RenderUnifiedDiffSliver {
  List<SemanticsNode> buildLineSemantics(DiffLineSemanticsLabel label) {
    final SliverConstraints c = constraints;
    final SliverGeometry? g = geometry;
    if (_document.fileCount == 0 || g == null) {
      _lineSemanticsNodes.clear();
      return const [];
    }
    final double scrollOffset = c.scrollOffset;
    final double bandTop = math.max(0, scrollOffset + c.cacheOrigin);
    final double bandBottom =
        scrollOffset + c.cacheOrigin + c.remainingCacheExtent;
    final double paintExtent = g.paintExtent;
    final double width = c.crossAxisExtent;
    final double headerHeight = _document.headerHeight;
    final commentAction = commentOnLineActionLabel;
    final previous = _lineSemanticsNodes;
    final next = <(String, int), SemanticsNode>{};
    final out = <SemanticsNode>[];

    var f = _document.fileAtOffset(bandTop);
    while (f < _document.fileCount) {
      final double fileTop = _document.offsetOfFile(f);
      if (fileTop >= bandBottom) {
        break;
      }
      final raw = _document.structureOf(f);
      if (_document.isExpanded(f) &&
          !_document.isPreviewing(f) &&
          raw != null &&
          raw.length > 0) {
        final double bodyTop = fileTop + headerHeight;
        final double fileBottom = fileTop + _document.heightOfFile(f);
        final double segTop = math.max(bandTop, bodyTop);
        final double segBottom = math.min(bandBottom, fileBottom);
        if (segBottom > segTop) {
          final String filename = _document.files[f].filename;
          final int first = _document.lineAtFileLocalY(f, segTop - fileTop);
          final int last = _document.lineAtFileLocalY(f, segBottom - fileTop);
          final int count = _document.lineCountOf(f);
          for (var d = first; d <= last && d < count; d++) {
            final int r = _document.rawIndexOf(f, d);
            final kind = raw.kindAt(r);
            // Gap rows are real widgets with their own semantics.
            if (kind == DiffLineKind.expandGap) {
              continue;
            }
            final double y = _document.offsetOfLine(f, d) - scrollOffset;
            final double h =
                _document.visualRowsOf(f, d) * _document.lineHeight;
            final rect = Rect.fromLTWH(0, y, width, h);
            final key = (filename, r);
            final node =
                previous[key] ??
                SemanticsNode(showOnScreen: () => _showLine(filename, r));
            next[key] = node;
            final text = kind == DiffLineKind.hunkHeader
                ? (raw.hunkHeaders[r] ?? raw.contents[r])
                : raw.contents[r];
            final config = SemanticsConfiguration()
              ..label = label(kind, raw.oldLines[r], raw.newLines[r], text)
              // RTL carve-out: code reads left to right in every locale.
              ..textDirection = TextDirection.ltr
              ..isHidden = y + h <= 0 || y >= paintExtent;
            final gutterTap = onGutterTap;
            if (gutterTap != null &&
                commentAction != null &&
                kind != DiffLineKind.hunkHeader) {
              final fileIndex = f;
              config.customSemanticsActions = {
                CustomSemanticsAction(label: commentAction): () =>
                    gutterTap(fileIndex, r),
              };
            }
            node
              ..rect = rect
              ..updateWith(config: config);
            out.add(node);
          }
        }
      }
      f++;
    }
    _lineSemanticsNodes = next;
    return out;
  }

  /// Scrolls the row a screen reader stepped onto into view, clear of the
  /// docked file header. (A viewport ignores the rect of a sliver passed to
  /// `showOnScreen`, so this scrolls the viewport offset directly.)
  void _showLine(String filename, int rawIndex) {
    final f = _document.indexOfFile(filename);
    final viewport = parent;
    if (f < 0 || !attached || viewport is! RenderViewportBase) {
      return;
    }
    final raw = _document.structureOf(f);
    if (raw == null || rawIndex >= raw.length) {
      return;
    }
    final count = _document.lineCountOf(f);
    for (var d = 0; d < count; d++) {
      if (_document.rawIndexOf(f, d) != rawIndex) {
        continue;
      }
      final ViewportOffset offset = viewport.offset;
      final double top = _precedingScrollExtent + _document.offsetOfLine(f, d);
      final double bottom =
          top + _document.visualRowsOf(f, d) * _document.lineHeight;
      final double cover = _config.topInset + _document.headerHeight;
      final double extent = constraints.viewportMainAxisExtent;
      if (top < offset.pixels + cover) {
        offset.jumpTo(math.max(0, top - cover));
      } else if (bottom > offset.pixels + extent) {
        offset.jumpTo(bottom - extent);
      }
      return;
    }
  }
}
