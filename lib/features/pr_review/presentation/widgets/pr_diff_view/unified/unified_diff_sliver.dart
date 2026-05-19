import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_slot.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_structure_store.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_row_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Per-frame visual configuration for the unified diff sliver. Cheap to
/// rebuild; the render object diffs it to decide between repaint and relayout.
@immutable
class UnifiedDiffPaintConfig {
  /// Creates a paint config.
  const UnifiedDiffPaintConfig({
    required this.brightness,
    required this.baseStyle,
    required this.gutterBgColor,
    required this.gutterBorderColor,
    required this.expandGapBgColor,
    required this.expandGapBorderColor,
    required this.expandGapTextColor,
    required this.commentHighlightColor,
    required this.commentHighlightActiveColor,
    required this.revision,
    this.topInset = 0,
    this.overflowMode = DiffOverflowMode.scroll,
    this.searchFile = -1,
    this.searchRawIndex = -1,
    this.splitMode = false,
  });

  /// Active theme brightness (drives colours; baked into cached paragraphs).
  final Brightness brightness;

  /// Base monospace text style.
  final TextStyle baseStyle;

  /// Opaque gutter background.
  final Color gutterBgColor;

  /// Gutter/code divider colour.
  final Color gutterBorderColor;

  /// Expand-gap row colours (the gap rows are widgets now, but the painter
  /// still uses these for any residual fills).
  final Color expandGapBgColor;

  /// Expand-gap border colour.
  final Color expandGapBorderColor;

  /// Expand-gap label colour.
  final Color expandGapTextColor;

  /// Google-Docs-style background drawn over a commented range.
  final Color commentHighlightColor;

  /// Background drawn over the commented range whose thread is focused.
  final Color commentHighlightActiveColor;

  /// Monotonic counter bumped whenever the document's row layout changes.
  final int revision;

  /// Pixels of viewport-top occupied by a pinned ancestor (the tab strip), so
  /// the sticky header pins just below it instead of behind it.
  final double topInset;

  /// Whether long lines wrap or scroll horizontally.
  final DiffOverflowMode overflowMode;

  /// Current search-match file + raw line index to highlight (-1 = none).
  final int searchFile;

  /// Current search-match raw line index (-1 = none).
  final int searchRawIndex;

  /// Side-by-side (split) rendering: deletions/old-numbers on the left half,
  /// additions/new-numbers on the right, context on both.
  final bool splitMode;
}

/// Gutter width used per side in split mode (one line-number column).
const double kDiffSplitGutterWidth = kDiffGutterPillSlot + 44 + 8;

/// A persistent comment highlight to paint over one display row: the display
/// column span `[startCol, endCol)` (a null [endCol] means "to the row's right
/// edge"), drawn in the active colour when its thread is focused.
@immutable
class DiffCommentHighlight {
  /// Creates a highlight descriptor.
  const DiffCommentHighlight({
    required this.startCol,
    this.endCol,
    this.active = false,
  });

  /// First display column (tabs expanded) of the highlight.
  final int startCol;

  /// Exclusive end display column, or null for "to the right edge".
  final int? endCol;

  /// Whether this row's thread is the focused one (darker highlight).
  final bool active;
}

/// Sliver widget hosting the unified diff. Code rows are painted directly on a
/// single canvas; the comparatively rare interactive rows (file headers, gap
/// affordances, comment threads, composer) are lazily-built sparse children,
/// described by an offset-ordered [slots] list.
class UnifiedDiffSliver extends SliverMultiBoxAdaptorWidget {
  /// Creates the sliver. [delegate] builds the widget for `slots[index]`.
  const UnifiedDiffSliver({
    super.key,
    required super.delegate,
    required this.document,
    required this.store,
    required this.config,
    required this.slots,
    this.commentHighlights = const {},
    this.onGutterTap,
    this.onSelectionChanged,
    this.onLayoutModeChanged,
  });

  /// The flat document model.
  final PrDiffDocument document;

  /// Structure + token store (synchronous structure, async colour).
  final DiffStructureStore store;

  /// Visual configuration.
  final UnifiedDiffPaintConfig config;

  /// Offset-ordered sparse children. `slots[i]` is built by `delegate`'s
  /// builder at index `i`.
  final List<DiffSlot> slots;

  /// Per-`(file, displayLine)` comment highlights to paint over code rows.
  final Map<int, Map<int, DiffCommentHighlight>> commentHighlights;

  /// Called when a code row's gutter is tapped: `(fileIndex, rawLineIndex)`.
  final void Function(int file, int rawIndex)? onGutterTap;

  /// Called whenever the text selection changes (start/extend/clear), so a
  /// host overlay can reposition the floating review toolbar.
  final VoidCallback? onSelectionChanged;

  /// Called (post-frame) when the wrap layout changes — a width/mode change
  /// moved per-line offsets, so the host must rebuild its slot list.
  final VoidCallback? onLayoutModeChanged;

  @override
  RenderUnifiedDiffSliver createRenderObject(BuildContext context) {
    final element = context as SliverMultiBoxAdaptorElement;
    return RenderUnifiedDiffSliver(
        childManager: element,
        document: document,
        store: store,
        config: config,
        slots: slots,
      )
      ..onGutterTap = onGutterTap
      ..onSelectionChanged = onSelectionChanged
      ..onLayoutModeChanged = onLayoutModeChanged
      ..commentHighlights = commentHighlights;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderUnifiedDiffSliver renderObject,
  ) {
    renderObject
      ..document = document
      ..store = store
      ..slots = slots
      ..onGutterTap = onGutterTap
      ..onSelectionChanged = onSelectionChanged
      ..onLayoutModeChanged = onLayoutModeChanged
      ..commentHighlights = commentHighlights
      ..config = config;
  }
}

/// Render sliver for the unified diff. See [UnifiedDiffSliver].
class RenderUnifiedDiffSliver extends RenderSliverMultiBoxAdaptor {
  /// Creates the render object.
  RenderUnifiedDiffSliver({
    required super.childManager,
    required PrDiffDocument document,
    required DiffStructureStore store,
    required UnifiedDiffPaintConfig config,
    required List<DiffSlot> slots,
  }) : _document = document,
       _store = store,
       _config = config,
       _slots = slots;

  PrDiffDocument _document;
  DiffStructureStore _store;
  UnifiedDiffPaintConfig _config;
  List<DiffSlot> _slots;

  /// Called when the user taps a code row's gutter to start a line comment:
  /// `(fileIndex, rawLineIndex)`.
  void Function(int file, int rawIndex)? onGutterTap;

  /// Called whenever the selection changes, so a host overlay can reposition
  /// the floating review toolbar.
  VoidCallback? onSelectionChanged;

  /// Called (post-frame) after a width/mode change moved per-line offsets, so
  /// the host can rebuild its slot list against the new geometry.
  VoidCallback? onLayoutModeChanged;

  /// Live horizontal scroll offset (scroll mode). Owned here — not on the
  /// config — so a pan is a cheap [markNeedsPaint] without rebuilding the view
  /// (whose build recomputes comment highlights over every line). The host
  /// overlay reads it back via [horizontalScrollOffset] after each paint.
  double _horizontalScrollOffset = 0;

  /// Current (clamped) horizontal scroll offset, for the host's scrollbar.
  double get horizontalScrollOffset => _effectiveHScroll;

  /// Code columns per visual row resolved from the last layout (wrap mode);
  /// a huge sentinel in scroll mode. Used by hit-testing and the host overlay.
  int _colsPerRow = 1 << 30;

  /// Code columns per visual row from the last layout (see `_colsPerRow`).
  int get colsPerRow => _colsPerRow;

  /// Cross-axis extent captured at the last layout (for the scroll extent).
  double _lastCrossAxisExtent = 0;

  /// Whether a slot-rebuild notification is already scheduled for this frame.
  bool _layoutModeTickScheduled = false;

  Map<int, Map<int, DiffCommentHighlight>> _commentHighlights = const {};

  /// Per-`(file, displayLine)` comment highlights painted under the code text.
  set commentHighlights(Map<int, Map<int, DiffCommentHighlight>> value) {
    _commentHighlights = value;
    markNeedsPaint();
  }

  /// Bumped (post-frame) after every paint (scroll / selection / layout /
  /// colour fade) so a host overlay listening to it can reposition the toolbar,
  /// gutter pill and commenter avatars against fresh, settled geometry.
  final ValueNotifier<int> geometryListenable = ValueNotifier<int>(0);
  bool _geometryTickScheduled = false;

  /// The diff's cross-axis extent on the last paint — the width the code paints
  /// into, *after* any left padding (e.g. the file-tree column). The view uses
  /// `scrollableWidth − this` to find the diff content's global left edge.
  double _contentCrossAxisExtent = 0;

  /// The diff's cross-axis extent on the last paint.
  double get contentCrossAxisExtent => _contentCrossAxisExtent;

  late final TapGestureRecognizer _tapRecognizer = TapGestureRecognizer()
    ..onTap = _handleGutterTap;
  double? _downMain;

  /// Mouse-only drag recognizer for text selection. On desktop, mouse drag is
  /// free for selection (scrolling is wheel/trackpad), so this never fights the
  /// scrollable.
  late final PanGestureRecognizer _selectRecognizer =
      PanGestureRecognizer(supportedDevices: const {PointerDeviceKind.mouse})
        ..onStart = _onSelectStart
        ..onUpdate = _onSelectUpdate
        ..onEnd = _onSelectEnd;

  /// Tap recognizer for the code area: a plain click (no drag) clears any
  /// active text selection. A drag is claimed by `_selectRecognizer`, which
  /// crosses the pan slop and rejects this recognizer — so click clears and
  /// drag selects, without either fighting the other.
  late final TapGestureRecognizer _clearSelectionTapRecognizer =
      TapGestureRecognizer()..onTap = clearSelection;

  /// Character-precise selection anchor/focus as
  /// `(fileIndex, displayLine, displayColumn)` — the column is in display
  /// space (tabs expanded), resolved against `_monoAdvance`.
  (int, int, int)? _selAnchor;
  (int, int, int)? _selFocus;
  double _selDownMain = 0;
  double _selDownCross = 0;
  double _selAccumDy = 0;
  double _selAccumDx = 0;
  bool _selMoved = false;

  /// Monospace advance for the active base style, used to turn a cross-axis x
  /// into a display column (and back, in the painter). Cached; cleared when the
  /// base style changes.
  double? _monoAdvanceCache;
  double get _monoAdvance =>
      _monoAdvanceCache ??= measureMonoAdvanceWidth(_config.baseStyle);

  /// Code area width available for wrapping (gutter + inner padding removed),
  /// per side in split mode. Drives `colsPerRow`.
  double _codeWidthFor(double crossAxisExtent) {
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
  /// Drives the horizontal-scroll extent.
  double _codeViewportWidthFor(double crossAxisExtent) {
    if (_config.splitMode) {
      final double halfW = math.max(0.0, (crossAxisExtent - 1) / 2);
      return math.max(0.0, halfW - kDiffSplitGutterWidth);
    }
    return math.max(0.0, crossAxisExtent - kDiffGutterWidth);
  }

  /// Effective gutter width for file [file] in unified mode. Added/removed files
  /// (and pure renames) carry only one line-number column, so their gutter — and
  /// therefore the code start — collapses to [kDiffSingleGutterWidth]. Split mode
  /// keeps [kDiffGutterWidth] here: its per-side hit-test paths predate the
  /// collapse and char selection is disabled, so the value is unused there.
  double gutterWidthOf(int file) {
    if (_config.splitMode) {
      return kDiffGutterWidth;
    }
    return _document.gutterModeOf(file) == DiffGutterMode.both
        ? kDiffGutterWidth
        : kDiffSingleGutterWidth;
  }

  /// Maximum horizontal scroll offset in scroll mode (0 in wrap mode or when
  /// the widest line already fits).
  double get maxHorizontalScrollExtent {
    if (_config.overflowMode != DiffOverflowMode.scroll) {
      return 0;
    }
    final int cols = _document.maxDisplayColsOfExpanded();
    if (cols <= 0) {
      return 0;
    }
    final double contentWidth =
        cols * _monoAdvance + kDiffCodePadLeft + kDiffCodePadRight;
    return math.max(
      0.0,
      contentWidth - _codeViewportWidthFor(_lastCrossAxisExtent),
    );
  }

  /// The owned offset, clamped to the live content extent (so a stale offset
  /// from a since-widened viewport can never overscroll).
  double get _effectiveHScroll =>
      _horizontalScrollOffset.clamp(0.0, maxHorizontalScrollExtent);

  /// Pans the code to [offset] (clamped). Used by the wheel handler and the
  /// host's horizontal scrollbar; a paint-only update.
  void applyHorizontalPan(double offset) {
    final double clamped = offset.clamp(0.0, maxHorizontalScrollExtent);
    if (clamped == _horizontalScrollOffset) {
      return;
    }
    _horizontalScrollOffset = clamped;
    markNeedsPaint();
  }

  void _scheduleLayoutModeTick() {
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

  /// Whether there is an active selection (for the view's copy shortcut).
  bool get hasSelection => _selAnchor != null && _selFocus != null;

  /// Raw source text of the current selection, or null if none. Assembled from
  /// the document model so it is correct across files (and rows the canvas
  /// never painted), marker-free, with real tabs — and sliced at the precise
  /// start/end columns.
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

  // ── Geometry exposure for the host review overlay ───────────────────────
  // The review overlay (floating toolbar, gutter pill, commenter avatars) lives
  // in the root Overlay and positions itself in GLOBAL screen coordinates. A
  // RenderSliver has no localToGlobal and its paint transform through a
  // SliverMainAxisGroup is awkward, so the *view* does the screen mapping from
  // the enclosing scrollable's box + scroll offset; the sliver only exposes the
  // document-space primitives the view needs.

  /// Monospace advance of the active base style (display column → pixels).
  double get monoAdvanceWidth => _monoAdvance;

  /// Scroll extent of the slivers before this one (PR header, tab strip,
  /// toolbar) — so the view can turn a document offset into an absolute scroll
  /// position.
  double get precedingScrollExtent => _precedingScrollExtent;

  /// Active selection as a normalised range in display space, or null. Columns
  /// are clamped display columns; startLine/endLine are display lines in the
  /// focus file (selection never spans files for anchoring — the focus wins).
  ({int file, int startLine, int startCol, int endLine, int endCol})?
  selectionRange() {
    final a = _selAnchor;
    final f = _selFocus;
    if (a == null || f == null) {
      return null;
    }
    // Anchor a comment to the focus file; clamp the range to it.
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
  (int, int, int)? _cellAt(double mainAxisPosition, double crossAxisPosition) {
    final double scrollPos = constraints.scrollOffset + mainAxisPosition;
    if (scrollPos < 0 || _document.totalExtent <= 0) {
      return null;
    }
    final clamped = scrollPos.clamp(0.0, _document.totalExtent - 0.001);
    final int f = _document.fileAtOffset(clamped);
    if (_document.isPreviewing(f)) {
      // No selectable code rows over a Markdown preview body; a drag crossing
      // into one resolves to no cell (rather than a hidden source line).
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
    return (f, line, _columnAt(crossAxisPosition, f, line, subRow));
  }

  /// Display column under cross-axis x [crossAxisPosition] on `(file, line)`,
  /// clamped to that line's rendered width. The gutter is pinned, so code
  /// starts at `gutterWidthOf(file) + kDiffCodePadLeft` (unified mode — a
  /// collapsed-gutter file starts further left). [subRow] is the wrapped sub-row
  /// under the cursor (0 in scroll mode); the horizontal scroll offset is folded
  /// in for scroll mode. Only one of the two terms is ever non-zero (the modes
  /// are mutually exclusive).
  int _columnAt(double crossAxisPosition, int file, int line, int subRow) {
    final double codeStartX = gutterWidthOf(file) + kDiffCodePadLeft;
    final double local = crossAxisPosition - codeStartX + _effectiveHScroll;
    final int colInRow = local <= 0 ? 0 : (local / _monoAdvance).round();
    final int base = _config.overflowMode == DiffOverflowMode.wrap
        ? subRow * _colsPerRow
        : 0;
    return (base + colInRow).clamp(0, _document.displayWidthOf(file, line));
  }

  void _onSelectStart(DragStartDetails details) {
    final anchor = _cellAt(_selDownMain, _selDownCross);
    _selAnchor = anchor;
    _selFocus = anchor;
    _selAccumDy = 0;
    _selAccumDx = 0;
    _selMoved = false;
  }

  void _onSelectUpdate(DragUpdateDetails details) {
    _selAccumDy += details.delta.dy;
    _selAccumDx += details.delta.dx;
    if (!_selMoved && _selAccumDy.abs() < 2 && _selAccumDx.abs() < 2) {
      return; // ignore micro-jitter so a click doesn't select
    }
    _selMoved = true;
    _selFocus = _cellAt(
      _selDownMain + _selAccumDy,
      _selDownCross + _selAccumDx,
    );
    markNeedsPaint();
    onSelectionChanged?.call();
  }

  void _onSelectEnd(DragEndDetails details) {
    if (!_selMoved) {
      clearSelection(); // a plain click clears any prior selection
    } else {
      onSelectionChanged?.call();
    }
  }

  /// Display-column span `[start, end)` to highlight on `(file, displayLine)`,
  /// or `(null, null)` if the row is outside the selection. A null `end` means
  /// "to the row's right edge" (interior fully selected).
  (int?, int?) _selectionColsFor(int file, int displayLine) {
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
      return (sc, null); // from sc to the right edge
    }
    if (atEnd) {
      return (0, ec); // from the start to ec
    }
    return (0, null); // whole interior
  }

  /// Persistent per-line layout cache (survives config changes).
  final UnifiedLineCache lineCache = UnifiedLineCache();

  /// Scroll extent of all slivers before this one (PR header, tab strip,
  /// toolbar). Captured each layout for jump-to-file.
  double _precedingScrollExtent = 0;

  /// Absolute scroll offset (in the outer scrollable) of file [index]'s top.
  double scrollOffsetForFile(int index) =>
      _precedingScrollExtent + _document.offsetOfFile(index);

  /// Scroll offset that reveals file [index] with its header docked just below
  /// the pinned tab strip. [scrollOffsetForFile] places the header top at
  /// viewport y=0, which hides the first topInset px of content behind the
  /// floating sticky header.
  double revealOffsetForFile(int index) =>
      math.max(0, scrollOffsetForFile(index) - _config.topInset);

  Set<int> _lastTokenSet = const {};

  /// Sticky-header state, recomputed each layout.
  int _stickyFile = -1;
  int _stickySlotIndex = -1;
  double _stickyHeaderTop = 0;

  /// Whether the sticky header is currently pinned (docked under the tabs)
  /// rather than at its natural scroll position. When pinned, its top border
  /// is clipped so it sits flush under the tab strip.
  bool _stickyPinned = false;

  /// Drops every cached paragraph — called after a gap expand shifts a file's
  /// row indices, or after a refresh replaces the file set/order, so stale
  /// `(file, line)` entries can't be reused.
  ///
  /// Also clears `_lastTokenSet` and relayouts: the store's syntax colour was
  /// dropped alongside, and the visible-file index set is often unchanged after
  /// a refresh — without resetting the gate the next layout would skip
  /// re-requesting tokens, leaving visible files stuck as plain text until the
  /// user scrolls. (Files whose tokens are still resident — e.g. a gap expand
  /// that spliced them — are skipped inside `requestTokens`, so no needless
  /// re-fetch or colour flash.)
  void clearLineCache() {
    lineCache.clear();
    _lastTokenSet = const {};
    markNeedsLayout();
  }

  /// The flat document model.
  PrDiffDocument get document => _document;
  set document(PrDiffDocument value) {
    if (identical(_document, value)) {
      return;
    }
    _document = value;
    markNeedsLayout();
  }

  /// Structure + token store.
  DiffStructureStore get store => _store;
  set store(DiffStructureStore value) {
    if (identical(_store, value)) {
      return;
    }
    if (attached) {
      _store.repaint.removeListener(markNeedsPaint);
      value.repaint.addListener(markNeedsPaint);
    }
    _store = value;
    markNeedsLayout();
  }

  /// Offset-ordered sparse child descriptors.
  List<DiffSlot> get slots => _slots;
  set slots(List<DiffSlot> value) {
    _slots = value;
    markNeedsLayout();
  }

  /// Visual configuration.
  UnifiedDiffPaintConfig get config => _config;
  set config(UnifiedDiffPaintConfig value) {
    final old = _config;
    _config = value;
    if (old.brightness != value.brightness ||
        old.baseStyle != value.baseStyle ||
        old.overflowMode != value.overflowMode) {
      // Cached paragraphs were laid out at the old style / wrap width.
      lineCache.clear();
    }
    if (old.baseStyle != value.baseStyle) {
      _monoAdvanceCache = null;
    }
    if (old.overflowMode != value.overflowMode) {
      // Switching modes resets any horizontal pan (wrap has no h-scroll).
      _horizontalScrollOffset = 0;
    }
    markNeedsLayout();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _store.repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _store.repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    _selectRecognizer.dispose();
    _clearSelectionTapRecognizer.dispose();
    geometryListenable.dispose();
    super.dispose();
  }

  /// Resolves the context/addition/deletion code row at [mainAxisPosition]
  /// (any cross-axis x), or null if that Y isn't on a code row.
  (int, int)? _codeRowAt(double mainAxisPosition) {
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
      return null; // header row
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

  @override
  bool hitTestSelf({
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    // Capture pointers over code rows: gutter taps create line comments;
    // mouse drags in the code area select text. Non-mouse drags are rejected
    // by the mouse-only select recognizer, so scrolling still works.
    if (_codeRowAt(mainAxisPosition) != null) {
      return true;
    }
    // In horizontal-scroll mode, also capture (for the wheel handler) anywhere
    // over the diff so a horizontal swipe scrolls the code even off a row.
    return _config.overflowMode == DiffOverflowMode.scroll &&
        maxHorizontalScrollExtent > 0;
  }

  @override
  void handleEvent(PointerEvent event, SliverHitTestEntry entry) {
    if (event is PointerScrollEvent) {
      _handlePointerScroll(event);
      return;
    }
    if (event is! PointerDownEvent) {
      return;
    }
    final hit = _codeRowAt(entry.mainAxisPosition);
    if (hit == null) {
      return;
    }
    _downMain = entry.mainAxisPosition;
    if (entry.crossAxisPosition < gutterWidthOf(hit.$1)) {
      _tapRecognizer.addPointer(event); // gutter → line comment
    } else {
      _selDownMain = entry.mainAxisPosition;
      _selDownCross = entry.crossAxisPosition;
      _selectRecognizer.addPointer(event); // code area → mouse-drag selection
      _clearSelectionTapRecognizer.addPointer(event); // click → clear selection
    }
  }

  void _handleGutterTap() {
    final m = _downMain;
    if (m == null) {
      return;
    }
    clearSelection();
    final hit = _codeRowAt(m);
    if (hit != null && onGutterTap != null) {
      onGutterTap!(hit.$1, hit.$2);
    }
  }

  /// Pans the code horizontally on a trackpad horizontal swipe (or shift+wheel)
  /// in scroll mode. Pure-vertical scrolls are left untouched so the enclosing
  /// vertical scrollable still flings. The scroll signal is claimed via the
  /// resolver only when there's a horizontal component, so vertical wins
  /// otherwise.
  void _handlePointerScroll(PointerScrollEvent event) {
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
    // Consume the scroll signal (deepest registrant wins the resolver) so the
    // enclosing vertical scrollable doesn't also act on it.
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      applyHorizontalPan(next);
    });
  }

  int _laidOutCount() {
    var count = 0;
    var child = firstChild;
    while (child != null) {
      count++;
      child = childAfter(child);
    }
    return count;
  }

  void _setChildOffset(RenderBox child, int index) {
    (child.parentData! as SliverMultiBoxAdaptorParentData).layoutOffset =
        _slots[index].offset;
  }

  BoxConstraints _constraintsFor(int index, double crossAxisExtent) {
    final slot = _slots[index];
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
        // Loose height so the block self-sizes; its measured height is fed
        // back into the document for the next layout.
        return BoxConstraints(
          minWidth: crossAxisExtent,
          maxWidth: crossAxisExtent,
          maxHeight: double.infinity,
        );
    }
  }

  /// First slot index whose `offset >= value` (lower bound).
  int _firstSlotAtOrAfter(double value) {
    var lo = 0;
    var hi = _slots.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_slots[mid].offset < value) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Visible slot range `[first, last]` intersecting `[start, end]`, or null.
  ({int first, int last})? _visibleSlotRange(double start, double end) {
    if (_slots.isEmpty) {
      return null;
    }
    // Largest slot index with offset <= start; include it if it extends past
    // start (a tall comment straddling the top edge).
    final atOrAfterStart = _firstSlotAtOrAfter(start);
    var first = atOrAfterStart;
    if (atOrAfterStart > 0) {
      final prev = _slots[atOrAfterStart - 1];
      if (prev.offset + prev.height > start) {
        first = atOrAfterStart - 1;
      }
    }
    // Last slot with offset < end.
    final last = _firstSlotAtOrAfter(end) - 1;
    if (last < first) {
      return null;
    }
    return (first: first, last: math.min(last, _slots.length - 1));
  }

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    _precedingScrollExtent = constraints.precedingScrollExtent;

    final double crossAxisExtent = constraints.crossAxisExtent;
    _lastCrossAxisExtent = crossAxisExtent;

    // Resolve wrap columns from the live viewport width and push the layout
    // mode into the document BEFORE any offset / extent / slot math reads it.
    // A change moved per-line heights, so clear the paragraph cache (laid out
    // at the old width) and ask the host to rebuild slot offsets (post-frame —
    // we can't setState during layout).
    final double codeWidth = _codeWidthFor(crossAxisExtent);
    final int colsPerRow = _config.overflowMode == DiffOverflowMode.wrap
        ? math.max(1, (codeWidth / _monoAdvance).floor())
        : (1 << 30);
    _colsPerRow = colsPerRow;
    if (_document.setLayoutMode(_config.overflowMode, colsPerRow)) {
      lineCache.clear();
      _scheduleLayoutModeTick();
    }

    final double total = _document.totalExtent;

    if (_slots.isEmpty || _document.fileCount == 0) {
      collectGarbage(_laidOutCount(), 0);
      geometry = total > 0
          ? SliverGeometry(
              scrollExtent: total,
              maxPaintExtent: total,
              paintExtent: calculatePaintOffset(
                constraints,
                from: 0,
                to: total,
              ),
            )
          : SliverGeometry.zero;
      childManager.didFinishLayout();
      return;
    }

    final double cacheStart = math.max(
      0,
      constraints.scrollOffset + constraints.cacheOrigin,
    );
    final double cacheEnd = math.min(
      total,
      cacheStart + constraints.remainingCacheExtent,
    );

    // Ensure structure for the files whose body intersects the cache window
    // (needed to paint their code rows). Cache hits in steady state.
    final int firstFile = _document.fileAtOffset(cacheStart);
    final int lastFile = _document.fileAtOffset(
      math.min(total - 0.0001, math.max(0, cacheEnd)),
    );
    for (var i = firstFile; i <= lastFile; i++) {
      if (_document.isExpanded(i) && _document.structureOf(i) == null) {
        _store.ensureStructure(i);
      }
    }

    // Compute sticky state before layout so the sticky file's header slot can
    // be force-included in the laid-out range even when scrolled deep into the
    // file (its natural offset is above the viewport).
    _computeSticky(constraints);

    final range = _visibleSlotRange(cacheStart, cacheEnd);
    var layoutFirst = range?.first ?? _stickySlotIndex;
    var layoutLast = range?.last ?? _stickySlotIndex;
    if (_stickySlotIndex >= 0) {
      if (layoutFirst < 0 || _stickySlotIndex < layoutFirst) {
        layoutFirst = _stickySlotIndex;
      }
      if (layoutLast < 0) {
        layoutLast = _stickySlotIndex;
      }
    }
    if (layoutFirst < 0 || layoutLast < layoutFirst) {
      collectGarbage(_laidOutCount(), 0);
    } else {
      _layoutSlotRange(layoutFirst, layoutLast, crossAxisExtent);
    }

    // Drive colour fetching for visible expanded files.
    final tokenSet = <int>{};
    for (var i = firstFile; i <= lastFile; i++) {
      if (_document.isExpanded(i)) {
        tokenSet.add(i);
      }
    }
    if (!setEquals(tokenSet, _lastTokenSet)) {
      _lastTokenSet = tokenSet;
      _store.requestTokens(tokenSet);
    }

    geometry = SliverGeometry(
      scrollExtent: total,
      paintExtent: calculatePaintOffset(constraints, from: 0, to: total),
      cacheExtent: calculateCacheOffset(constraints, from: 0, to: total),
      maxPaintExtent: total,
      hasVisualOverflow: true,
    );

    childManager.didFinishLayout();
  }

  void _layoutSlotRange(int first, int last, double crossAxisExtent) {
    // Drop everything if the kept range is disjoint from current children
    // (big scrollbar jump) so the jump stays O(visible), not O(distance).
    if (firstChild != null) {
      final curFirst = indexOf(firstChild!);
      final curLast = indexOf(lastChild!);
      if (curLast < first || curFirst > last) {
        collectGarbage(_laidOutCount(), 0);
      }
    }

    if (firstChild == null) {
      if (!addInitialChild(index: first, layoutOffset: _slots[first].offset)) {
        return;
      }
      firstChild!.layout(
        _constraintsFor(first, crossAxisExtent),
        parentUsesSize: true,
      );
      _setChildOffset(firstChild!, first);
    }

    while (indexOf(firstChild!) > first) {
      final leading = insertAndLayoutLeadingChild(
        _constraintsFor(indexOf(firstChild!) - 1, crossAxisExtent),
        parentUsesSize: true,
      );
      if (leading == null) {
        break;
      }
      _setChildOffset(leading, indexOf(leading));
    }

    var child = firstChild!;
    while (true) {
      final idx = indexOf(child);
      child.layout(_constraintsFor(idx, crossAxisExtent), parentUsesSize: true);
      _setChildOffset(child, idx);
      if (idx >= last) {
        break;
      }
      // Insert when the chain ends (tail) *or* skips an index — a slot inserted
      // mid-list (e.g. opening a composer) relocates the trailing children, so
      // `childAfter` returns a non-contiguous index and the new slot's child
      // must be built into the gap. Without the index check it is skipped: its
      // reserved height shows as white space with nothing painted in it.
      var next = childAfter(child);
      if (next == null || indexOf(next) != idx + 1) {
        next = insertAndLayoutChild(
          _constraintsFor(idx + 1, crossAxisExtent),
          after: child,
          parentUsesSize: true,
        );
        if (next == null) {
          break;
        }
      }
      _setChildOffset(next, indexOf(next));
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

  /// Header slot index for [file] (the slot at the file's top offset), or -1.
  int _headerSlotOf(int file) {
    if (file < 0 || file >= _document.fileCount) {
      return -1;
    }
    final idx = _firstSlotAtOrAfter(_document.offsetOfFile(file));
    return (idx < _slots.length &&
            _slots[idx].fileIndex == file &&
            _slots[idx].kind == DiffSlotKind.header)
        ? idx
        : -1;
  }

  void _computeSticky(SliverConstraints constraints) {
    // Conservative candidate (the file at the sliver's scroll top) so its
    // header slot is force-included in the laid-out range. paint() refines
    // this to the file at the tab line once it knows the screen origin —
    // which is always >= this file, so its slot is still laid out.
    _stickyFile = _document.fileAtOffset(constraints.scrollOffset);
    _stickySlotIndex = _headerSlotOf(_stickyFile);
    // _stickyHeaderTop is computed in paint() (needs the viewport paint origin).
  }

  /// Computes the sticky header's main-axis offset in paint, where [originY]
  /// is the sliver's screen-space paint origin in viewport coordinates. Because
  /// this sliver is a repaint boundary, the `offset` passed to paint() is
  /// `Offset.zero` and the real position lives on its OffsetLayer — paint()
  /// reads it from there and passes it here. The header pins just below the
  /// full-height pinned tab strip ([UnifiedDiffPaintConfig.topInset]) so it
  /// never slides behind it, and is pushed up by the next file's header during
  /// handoff.
  double _stickyMainAxis(double originY) {
    if (_stickySlotIndex < 0) {
      _stickyPinned = false;
      return 0;
    }
    final double scrollOffset = constraints.scrollOffset;
    final double topInset = _config.topInset;
    final double naturalScreenY =
        originY + (_document.offsetOfFile(_stickyFile) - scrollOffset);
    if (naturalScreenY >= topInset) {
      _stickyPinned = false;
      return naturalScreenY - originY; // not pinned — natural position
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

  @override
  double childMainAxisPosition(RenderBox child) {
    if (indexOf(child) == _stickySlotIndex) {
      return _stickyHeaderTop;
    }
    return childScrollOffset(child)! - constraints.scrollOffset;
  }

  @override
  double childCrossAxisPosition(RenderBox child) => 0;

  @override
  void paint(PaintingContext context, Offset offset) {
    final SliverGeometry? g = geometry;
    if (_document.fileCount == 0 || g == null || g.paintExtent <= 0) {
      return;
    }
    final SliverConstraints constraints = this.constraints;
    final double scrollOffset = constraints.scrollOffset;
    final double crossAxisExtent = constraints.crossAxisExtent;
    final double bandTop = scrollOffset;
    final double bandBottom = scrollOffset + constraints.remainingPaintExtent;

    final Canvas canvas = context.canvas;
    final double paintH = constraints.remainingPaintExtent;
    _contentCrossAxisExtent = crossAxisExtent;

    if (_config.splitMode) {
      const double divider = 1;
      final double halfW = math.max(0, (crossAxisExtent - divider) / 2);
      final leftPainter = _makeRowPainter(
        gutterWidth: kDiffSplitGutterWidth,
        hideOldGutter: false,
        hideNewGutter: true,
      );
      final rightPainter = _makeRowPainter(
        gutterWidth: kDiffSplitGutterWidth,
        hideOldGutter: true,
        hideNewGutter: false,
      );
      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(offset.dx, offset.dy, halfW, paintH))
        ..translate(offset.dx, offset.dy);
      _paintCode(
        canvas,
        (_) => leftPainter,
        scrollOffset,
        bandTop,
        bandBottom,
        halfW,
        skipKind: DiffLineKind.addition,
      );
      canvas
        ..restore()
        ..save()
        ..clipRect(
          Rect.fromLTWH(offset.dx + halfW + divider, offset.dy, halfW, paintH),
        )
        ..translate(offset.dx + halfW + divider, offset.dy);
      _paintCode(
        canvas,
        (_) => rightPainter,
        scrollOffset,
        bandTop,
        bandBottom,
        halfW,
        skipKind: DiffLineKind.deletion,
      );
      canvas
        ..restore()
        ..drawLine(
          Offset(offset.dx + halfW, offset.dy),
          Offset(offset.dx + halfW, offset.dy + paintH),
          Paint()
            ..color = _config.gutterBorderColor
            ..strokeWidth = divider,
        );
      leftPainter.dispose();
      rightPainter.dispose();
    } else {
      // Most files show both line-number columns. Added/removed files (one side
      // has no numbers) collapse to a single column with a narrower gutter, so
      // their code starts further left. Build each variant lazily and pick per
      // file; the shared line cache is gutter-independent, so it's reused safely.
      final fullPainter = _makeRowPainter(
        gutterWidth: kDiffGutterWidth,
        hideOldGutter: false,
        hideNewGutter: false,
      );
      UnifiedRowPainter? newOnlyPainter;
      UnifiedRowPainter? oldOnlyPainter;
      UnifiedRowPainter painterFor(int file) {
        switch (_document.gutterModeOf(file)) {
          case DiffGutterMode.both:
            return fullPainter;
          case DiffGutterMode.newOnly:
            return newOnlyPainter ??= _makeRowPainter(
              gutterWidth: kDiffSingleGutterWidth,
              hideOldGutter: true,
              hideNewGutter: false,
            );
          case DiffGutterMode.oldOnly:
            return oldOnlyPainter ??= _makeRowPainter(
              gutterWidth: kDiffSingleGutterWidth,
              hideOldGutter: false,
              hideNewGutter: true,
            );
        }
      }

      canvas
        ..save()
        ..clipRect(offset & Size(crossAxisExtent, paintH))
        ..translate(offset.dx, offset.dy);
      _paintCode(
        canvas,
        painterFor,
        scrollOffset,
        bandTop,
        bandBottom,
        crossAxisExtent,
      );
      canvas.restore();
      fullPainter.dispose();
      newOnlyPainter?.dispose();
      oldOnlyPainter?.dispose();
    }

    // The sticky math runs in viewport coordinates and needs this sliver's true
    // screen origin. But the sliver is a repaint boundary, so the `offset`
    // passed to paint() is always Offset.zero — the real viewport position is
    // carried by its OffsetLayer. Read it from there (fall back to offset.dy if
    // there's no OffsetLayer yet). Using offset.dy directly would peg the origin
    // at 0 and force the first file's header to pin a topInset-tall band below
    // the content's actual top.
    final Layer? selfLayer = layer;
    final double originY = selfLayer is OffsetLayer
        ? selfLayer.offset.dy
        : offset.dy;

    // Now that we know the sliver's screen origin, refine the sticky file to the
    // one occupying the tab line (screen y = topInset). When the pinned tab
    // strip overlaps the sliver (originY < topInset) the file at the *scroll*
    // top sits behind the strip; the visually-topmost file is `topInset -
    // originY` further down. Its header slot is >= the layout candidate, so it's
    // already laid out.
    final double tabLineScroll =
        scrollOffset + math.max(0.0, _config.topInset - originY);
    _stickyFile = _document.fileAtOffset(tabLineScroll);
    _stickySlotIndex = _headerSlotOf(_stickyFile);
    _stickyHeaderTop = _stickyMainAxis(originY);

    // Paint slot children on top of the code. Non-sticky first, then the
    // pinned sticky header last so it overlays everything.
    RenderBox? hc = firstChild;
    RenderBox? stickyChild;
    while (hc != null) {
      if (indexOf(hc) == _stickySlotIndex) {
        stickyChild = hc;
      } else {
        final double mainPos = childMainAxisPosition(hc);
        if (mainPos + paintExtentOf(hc) > 0 &&
            mainPos < constraints.remainingPaintExtent) {
          context.paintChild(hc, offset + Offset(0, mainPos));
        }
      }
      hc = childAfter(hc);
    }
    if (stickyChild != null) {
      final double pos = childMainAxisPosition(stickyChild);
      if (_stickyPinned) {
        // Hide the top border so the docked header sits flush under the tabs.
        final RenderBox sc = stickyChild;
        context.pushClipRect(
          false,
          offset,
          Rect.fromLTWH(0, pos + 1, crossAxisExtent, paintExtentOf(sc) - 1),
          (ctx, off) => ctx.paintChild(sc, off + Offset(0, pos)),
        );
      } else {
        context.paintChild(stickyChild, offset + Offset(0, pos));
      }
    }

    // Nudge the review overlay to reposition against the new geometry. Defer to
    // a post-frame callback: notifying during paint would have the overlay read
    // geometry one frame stale, and could fire mid-paint. Coalesced via a flag.
    if (!_geometryTickScheduled) {
      _geometryTickScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _geometryTickScheduled = false;
        if (attached) {
          geometryListenable.value++;
        }
      });
    }
  }

  UnifiedRowPainter _makeRowPainter({
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
    );
  }

  /// Paints the visible code rows of every expanded file in `[bandTop, bandBottom]`
  /// using the painter [painterFor] returns for each file index — unified mode
  /// hands collapsed-gutter files (added/removed) a single-column painter, while
  /// split mode returns the same per-side painter for every file. When [skipKind]
  /// is set, rows of that kind are left blank (used for per-side filtering in
  /// split mode). The canvas is assumed to be translated to the column's origin
  /// already.
  void _paintCode(
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
      // Previewing files render their body as a hosted Markdown slot, not code
      // rows — skip painting them here.
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
              // Gap rows are hosted as widgets; skipKind hides the other side.
              if (kind == DiffLineKind.expandGap || kind == skipKind) {
                continue;
              }
              final double y =
                  _document.offsetOfLine(f, displayLine) - scrollOffset;
              final bool isSearchHit =
                  _config.searchFile == f && _config.searchRawIndex == rawIndex;
              // Char-precise highlight only in unified mode — the column origin
              // assumes the single unified gutter; split's two columns would
              // mis-place it.
              final (int?, int?) sel = _config.splitMode
                  ? (null, null)
                  : _selectionColsFor(f, displayLine);
              final hl = _config.splitMode
                  ? null
                  : _commentHighlights[f]?[displayLine];
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
                commentActive: hl?.active ?? false,
              );
            }
          }
        }
      }
      f++;
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    RenderBox? child = lastChild;
    while (child != null) {
      if (hitTestBoxChild(
        BoxHitTestResult.wrap(result),
        child,
        mainAxisPosition: mainAxisPosition,
        crossAxisPosition: crossAxisPosition,
      )) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    applyPaintTransformForBoxChild(child as RenderBox, transform);
  }
}
