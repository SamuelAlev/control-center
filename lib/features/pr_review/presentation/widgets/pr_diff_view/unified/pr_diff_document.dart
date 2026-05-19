import 'dart:math' as math;

import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_fenwick.dart';
import 'package:control_center/shared/utils/diff_parser.dart';

/// Sentinel stored in an expand-gap row's `gapOldEnd` / `gapNewEnd` to mark a
/// "show rest of file" gap whose end is the (unknown) end of the file. The
/// painter renders it as "Show end of file" and expanding it fetches the file
/// and reveals every line from the gap start to EOF.
const int kEofGapSentinel = -1;

/// Tab width (in columns) the renderer expands `\t` to. Shared with the painter
/// so the *display* columns a selection reports line up with the raw source the
/// document slices on copy.
const int kDiffTabWidth = 4;

/// Which line-number columns a file's gutter shows. Added files carry no old
/// line numbers and removed files carry no new ones, so each collapses its
/// gutter to a single column ([newOnly] / [oldOnly]); a two-sided diff (context
/// + modifications, including renames with edits) keeps [both].
enum DiffGutterMode {
  /// Both old and new line-number columns (the default two-sided diff).
  both,

  /// Only the old line-number column (removed files — no new side).
  oldOnly,

  /// Only the new line-number column (added files — no old side).
  newOnly,
}

/// One inline-comment block (a thread, or the open composer) anchored below a
/// code line. Heights are measured by the hosting child widget and fed back
/// via [PrDiffDocument.setCommentBlocks].
class DiffCommentBlock {
  /// Creates a comment block anchored at [anchorLine] (a line index into the
  /// file's parsed structure) with the given measured [height].
  const DiffCommentBlock({
    required this.key,
    required this.anchorLine,
    required this.height,
  });

  /// Stable identity for the hosting child widget (thread id, or a composer
  /// sentinel). Drives child reuse across rebuilds.
  final String key;

  /// Line index this block renders *below*. `-1` anchors above the first code
  /// line (rare; file-level composer).
  final int anchorLine;

  /// Measured height in logical pixels.
  final double height;
}

/// Per-file vertical layout state inside the unified diff document.
class _FileLayout {
  _FileLayout({required this.estimatedLines, required this.expanded});

  /// Whether the file's body is shown. Collapsed files occupy only the header.
  bool expanded;

  /// Whether the file's body renders a Markdown preview instead of the diff.
  /// Only meaningful while [expanded]. A previewing file paints no code rows;
  /// its body is a single measured slot whose height is [previewHeight].
  bool previewing = false;

  /// Reserved height of the Markdown preview body (header + this + separator).
  /// Seeded with an estimate, replaced by the measured height fed back from the
  /// hosting slot — mirrors the comment-block measure path.
  double previewHeight = 240;

  /// Parsed pass-1 structure. Null until the structure store fills it in.
  DiffRawLines? structure;

  /// Which line-number columns this file's gutter shows, derived from
  /// [structure]. Null until parsed; [PrDiffDocument.gutterModeOf] falls back to
  /// the file status in the meantime so the gutter width doesn't jump on load.
  DiffGutterMode? gutterMode;

  /// Upper-bound line count from the patch, used to size the file before its
  /// structure has been parsed (keeps the scroll extent stable from frame 1).
  int estimatedLines;

  /// Indices into [structure] of the rows actually rendered, in display order
  /// — i.e. everything except `@@` hunk-header rows, which the unified viewer
  /// drops in favour of the "Show N lines" expand affordances. Empty until the
  /// structure is parsed.
  List<int> displayToRaw = const [];

  /// Inline-comment blocks, sorted ascending by [DiffCommentBlock.anchorLine].
  List<DiffCommentBlock> comments = const [];

  /// `_commentCumBelow[i]` = total comment height for blocks with
  /// `anchorLine < i`-th block's anchorLine, i.e. a prefix sum aligned to
  /// [comments]. `_commentCumBelow[comments.length]` == [commentTotal].
  List<double> _commentPrefix = const [0];

  /// Sum of all comment-block heights for this file.
  double commentTotal = 0;

  /// Effective rendered-line count: number of display rows once parsed (hunk
  /// headers excluded), else the pre-parse estimate.
  int get lineCount => structure == null ? estimatedLines : displayToRaw.length;

  /// Cumulative *visual* rows: `_visualRowPrefix[d]` = visual rows of display
  /// lines `[0, d)`; length `lineCount + 1`. Trivial (`[0]`) in scroll mode and
  /// before parse, in which case every line is one visual row.
  List<int> _visualRowPrefix = const [0];

  /// Largest display-column width across this file's lines (tabs expanded).
  /// Drives the horizontal-scroll content extent. Computed in
  /// [recomputeVisualRows].
  int _maxDisplayCols = 0;

  /// Total visual rows in the file body: the wrapped row count in wrap mode,
  /// else [lineCount] (so the file height stays byte-identical to the pre-wrap
  /// formula in scroll mode).
  int get effectiveVisualRows =>
      _visualRowPrefix.length > 1 ? _visualRowPrefix.last : lineCount;

  /// Cumulative visual rows strictly above display line [line].
  int _visualRowsBefore(int line) {
    if (line <= 0) {
      return 0;
    }
    final p = _visualRowPrefix;
    return p.length > line ? p[line] : line;
  }

  /// Display-column width (tabs expanded) of display line [d].
  int _displayWidthOfDisplayLine(int d) {
    final raw = structure;
    if (raw == null) {
      return 0;
    }
    final r = (d >= 0 && d < displayToRaw.length) ? displayToRaw[d] : d;
    if (r < 0 || r >= raw.length) {
      return 0;
    }
    return PrDiffDocument._expandedWidth(raw.contents[r]);
  }

  /// Recomputes the wrap prefix sums and [_maxDisplayCols] for [mode] /
  /// [colsPerRow]. Pure integer math, O(file content length). In scroll mode
  /// (or before parse / empty) the prefix stays trivial so every line is one
  /// visual row, but [_maxDisplayCols] is still computed for the scroll extent.
  void recomputeVisualRows(int colsPerRow, DiffOverflowMode mode) {
    final n = lineCount;
    final raw = structure;
    if (raw == null || n == 0) {
      _visualRowPrefix = const [0];
      _maxDisplayCols = 0;
      return;
    }
    final wrap = mode == DiffOverflowMode.wrap;
    final prefix = wrap ? List<int>.filled(n + 1, 0) : const <int>[0];
    var acc = 0;
    var maxCols = 0;
    for (var d = 0; d < n; d++) {
      final w = _displayWidthOfDisplayLine(d);
      if (w > maxCols) {
        maxCols = w;
      }
      if (wrap) {
        prefix[d] = acc;
        acc += w <= 0 ? 1 : ((w + colsPerRow - 1) ~/ colsPerRow);
      }
    }
    _maxDisplayCols = maxCols;
    if (wrap) {
      prefix[n] = acc;
      _visualRowPrefix = prefix;
    } else {
      _visualRowPrefix = const [0];
    }
  }

  void recomputeComments() {
    if (comments.isEmpty) {
      _commentPrefix = const [0];
      commentTotal = 0;
      return;
    }
    final prefix = List<double>.filled(comments.length + 1, 0);
    for (var i = 0; i < comments.length; i++) {
      prefix[i + 1] = prefix[i] + comments[i].height;
    }
    _commentPrefix = prefix;
    commentTotal = prefix.last;
  }

  /// Total comment height inserted strictly above code line [line].
  double commentExtraAbove(int line) {
    if (comments.isEmpty) {
      return 0;
    }
    // Count blocks whose anchorLine < line (they render above `line`).
    // Binary search for the first block with anchorLine >= line.
    var lo = 0;
    var hi = comments.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (comments[mid].anchorLine < line) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return _commentPrefix[lo];
  }
}

/// Resolved hit: what occupies a particular Y in the unified scroll space.
sealed class DiffHit {
  const DiffHit({required this.fileIndex});

  /// File this hit belongs to.
  final int fileIndex;
}

/// The Y falls on a file header row.
class HeaderHit extends DiffHit {
  /// Creates a header hit for [fileIndex].
  const HeaderHit({required super.fileIndex});
}

/// The Y falls on a painted code line (context / addition / deletion /
/// hunk-header / expand-gap), identified by [lineIndex] into the structure.
class LineHit extends DiffHit {
  /// Creates a line hit.
  const LineHit({required super.fileIndex, required this.lineIndex});

  /// Line index into the file's parsed structure.
  final int lineIndex;
}

/// The Y falls inside an inline-comment block.
class CommentHit extends DiffHit {
  /// Creates a comment-block hit.
  const CommentHit({
    required super.fileIndex,
    required this.blockIndex,
    required this.anchorLine,
  });

  /// Index into the file's [_FileLayout.comments].
  final int blockIndex;

  /// Line the block is anchored below.
  final int anchorLine;
}

/// The flat, continuous vertical model of an entire PR diff: every file, in
/// tree order, laid out one after another in a single scroll space.
///
/// Indexed per *file* via a [DiffFenwickTree] (3000 files, not 150k lines), so
/// every offset↔file query is O(log files) and any single-file height change
/// (collapse/expand, comment measure, gap expand) is an O(log files) point
/// update — the scroll extent stays exact with no per-frame O(n) work.
///
/// Within a file the layout is arithmetic: a fixed-height header, then code
/// lines at a uniform [lineHeight], with inline-comment blocks inserting extra
/// height below their anchor line. This avoids materialising a row object per
/// line.
class PrDiffDocument {
  /// Creates a document. [lineHeight] is the fixed code-line height;
  /// [headerHeight] is the per-file header height.
  PrDiffDocument({
    required this.lineHeight,
    required this.headerHeight,
    required this.autoCollapseThreshold,
    this.fileSeparator = 10,
  });

  /// Fixed height of a single code line.
  final double lineHeight;

  /// Fixed height of a file header row.
  final double headerHeight;

  /// Files whose patch exceeds this many lines start collapsed.
  final int autoCollapseThreshold;

  /// Trailing empty space appended below every file so consecutive files have
  /// visual breathing room. Code rows + slots live above this gap.
  final double fileSeparator;

  List<PrFile> _files = const [];
  final List<_FileLayout> _layouts = [];
  final DiffFenwickTree _fenwick = DiffFenwickTree(const []);

  /// Active overflow mode. In [DiffOverflowMode.scroll] every line occupies a
  /// single visual row (heights are width-independent — identical to the
  /// pre-wrap behaviour); in [DiffOverflowMode.wrap] a line occupies
  /// `ceil(displayWidth / colsPerRow)` rows.
  DiffOverflowMode _overflowMode = DiffOverflowMode.scroll;

  /// Code columns per visual row in wrap mode. A huge sentinel in scroll mode
  /// so `ceil(width / colsPerRow) == 1` for every line with no hot-path branch.
  int _colsPerRow = 1 << 30;

  /// Files in display (tree) order.
  List<PrFile> get files => _files;

  /// Number of files.
  int get fileCount => _files.length;

  /// Total vertical extent of the whole diff in logical pixels.
  double get totalExtent => _fenwick.total;

  /// Replaces the file list, preserving per-file expanded / comment state for
  /// files that survive (matched by filename). New large files auto-collapse.
  ///
  /// Returns the indices of surviving files whose **patch changed** — their
  /// stale structure was dropped so it re-parses from the new patch. Callers
  /// must invalidate any derived caches (e.g. syntax tokens) for these indices.
  /// This matters for the local-git source, which emits each file first with an
  /// empty patch (fast tree render) and then again with the real patch filled
  /// in: without this, the empty-patch structure would be cached and the diff
  /// body would render headers with no content.
  List<int> setFiles(List<PrFile> next) {
    // Preserve prior per-file state (layout + the file it was parsed from) by
    // filename.
    final priorLayout = <String, _FileLayout>{};
    final priorFile = <String, PrFile>{};
    for (var i = 0; i < _files.length; i++) {
      priorLayout[_files[i].filename] = _layouts[i];
      priorFile[_files[i].filename] = _files[i];
    }
    _files = next;
    _layouts.clear();
    final repatched = <int>[];
    for (var i = 0; i < next.length; i++) {
      final f = next[i];
      final existing = priorLayout[f.filename];
      if (existing != null) {
        final old = priorFile[f.filename];
        if (old != null && old.patch != f.patch) {
          // The patch content changed (e.g. empty tree → filled patch). The
          // cached structure is stale; drop it and re-estimate the height, but
          // keep the user's expand state and any inline-comment blocks.
          existing
            ..structure = null
            ..gutterMode = null
            ..displayToRaw = const []
            ..estimatedLines = _estimateLines(f);
          repatched.add(i);
        }
        // The viewer's viewed state can arrive in a later load than the file
        // list itself (the GitHub source yields files first, then a second
        // load enriched with viewerViewedState). When it flips for a surviving
        // file, mirror the collapse-on-view behaviour so a viewed file folds
        // and an un-viewed one unfolds — otherwise the preserved layout stays
        // expanded and the header reads "viewed" over an open diff. A plain
        // expand/collapse the user made without changing viewed state (same
        // viewed flag on both files) is left untouched.
        if (old != null &&
            old.viewerViewedState.isViewed != f.viewerViewedState.isViewed) {
          existing.expanded = !f.viewerViewedState.isViewed;
        }
        _layouts.add(existing);
      } else {
        final estimated = _estimateLines(f);
        // A file the viewer has already marked viewed starts collapsed
        // (mirrors the collapse-on-view behaviour), regardless of its size —
        // so re-entering a PR shows viewed files folded away.
        final startCollapsed =
            f.viewerViewedState.isViewed || estimated > autoCollapseThreshold;
        _layouts.add(
          _FileLayout(estimatedLines: estimated, expanded: !startCollapsed),
        );
      }
    }
    _rebuildFenwick();
    return repatched;
  }

  int _estimateLines(PrFile file) {
    final patch = file.patch;
    if (patch.isEmpty) {
      return math.max(1, file.additions + file.deletions + 4);
    }
    return math.max(1, '\n'.allMatches(patch).length);
  }

  double _heightOf(int i) {
    final l = _layouts[i];
    if (!l.expanded) {
      return headerHeight + fileSeparator;
    }
    if (l.previewing) {
      // A previewing file paints no code rows and hides comments; its body is
      // the measured Markdown preview slot.
      return headerHeight + l.previewHeight + fileSeparator;
    }
    // effectiveVisualRows == lineCount in scroll mode (byte-identical to the
    // pre-wrap formula); the wrapped row count in wrap mode.
    return headerHeight +
        l.effectiveVisualRows * lineHeight +
        l.commentTotal +
        fileSeparator;
  }

  void _rebuildFenwick() {
    final heights = List<double>.generate(_files.length, _heightOf);
    _fenwick.rebuild(heights);
  }

  void _refreshHeight(int i) => _fenwick.update(i, _heightOf(i));

  /// Sets the overflow mode and (for wrap) the code columns per visual row,
  /// recomputing every file's wrap layout and the scroll extent. Called by the
  /// sliver each layout from the live viewport width. Returns true if anything
  /// changed (the caller must clear its line cache and rebuild slot offsets,
  /// since per-line heights — and therefore `offsetOfLine` — have moved).
  ///
  /// `colsPerRow` is an integer, so sub-pixel width jitter that doesn't cross a
  /// column boundary is a no-op (early return).
  bool setLayoutMode(DiffOverflowMode mode, int colsPerRow) {
    final effective = mode == DiffOverflowMode.wrap
        ? math.max(1, colsPerRow)
        : (1 << 30);
    if (_overflowMode == mode && _colsPerRow == effective) {
      return false;
    }
    _overflowMode = mode;
    _colsPerRow = effective;
    for (var i = 0; i < _layouts.length; i++) {
      _layouts[i].recomputeVisualRows(effective, mode);
    }
    _rebuildFenwick();
    return true;
  }

  /// Visual rows occupied by display line [displayLine] of file [i] (1 in
  /// scroll mode; `ceil(displayWidth / colsPerRow)` in wrap mode).
  int visualRowsOf(int i, int displayLine) {
    final p = _layouts[i]._visualRowPrefix;
    if (displayLine >= 0 && p.length > displayLine + 1) {
      return p[displayLine + 1] - p[displayLine];
    }
    return 1;
  }

  /// Largest line display-column width across expanded, parsed files — drives
  /// the horizontal-scroll content extent. 0 when nothing is scrollable.
  int maxDisplayColsOfExpanded() {
    var maxCols = 0;
    for (var i = 0; i < _layouts.length; i++) {
      final l = _layouts[i];
      if (l.expanded && l.structure != null && l._maxDisplayCols > maxCols) {
        maxCols = l._maxDisplayCols;
      }
    }
    return maxCols;
  }

  /// Display line of layout [l] whose visual-row span contains [vrow]
  /// (wrap mode). Binary search over the cumulative prefix.
  int _displayLineForVisualRow(_FileLayout l, int vrow) {
    final p = l._visualRowPrefix;
    var lo = 0;
    var hi = l.lineCount - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (p[mid] <= vrow) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  // ── Per-file accessors ────────────────────────────────────────────────

  /// Top offset of file [i] in the unified scroll space.
  double offsetOfFile(int i) => _fenwick.offsetOf(i);

  /// Total height of file [i] (header + body when expanded).
  double heightOfFile(int i) => _heightOf(i);

  /// Whether file [i] is expanded.
  bool isExpanded(int i) => _layouts[i].expanded;

  /// Whether file [i] renders a Markdown preview instead of the diff body.
  bool isPreviewing(int i) => _layouts[i].previewing;

  /// Reserved Markdown-preview body height of file [i].
  double previewHeightOf(int i) => _layouts[i].previewHeight;

  /// Parsed structure of file [i], or null if not parsed yet.
  DiffRawLines? structureOf(int i) => _layouts[i].structure;

  /// Effective line count of file [i] (exact when parsed, else estimated).
  int lineCountOf(int i) => _layouts[i].lineCount;

  /// Comment blocks of file [i], sorted by anchor line.
  List<DiffCommentBlock> commentsOf(int i) => _layouts[i].comments;

  /// File index whose vertical range contains [offset].
  int fileAtOffset(double offset) => _fenwick.indexAtOffset(offset);

  /// Number of *display* columns code line [displayLine] of file [i] occupies
  /// once tabs are expanded to [kDiffTabWidth] stops — i.e. its rendered width
  /// in monospace columns. Used to clamp a selection's column to the text.
  int displayWidthOf(int i, int displayLine) {
    final raw = _layouts[i].structure;
    if (raw == null) {
      return 0;
    }
    final r = rawIndexOf(i, displayLine);
    if (r < 0 || r >= raw.length) {
      return 0;
    }
    return _expandedWidth(raw.contents[r]);
  }

  /// Assembles the raw source of `(aFile, aLine, aCol)`..`(bFile, bLine, bCol)`
  /// (inclusive, any order), across files, joined with '\n'. The columns are
  /// *display* columns (tabs expanded). Uses the RAW parsed content — no +/-
  /// markers, real tabs (never the painter's `→`/`·` hints) — so pasted text is
  /// real source. Non-code rows (hunk headers, gaps) contribute nothing. The
  /// first and last lines are sliced at the mapped raw column; lines between
  /// are taken whole.
  String copyTextBetween(
    int aFile,
    int aLine,
    int aCol,
    int bFile,
    int bLine,
    int bCol,
  ) {
    var sf = aFile, sl = aLine, sc = aCol;
    var ef = bFile, el = bLine, ec = bCol;
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
    final out = <String>[];
    for (var f = sf; f <= ef && f < _files.length; f++) {
      final raw = _layouts[f].structure;
      if (raw == null) {
        continue;
      }
      final count = _layouts[f].lineCount;
      final from = f == sf ? sl : 0;
      final to = f == ef ? el : count - 1;
      for (var d = math.max(0, from); d <= to && d < count; d++) {
        final r = rawIndexOf(f, d);
        if (r < 0 || r >= raw.length) {
          continue;
        }
        final k = raw.kindAt(r);
        if (k != DiffLineKind.context &&
            k != DiffLineKind.addition &&
            k != DiffLineKind.deletion) {
          continue;
        }
        var text = raw.contents[r];
        final atStart = f == sf && d == sl;
        final atEnd = f == ef && d == el;
        if (atStart && atEnd) {
          final lo = _displayColToRawCol(text, math.min(sc, ec));
          final hi = _displayColToRawCol(text, math.max(sc, ec));
          text = text.substring(lo, hi);
        } else if (atStart) {
          text = text.substring(_displayColToRawCol(text, sc));
        } else if (atEnd) {
          text = text.substring(0, _displayColToRawCol(text, ec));
        }
        out.add(text);
      }
    }
    return out.join('\n');
  }

  /// Display width (tabs expanded to [kDiffTabWidth] stops) of [content].
  static int _expandedWidth(String content) {
    var col = 0;
    for (var i = 0; i < content.length; i++) {
      col += content[i] == '\t' ? kDiffTabWidth - (col % kDiffTabWidth) : 1;
    }
    return col;
  }

  /// Maps a *display* column (tabs expanded) to the raw character index in
  /// [content] — the inverse of the painter's tab expansion. Clamps to the
  /// string bounds.
  static int _displayColToRawCol(String content, int displayCol) {
    if (displayCol <= 0) {
      return 0;
    }
    var col = 0;
    for (var i = 0; i < content.length; i++) {
      if (col >= displayCol) {
        return i;
      }
      col += content[i] == '\t' ? kDiffTabWidth - (col % kDiffTabWidth) : 1;
    }
    return content.length;
  }

  // ── Within-file layout (file-local Y, measured from the file's top) ───

  /// File-local Y of the top of code line [line] in file [i] (after the
  /// header and any comment blocks above it). Uses cumulative *visual* rows so
  /// wrapped lines above [line] push it down by their extra rows.
  double lineTopInFile(int i, int line) {
    final l = _layouts[i];
    return headerHeight +
        l._visualRowsBefore(line) * lineHeight +
        l.commentExtraAbove(line);
  }

  /// Absolute Y (unified scroll space) of the top of code line [line].
  double offsetOfLine(int i, int line) =>
      offsetOfFile(i) + lineTopInFile(i, line);

  /// Resolves the code line whose slot contains file-local [yLocal], assuming
  /// `yLocal >= headerHeight`. Returns a clamped line index. Comment regions
  /// resolve to their anchor line.
  int lineAtFileLocalY(int i, double yLocal) {
    final l = _layouts[i];
    final count = l.lineCount;
    if (count <= 0) {
      return 0;
    }
    final wrap =
        _overflowMode == DiffOverflowMode.wrap && l._visualRowPrefix.length > 1;
    if (l.comments.isEmpty) {
      if (!wrap) {
        final line = ((yLocal - headerHeight) / lineHeight).floor();
        return line.clamp(0, count - 1);
      }
      // Map yLocal to a visual row, then to the display line whose wrapped span
      // contains it.
      final vrow = ((yLocal - headerHeight) / lineHeight).floor();
      if (vrow <= 0) {
        return 0;
      }
      return _displayLineForVisualRow(l, vrow).clamp(0, count - 1);
    }
    // Comments present: binary search for the largest line whose top <= yLocal.
    // lineTopInFile is monotonic in both modes (wrap heights fold in), so this
    // works unchanged for wrap + comments.
    var lo = 0;
    var hi = count - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (lineTopInFile(i, mid) <= yLocal) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  /// Installs parsed [structure] for file [i], computes the display→raw row
  /// map (dropping `@@` hunk headers), optionally appends a "Show end of file"
  /// gap, and refreshes the file's height.
  ///
  /// Pass `augment: false` when re-installing a spliced structure after a gap
  /// expand — the EOF gap (if any) is already present and must not be doubled.
  void setStructure(int i, DiffRawLines structure, {bool augment = true}) {
    final raw = augment ? _augmentWithEofGap(i, structure) : structure;
    final display = <int>[];
    for (var j = 0; j < raw.length; j++) {
      if (raw.kindAt(j) != DiffLineKind.hunkHeader) {
        display.add(j);
      }
    }
    _layouts[i]
      ..structure = raw
      ..gutterMode = _computeGutterMode(raw)
      ..displayToRaw = display
      ..recomputeVisualRows(_colsPerRow, _overflowMode);
    _refreshHeight(i);
  }

  /// Derives the gutter mode from a parsed structure: a side whose line numbers
  /// are entirely absent across the body is dropped. Added files (all rows are
  /// additions) collapse to [DiffGutterMode.newOnly], removed files to
  /// [DiffGutterMode.oldOnly]; any two-sided body keeps [DiffGutterMode.both].
  DiffGutterMode _computeGutterMode(DiffRawLines raw) {
    var hasOld = false;
    var hasNew = false;
    for (var j = 0; j < raw.length; j++) {
      final kind = raw.kindAt(j);
      if (kind == DiffLineKind.hunkHeader || kind == DiffLineKind.expandGap) {
        continue;
      }
      if (raw.oldLines[j] != null) {
        hasOld = true;
      }
      if (raw.newLines[j] != null) {
        hasNew = true;
      }
      if (hasOld && hasNew) {
        return DiffGutterMode.both;
      }
    }
    if (hasNew && !hasOld) {
      return DiffGutterMode.newOnly;
    }
    if (hasOld && !hasNew) {
      return DiffGutterMode.oldOnly;
    }
    return DiffGutterMode.both;
  }

  /// Which line-number columns file [i]'s gutter should show. Derived from the
  /// parsed structure (a side with no line numbers is dropped); before the body
  /// parses, falls back to the file status so the gutter width — and the code
  /// start — stays stable when the structure loads.
  DiffGutterMode gutterModeOf(int i) {
    final cached = _layouts[i].gutterMode;
    if (cached != null) {
      return cached;
    }
    switch (_files[i].status) {
      case PrFileStatus.added:
        return DiffGutterMode.newOnly;
      case PrFileStatus.removed:
        return DiffGutterMode.oldOnly;
      case PrFileStatus.modified:
      case PrFileStatus.renamed:
      case PrFileStatus.unchanged:
        return DiffGutterMode.both;
    }
  }

  /// Maps a display row [displayLine] of file [i] back to its index into the
  /// parsed structure. Identity fallback before the structure is parsed.
  int rawIndexOf(int i, int displayLine) {
    final dtr = _layouts[i].displayToRaw;
    if (displayLine < 0 || displayLine >= dtr.length) {
      return displayLine;
    }
    return dtr[displayLine];
  }

  /// Inverse of [rawIndexOf]: the display row showing structure index
  /// [rawIndex] in file [i], or -1 when that raw row isn't displayed (e.g. a
  /// filtered hunk header).
  int displayLineOfRaw(int i, int rawIndex) {
    final dtr = _layouts[i].displayToRaw;
    for (var d = 0; d < dtr.length; d++) {
      if (dtr[d] == rawIndex) {
        return d;
      }
    }
    return -1;
  }

  /// Appends a trailing "Show end of file" expand gap for modified/renamed
  /// files so the reviewer can pull in the lines below the last hunk. Skipped
  /// for added/removed files (their whole content is already shown) and for
  /// empty/hunk-less structures. The gap is appended last, so existing row
  /// indices — and therefore the worker's per-line tokens — stay aligned.
  DiffRawLines _augmentWithEofGap(int i, DiffRawLines raw) {
    if (raw.length == 0) {
      return raw;
    }
    final status = _files[i].status;
    if (status == PrFileStatus.added || status == PrFileStatus.removed) {
      return raw;
    }
    var maxOld = 0;
    var maxNew = 0;
    var hasHunk = false;
    for (var j = 0; j < raw.length; j++) {
      final kind = raw.kindAt(j);
      if (kind == DiffLineKind.hunkHeader) {
        hasHunk = true;
        continue;
      }
      if (kind == DiffLineKind.expandGap) {
        continue;
      }
      final o = raw.oldLines[j];
      if (o != null && o > maxOld) {
        maxOld = o;
      }
      final n = raw.newLines[j];
      if (n != null && n > maxNew) {
        maxNew = n;
      }
    }
    if (!hasHunk || maxNew == 0) {
      return raw;
    }
    return DiffRawLines(
      kinds: [...raw.kinds, DiffLineKind.expandGap.index],
      contents: [...raw.contents, ''],
      oldLines: [...raw.oldLines, maxOld + 1],
      newLines: [...raw.newLines, maxNew + 1],
      hunkHeaders: [...raw.hunkHeaders, null],
      gapOldEnds: [...raw.gapOldEnds, kEofGapSentinel],
      gapNewEnds: [...raw.gapNewEnds, kEofGapSentinel],
      maxLineChars: raw.maxLineChars,
    );
  }

  /// Toggles or sets file [i]'s expanded state, refreshing its height.
  /// Returns true if the state changed.
  bool setExpanded(int i, {required bool expanded}) {
    if (_layouts[i].expanded == expanded) {
      return false;
    }
    _layouts[i].expanded = expanded;
    _refreshHeight(i);
    return true;
  }

  /// Sets file [i]'s Markdown-preview state, refreshing its height. Returns true
  /// if the state changed.
  bool setPreviewing(int i, {required bool previewing}) {
    if (_layouts[i].previewing == previewing) {
      return false;
    }
    _layouts[i].previewing = previewing;
    _refreshHeight(i);
    return true;
  }

  /// Sets file [i]'s reserved Markdown-preview body height (the measured height
  /// fed back from the hosting slot). Refreshes the file height only when the
  /// file is previewing and the change exceeds a sub-pixel threshold.
  void setPreviewHeight(int i, double height) {
    if ((_layouts[i].previewHeight - height).abs() < 0.5) {
      return;
    }
    _layouts[i].previewHeight = height;
    if (_layouts[i].previewing) {
      _refreshHeight(i);
    }
  }

  /// Replaces file [i]'s inline-comment blocks (already sorted by anchor line
  /// is not required — they are sorted here) and refreshes its height.
  void setCommentBlocks(int i, List<DiffCommentBlock> blocks) {
    final sorted = List<DiffCommentBlock>.of(blocks)
      ..sort((a, b) => a.anchorLine.compareTo(b.anchorLine));
    _layouts[i]
      ..comments = sorted
      ..recomputeComments();
    _refreshHeight(i);
  }

  /// Index of file matching [filename], or -1.
  int indexOfFile(String filename) {
    for (var i = 0; i < _files.length; i++) {
      if (_files[i].filename == filename) {
        return i;
      }
    }
    return -1;
  }
}
