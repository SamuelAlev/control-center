import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_goto.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_slot.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_structure_store.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_config.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_row_painter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

part 'unified_diff_sliver_input.dart';
part 'unified_diff_sliver_painting.dart';

/// Per-layout budget for prefetching structure outside the paint window.
/// On-screen files always parse (they have to paint); cache-window files
/// wait for the next frame once this is spent so a tab click stays under
/// the 150ms interaction budget.
const int _kStructureParseBudgetMs = 8;

/// How far a click series snaps the selection. A plain drag stays on
/// characters; the second click in a series grabs a word and the third
/// grabs the row, then a drag extends by that same unit.
enum _DiffSelGranularity { character, word, line }

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
    this.onCommentTap,
    this.hoveredCommentGroup,
    this.onSelectionChanged,
    this.onLayoutModeChanged,
    this.pinnedFileListenable,
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

  /// Called when a code row carrying a comment highlight is clicked, with that
  /// highlight's [DiffCommentHighlight.groupId].
  final void Function(String groupId)? onCommentTap;

  /// Conversation whose rows are currently hovered, drawn in the active colour.
  /// Set through the render object (paint-only) so hover never rebuilds the
  /// view — recomputing every line's highlight per pointer-move is what made
  /// the old hover path unaffordable.
  final String? hoveredCommentGroup;

  /// Called whenever the text selection changes (start/extend/clear), so a
  /// host overlay can reposition the floating review toolbar.
  final VoidCallback? onSelectionChanged;

  /// Called (post-frame) when layout geometry moved under the host's slot
  /// list — a width/mode change moved per-line offsets, or a lazy structure
  /// parse replaced estimated file heights — so the host must rebuild it.
  final VoidCallback? onLayoutModeChanged;

  /// Host-owned notifier updated (post-frame) with the file index whose header
  /// is currently docked (pinned), or null when none is. The host's header
  /// builder listens to this and drops the docked header's own top border so
  /// it never doubles with the line above the pinned position — mirroring the
  /// first file's flush-under-toolbar contract.
  final ValueNotifier<int?>? pinnedFileListenable;

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
      ..onCommentTap = onCommentTap
      ..onSelectionChanged = onSelectionChanged
      ..onLayoutModeChanged = onLayoutModeChanged
      ..commentHighlights = commentHighlights
      ..hoveredCommentGroup = hoveredCommentGroup
      ..pinnedFileListenable = pinnedFileListenable;
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
      ..onCommentTap = onCommentTap
      ..onSelectionChanged = onSelectionChanged
      ..onLayoutModeChanged = onLayoutModeChanged
      ..commentHighlights = commentHighlights
      ..hoveredCommentGroup = hoveredCommentGroup
      ..pinnedFileListenable = pinnedFileListenable
      ..config = config;
  }
}

/// Render sliver for the unified diff. See [UnifiedDiffSliver].
class RenderUnifiedDiffSliver extends RenderSliverMultiBoxAdaptor
    implements MouseTrackerAnnotation {
  /// Creates the render object.
  RenderUnifiedDiffSliver({
    required super.childManager,
    required this._document,
    required this._store,
    required this._config,
    required this._slots,
  });

  PrDiffDocument _document;
  DiffStructureStore _store;
  UnifiedDiffPaintConfig _config;
  List<DiffSlot> _slots;

  /// Called when the user taps a code row's gutter to start a line comment:
  /// `(fileIndex, rawLineIndex)`.
  void Function(int file, int rawIndex)? onGutterTap;

  /// Called when a highlighted (commented) code row is clicked, with the
  /// conversation's id.
  void Function(String groupId)? onCommentTap;

  /// Called whenever the selection changes, so a host overlay can reposition
  /// the floating review toolbar.
  VoidCallback? onSelectionChanged;

  /// Called (post-frame) after a width/mode change moved per-line offsets, or
  /// a lazy structure parse moved file heights, so the host can rebuild its
  /// slot list against the new geometry.
  VoidCallback? onLayoutModeChanged;

  /// Host-owned notifier: the file whose header is currently docked (pinned),
  /// or null. Updated post-frame alongside [geometryListenable].
  ValueNotifier<int?>? pinnedFileListenable;

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

  /// Whether a follow-up layout is already scheduled to finish a deferred
  /// cache-window structure parse.
  bool _deferredParseScheduled = false;

  Map<int, Map<int, DiffCommentHighlight>> _commentHighlights = const {};

  /// Per-`(file, displayLine)` comment highlights painted under the code text.
  set commentHighlights(Map<int, Map<int, DiffCommentHighlight>> value) {
    _commentHighlights = value;
    markNeedsPaint();
  }

  String? _hoveredCommentGroup;

  /// The hovered conversation, or null. A paint-only property: every row of the
  /// conversation brightens together, with no rebuild and no relayout.
  set hoveredCommentGroup(String? value) {
    if (_hoveredCommentGroup == value) {
      return;
    }
    _hoveredCommentGroup = value;
    markNeedsPaint();
  }

  /// The conversation covering display row [displayLine] of [file], or null.
  String? commentGroupAt(int file, int displayLine) =>
      _commentHighlights[file]?[displayLine]?.groupId;

  /// The conversation covering the row at main-axis position [mainAxisPosition]
  /// (sliver-local), or null. Feeds the host overlay's hover tracking.
  String? commentGroupAtMain(double mainAxisPosition) {
    final row = displayRowAt(mainAxisPosition);
    return row == null ? null : commentGroupAt(row.$1, row.$2);
  }

  DiffInteractiveSpan? _gotoUnderline;
  DiffGotoLanding? _gotoLanding;

  /// The Cmd/Ctrl+hovered interactive span, or null. Paint-only.
  set gotoUnderline(DiffInteractiveSpan? value) {
    if (_gotoUnderline == value) {
      return;
    }
    _gotoUnderline = value;
    markNeedsPaint();
  }

  /// Transient identifier flash after a go-to jump. Paint-only.
  set gotoLanding(DiffGotoLanding? value) {
    if (_gotoLanding == value) {
      return;
    }
    _gotoLanding = value;
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

  /// Mouse selection: drag selects characters, a double-click selects the
  /// word, a triple-click selects the row. One recognizer so the click count
  /// and the drag share a pointer. Mouse only — touch stays with the
  /// scrollable.
  late final TapAndPanGestureRecognizer _selectRecognizer =
      TapAndPanGestureRecognizer(
          supportedDevices: const {PointerDeviceKind.mouse},
        )
        ..dragStartBehavior = DragStartBehavior.down
        ..onTapDown = _handleCodeTapDown
        ..onTapUp = _handleCodeTapUp
        ..onDragStart = _handleSelectStart
        ..onDragUpdate = _handleSelectUpdate
        ..onDragEnd = _handleSelectEnd;

  /// Character-precise selection anchor/focus as
  /// `(fileIndex, displayLine, displayColumn)` — the column is in display
  /// space (tabs expanded), resolved against `_monoAdvance`.
  (int, int, int)? _selAnchor;
  (int, int, int)? _selFocus;

  /// Word or row a double- or triple-click grabbed. A drag keeps this edge
  /// fixed and extends by the same unit, the way a browser does.
  (int, int, int)? _pivotStart;
  (int, int, int)? _pivotEnd;
  _DiffSelGranularity _selGranularity = _DiffSelGranularity.character;
  double _selDownMain = 0;
  double _selDownCross = 0;
  bool _selMoved = false;

  /// Monospace advance for the active base style, used to turn a cross-axis x
  /// into a display column (and back, in the painter). Cached; cleared when the
  /// base style changes.
  double? _monoAdvanceCache;
  double get _monoAdvance =>
      _monoAdvanceCache ??= measureMonoAdvanceWidth(_config.baseStyle);

  /// Effective gutter width for file [file] in unified mode.
  double gutterWidthOf(int file) {
    if (_config.splitMode) {
      return kDiffGutterWidth;
    }
    return _document.gutterModeOf(file) == DiffGutterMode.both
        ? kDiffGutterWidth
        : kDiffSingleGutterWidth;
  }

  /// Maximum horizontal scroll offset in scroll mode.
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
      contentWidth - codeViewportWidthFor(_lastCrossAxisExtent),
    );
  }

  double get _effectiveHScroll =>
      _horizontalScrollOffset.clamp(0.0, maxHorizontalScrollExtent);

  /// Whether there is an active selection (for the view's copy shortcut).
  bool get hasSelection => _selAnchor != null && _selFocus != null;

  /// Monospace advance of the active base style (display column → pixels).
  double get monoAdvanceWidth => _monoAdvance;

  /// Scroll extent of the slivers before this one (PR header, tab strip,
  /// toolbar) — so the view can turn a document offset into an absolute scroll
  /// position.
  double get precedingScrollExtent => _precedingScrollExtent;

  void _handleCodeTapDown(TapDragDownDetails details) {
    final count = diffSelectionTapCount(
      details.consecutiveTapCount,
      defaultTargetPlatform,
    );
    _selMoved = false;
    if (count <= 1) {
      _selGranularity = _DiffSelGranularity.character;
      _pivotStart = null;
      _pivotEnd = null;
      return;
    }
    final cell = cellAt(_selDownMain, _selDownCross, floorColumn: true);
    if (cell == null) {
      return;
    }
    if (count == 2) {
      _selectWordAt(cell);
    } else {
      _selectLineAt(cell);
    }
  }

  void _handleCodeTapUp(TapDragUpDetails details) {
    if (diffSelectionTapCount(
          details.consecutiveTapCount,
          defaultTargetPlatform,
        ) !=
        1) {
      return;
    }
    _handleCodeTap();
  }

  void _handleSelectStart(TapDragStartDetails details) {
    if (_selGranularity != _DiffSelGranularity.character) {
      return;
    }
    final anchor = cellAt(_selDownMain, _selDownCross);
    if (anchor == null) {
      return;
    }
    _selAnchor = anchor;
    _selFocus = anchor;
    _selMoved = false;
  }

  void _handleSelectUpdate(TapDragUpdateDetails details) {
    final offset = details.localOffsetFromOrigin;
    if (_selGranularity == _DiffSelGranularity.character &&
        offset.distance < 2) {
      return;
    }
    final hit = cellAt(_selDownMain + offset.dy, _selDownCross + offset.dx);
    if (hit == null) {
      return;
    }
    _selMoved = true;
    switch (_selGranularity) {
      case _DiffSelGranularity.character:
        if (hit == _selFocus) {
          return;
        }
        _selFocus = hit;
      case _DiffSelGranularity.word:
        _extendSelectionByWord(hit);
      case _DiffSelGranularity.line:
        _extendSelectionByLine(hit);
    }
    markNeedsPaint();
    onSelectionChanged?.call();
  }

  void _handleSelectEnd(TapDragEndDetails details) {
    if (_selGranularity == _DiffSelGranularity.character && !_selMoved) {
      clearSelection();
    } else {
      onSelectionChanged?.call();
    }
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
  /// the pinned tab strip.
  double revealOffsetForFile(int index) =>
      math.max(0, scrollOffsetForFile(index) - _config.topInset);

  /// Scroll offset that reveals one LINE of file [index] just below the pinned
  /// file header.
  ///
  /// The header docks under the tab strip and paints over the rows that have
  /// scrolled under it. Stopping at the pin line, the inset
  /// [revealOffsetForFile] uses for the header itself, hides the row a search
  /// hit or goto landed on. The header's own height is the rest of the
  /// clearance.
  double revealOffsetForLine(int index, int displayLine) => math.max(
    0,
    _precedingScrollExtent +
        _document.offsetOfLine(index, displayLine) -
        _config.topInset -
        _document.headerHeight,
  );

  /// Whether the sticky file header is currently pinned under the tab strip.
  bool get stickyHeaderPinned => _stickyPinned;

  /// Whether [mainAxisPosition] (from this sliver's paint origin) falls on
  /// the painted sticky file header.
  ///
  /// Code that has scrolled under that overlay is not a selection, hover, or
  /// comment target — the header owns the pointer. Document-space hit tests
  /// ([codeRowAt], [cellAt]) cannot see the overlay, so callers have to ask
  /// this instead of trusting a Y that maps to a hidden row.
  bool coversStickyHeader(double mainAxisPosition) {
    if (!_stickyPinned || _stickySlotIndex < 0) {
      return false;
    }
    final top = _stickyHeaderTop;
    return mainAxisPosition >= top &&
        mainAxisPosition < top + _document.headerHeight;
  }

  Set<int> _lastTokenSet = const {};

  /// Sticky-header state, recomputed each layout.
  int _stickyFile = -1;
  int _stickySlotIndex = -1;
  double _stickyHeaderTop = 0;

  /// Whether the sticky header is currently pinned (docked under the tabs)
  /// rather than at its natural scroll position. When pinned, its top border
  /// is clipped so it sits flush under the tab strip.
  bool _stickyPinned = false;

  /// Drops the per-line layout cache so the next pass remeasures wrapping.
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
    _validForMouseTracker = true;
    _store.repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    // Drop out of the tracker before detach so an in-flight hover cannot
    // call back into a sliver that is leaving the tree.
    _validForMouseTracker = false;
    _store.repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    _selectRecognizer.dispose();
    geometryListenable.dispose();
    super.dispose();
  }

  @override
  bool hitTestSelf({
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    if (coversStickyHeader(mainAxisPosition)) {
      return false;
    }
    if (codeRowAt(mainAxisPosition) != null) {
      return true;
    }
    return _config.overflowMode == DiffOverflowMode.scroll &&
        maxHorizontalScrollExtent > 0;
  }

  /// I-beam over code a drag can select; [MouseCursor.defer] everywhere else
  /// so the gutter, pill, and gap rows keep their own cursors.
  @override
  MouseCursor get cursor => _cursor;
  MouseCursor _cursor = MouseCursor.defer;

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => _onMouseExit;

  @override
  bool get validForMouseTracker => _validForMouseTracker;
  bool _validForMouseTracker = true;

  void _onMouseExit(PointerExitEvent event) {
    _cursor = MouseCursor.defer;
  }

  /// Whether [entry] is on code the selection recognizer owns. The gutter is
  /// a comment target, and headers, gaps, and comment cards are not code.
  bool _selectsTextAt(SliverHitTestEntry entry) {
    if (coversStickyHeader(entry.mainAxisPosition)) {
      return false;
    }
    final hit = codeRowAt(entry.mainAxisPosition);
    if (hit == null) {
      return false;
    }
    return entry.crossAxisPosition >= gutterWidthOf(hit.$1);
  }

  void _syncSelectionCursor(SliverHitTestEntry entry) {
    final MouseCursor next = _selectsTextAt(entry)
        ? SystemMouseCursors.text
        : MouseCursor.defer;
    if (_cursor == next) {
      return;
    }
    _cursor = next;
    // The tracker reads [cursor] on the frame after the hover that changed
    // it. A repaint is what schedules that read.
    markNeedsPaint();
  }

  @override
  void handleEvent(PointerEvent event, SliverHitTestEntry entry) {
    if (event is PointerScrollEvent) {
      handlePointerScroll(event);
      return;
    }
    if (event is PointerHoverEvent) {
      _syncSelectionCursor(entry);
      return;
    }
    if (event is! PointerDownEvent) {
      return;
    }
    // The sliver stays on the hit path as the header child's ancestor, so
    // a press on the pinned bar would otherwise start a code selection of
    // the rows scrolling underneath it.
    if (coversStickyHeader(entry.mainAxisPosition)) {
      return;
    }
    final hit = codeRowAt(entry.mainAxisPosition);
    if (hit == null) {
      return;
    }
    _downMain = entry.mainAxisPosition;
    if (entry.crossAxisPosition < gutterWidthOf(hit.$1)) {
      _tapRecognizer.addPointer(event);
    } else {
      _selDownMain = entry.mainAxisPosition;
      _selDownCross = entry.crossAxisPosition;
      _selectRecognizer.addPointer(event);
    }
  }

  void _handleCodeTap() {
    final m = _downMain;
    final tap = onCommentTap;
    clearSelection();
    if (m == null || tap == null) {
      return;
    }
    final group = commentGroupAtMain(m);
    if (group != null) {
      tap(group);
    }
  }

  void _handleGutterTap() {
    final m = _downMain;
    if (m == null) {
      return;
    }
    clearSelection();
    final hit = codeRowAt(m);
    if (hit != null && onGutterTap != null) {
      onGutterTap!(hit.$1, hit.$2);
    }
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
    final double codeWidth = codeWidthFor(crossAxisExtent);
    final int colsPerRow = _config.overflowMode == DiffOverflowMode.wrap
        ? math.max(1, (codeWidth / _monoAdvance).floor())
        : (1 << 30);
    _colsPerRow = colsPerRow;
    if (_document.setLayoutMode(_config.overflowMode, colsPerRow)) {
      lineCache.clear();
      scheduleLayoutModeTick();
    }

    double total = _document.totalExtent;

    if (_slots.isEmpty || _document.fileCount == 0) {
      collectGarbage(laidOutCount(), 0);
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
    double cacheEnd = math.min(
      total,
      cacheStart + constraints.remainingCacheExtent,
    );

    // Ensure structure for files that intersect the paint window (they are
    // on screen) and, if this frame still has budget, the cache window.
    // Prefetching the whole cache in one pass is what made a mid-size PR
    // hitch on first Diff-tab layout. Each file parses at most once; a
    // leftover cache file is picked up on the next frame.
    int firstFile;
    int lastFile;
    var parsedAny = false;
    var deferred = false;
    final parseClock = Stopwatch()..start();
    while (true) {
      firstFile = _document.fileAtOffset(cacheStart);
      lastFile = _document.fileAtOffset(
        math.min(total - 0.0001, math.max(0, cacheEnd)),
      );
      final paintEnd = math.min(
        total,
        constraints.scrollOffset + constraints.remainingPaintExtent,
      );
      final firstPaint = _document.fileAtOffset(
        math.min(total - 0.0001, math.max(0, constraints.scrollOffset)),
      );
      final lastPaint = _document.fileAtOffset(
        math.min(total - 0.0001, math.max(0, paintEnd)),
      );
      var parsedThisPass = false;
      for (var i = firstPaint; i <= lastPaint; i++) {
        if (_document.isExpanded(i) && _document.structureOf(i) == null) {
          _store.ensureStructure(i);
          parsedThisPass = true;
        }
      }
      for (var i = firstFile; i <= lastFile; i++) {
        if (i >= firstPaint && i <= lastPaint) {
          continue;
        }
        if (!_document.isExpanded(i) || _document.structureOf(i) != null) {
          continue;
        }
        if (parseClock.elapsedMilliseconds >= _kStructureParseBudgetMs) {
          deferred = true;
          break;
        }
        _store.ensureStructure(i);
        parsedThisPass = true;
      }
      if (!parsedThisPass) {
        break;
      }
      parsedAny = true;
      total = _document.totalExtent;
      cacheEnd = math.min(total, cacheStart + constraints.remainingCacheExtent);
    }
    if (parsedAny) {
      scheduleLayoutModeTick();
    }
    if (deferred) {
      scheduleDeferredStructureParse();
    }

    // Compute sticky state before layout so the sticky file's header slot can
    // be force-included in the laid-out range even when scrolled deep into the
    // file (its natural offset is above the viewport).
    computeSticky(constraints);

    final range = visibleSlotRange(cacheStart, cacheEnd);
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
      collectGarbage(laidOutCount(), 0);
    } else {
      layoutSlotRange(layoutFirst, layoutLast, crossAxisExtent);
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
      final leftPainter = makeRowPainter(
        gutterWidth: kDiffSplitGutterWidth,
        hideOldGutter: false,
        hideNewGutter: true,
      );
      final rightPainter = makeRowPainter(
        gutterWidth: kDiffSplitGutterWidth,
        hideOldGutter: true,
        hideNewGutter: false,
      );
      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(offset.dx, offset.dy, halfW, paintH))
        ..translate(offset.dx, offset.dy);
      paintCode(
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
      paintCode(
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
      final fullPainter = makeRowPainter(
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
            return newOnlyPainter ??= makeRowPainter(
              gutterWidth: kDiffSingleGutterWidth,
              hideOldGutter: true,
              hideNewGutter: false,
            );
          case DiffGutterMode.oldOnly:
            return oldOnlyPainter ??= makeRowPainter(
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
      paintCode(
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
    _stickySlotIndex = headerSlotOf(_stickyFile);
    _stickyHeaderTop = stickyMainAxis(originY);

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
        // Hide the top border so the docked header sits flush under the
        // bordered toolbar above — keeping it would stack a doubled line.
        // The separator the eye expects at a file boundary is drawn by
        // `_paintCode` as each file's content-bottom hairline instead.
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
    // geometry one frame stale and could fire mid-paint. Coalesced via a flag.
    if (!_geometryTickScheduled) {
      _geometryTickScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _geometryTickScheduled = false;
        if (attached) {
          geometryListenable.value++;
          // Reflect the docked header (post-frame: this rebuilds header
          // widgets, which is illegal mid-paint). Reads the fields fresh so
          // coalesced paints report the final state of the frame.
          pinnedFileListenable?.value = _stickyPinned ? _stickyFile : null;
        }
      });
    }
  }

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    bool hit(RenderBox child) => hitTestBoxChild(
      BoxHitTestResult.wrap(result),
      child,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
    );

    // Painted last, so it must win hits too — otherwise a comment card or
    // gap row that has scrolled under the pinned bar still receives the
    // pointer, and so does the code-selection recognizer on this sliver.
    if (_stickyPinned && _stickySlotIndex >= 0) {
      RenderBox? child = firstChild;
      while (child != null) {
        if (indexOf(child) == _stickySlotIndex) {
          if (hit(child)) {
            return true;
          }
          break;
        }
        child = childAfter(child);
      }
    }

    RenderBox? child = lastChild;
    while (child != null) {
      if (!(_stickyPinned && indexOf(child) == _stickySlotIndex) &&
          hit(child)) {
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
