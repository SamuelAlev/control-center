import 'dart:math' as math;

import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_shadows.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/domain/entities/reaction_group.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/diff_keyboard_handler.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/diff_search_controller.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_slot.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/diff_structure_store.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/file_header.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/measured_inline_thread.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/pr_diff_document.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/suggestion_composer.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_sliver.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_row_painter.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_composer_widget.dart';
import 'package:control_center/features/pr_review/presentation/widgets/sticky_header.dart';
import 'package:control_center/features/pr_review/providers/diff_view_settings_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/diff_parser.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The unified single-canvas PR diff body, exposed as a sliver for the host
/// [CustomScrollView]. Owns the [PrDiffDocument] (flat row model) and the
/// [DiffStructureStore] (synchronous structure + async colour), and renders
/// the whole PR through one [UnifiedDiffSliver]:
///
/// - Code lines are painted directly on a single canvas — no per-file widgets,
///   so a 3000-file PR has no per-cell mount/dispose churn on a fast fling.
/// - Structure is parsed synchronously on demand, so every visible row always
///   has plain text to paint — there is never a loading placeholder.
/// - The scroll extent is exact (Fenwick over file heights), so the scrollbar
///   thumb maps 1:1 to content with zero drift.
class UnifiedDiffView extends ConsumerStatefulWidget {
  /// Creates the unified diff view.
  const UnifiedDiffView({
    super.key,
    required this.files,
    this.prNumber = 0,
    this.onToggleViewed,
    this.fetchFileContent,
    this.inlineCommentsController,
    this.serverComments = const [],
    this.splitView = false,
  });

  /// Files in display (tree) order.
  final List<PrFile> files;

  /// PR number (drives the inline-comments controller subscription).
  final int prNumber;

  /// Called when a file's "viewed" toggle is flipped.
  final void Function({required String path, required bool viewed})?
      onToggleViewed;

  /// Fetches a file's full content (for expanding "Show N lines" / "Show end
  /// of file" gaps). Null disables gap expansion.
  final Future<String> Function(String path)? fetchFileContent;

  /// Controller for draft/local inline comment threads + replies.
  final PrInlineCommentsController? inlineCommentsController;

  /// Server-side review comments, synthesised into read-only threads.
  final List<PrCodeReviewComment> serverComments;

  /// Whether to render side-by-side (split) instead of unified.
  final bool splitView;

  @override
  ConsumerState<UnifiedDiffView> createState() => UnifiedDiffViewState();
}

/// State for [UnifiedDiffView]; exposes [jumpToFile] for the file tree.
class UnifiedDiffViewState extends ConsumerState<UnifiedDiffView> {
  final GlobalKey _sliverKey = GlobalKey();
  late final PrDiffDocument _document;
  late final DiffStructureStore _store;
  late final PrDiffSearchController _search;
  late final PrDiffKeyboardHandler _keyboard;
  final Set<String> _viewed = {};

  /// In-flight gap expansions, keyed by `(file, gapRawIndex)`, to ignore
  /// double taps while content is being fetched.
  final Set<(int, int)> _expandingGaps = {};
  int _revision = 0;
  Brightness? _brightness;

  /// Measured inline-comment-block heights, keyed by thread id (and the
  /// composer's slot key). Seeded with an estimate, replaced with the real
  /// measured height for snap-free layout.
  final Map<String, double> _commentHeights = {};

  /// Threads to render, keyed by their slot key, rebuilt with the slot list.
  Map<String, PrInlineThread> _threadBySlotKey = const {};

  /// The open inline comment/suggestion composer (anchored under a selection or
  /// a row range), or null when nothing is being composed. Hosted as a
  /// `composer` slot so it reserves exact height like a thread block.
  _ComposerRequest? _activeComposer;

  /// Thread whose conversation is currently focused (its highlight is drawn in
  /// the active colour and its popover is shown).
  String? _focusedThreadId;

  /// Root-overlay entry hosting the review affordances (floating selection
  /// toolbar, gutter "+" pill, commenter avatars). Positioned in screen space
  /// from the sliver's geometry; rebuilt on the sliver's geometry notifier.
  OverlayEntry? _reviewOverlay;

  /// Root-overlay entry hosting the horizontal scrollbar (scroll mode). Kept
  /// separate from the review overlay so it shows regardless of the inline-
  /// comments controller and in split view.
  OverlayEntry? _hScrollbarOverlay;
  ValueNotifier<int>? _geometry;
  void _markReviewOverlayDirty() => _reviewOverlay?.markNeedsBuild();

  /// Marks both root overlays for rebuild on a geometry tick (post-paint), so
  /// affordances and the scrollbar thumb track settled geometry.
  void _onGeometryTick() {
    _reviewOverlay?.markNeedsBuild();
    _hScrollbarOverlay?.markNeedsBuild();
  }

  /// Binds the sliver's geometry notifier once (idempotent); both overlays
  /// reposition off it.
  void _bindGeometryListener() {
    if (_geometry != null) {
      return;
    }
    _geometry = _sliver?.geometryListenable?..addListener(_onGeometryTick);
  }

  /// Code row `(file, displayLine)` the mouse is over, for the gutter "+" pill.
  /// A notifier so hover changes rebuild only the pill/avatar layer (via a
  /// `ValueListenableBuilder`) and never the hover `MouseRegion` itself —
  /// rebuilding the region would re-fire enter/exit and make the pill flicker.
  final ValueNotifier<(int, int)?> _hoverRow = ValueNotifier(null);

  /// Stable key so the hover `MouseRegion`'s render object survives overlay
  /// rebuilds (scroll / token-fade) — recreating it would re-fire enter/exit
  /// and clear the hover, making the pill flicker.
  final GlobalKey _hoverRegionKey = GlobalKey();

  /// Active gutter-pill drag range `(file, startLine, endLine)`, shown as a
  /// pending highlight while dragging.
  (int, int, int)? _pillDrag;

  /// Memoised slot list, rebuilt only when [_revision] changes.
  List<DiffSlot> _slots = const [];
  Map<String, int> _slotIndexByKey = const {};
  int _slotsRevision = -1;

  List<DiffSlot> _ensureSlots() {
    if (_slotsRevision == _revision) {
      return _slots;
    }
    final threadBySlotKey = <String, PrInlineThread>{};
    _slots = _buildSlots(threadBySlotKey);
    _threadBySlotKey = threadBySlotKey;
    _slotIndexByKey = {
      for (var i = 0; i < _slots.length; i++) _slots[i].key: i,
    };
    _slotsRevision = _revision;
    return _slots;
  }

  /// Builds the offset-ordered sparse-child list: one header per file, a gap
  /// affordance per expand-gap row, and an inline-comment block per anchored
  /// thread (draft or synthesised server comment). Comment heights are
  /// reserved in the document first (single pass, in file order) so every
  /// slot offset is exact.
  List<DiffSlot> _buildSlots(Map<String, PrInlineThread> threadOut) {
    final slots = <DiffSlot>[];
    final ctl = widget.inlineCommentsController;
    for (var f = 0; f < _document.fileCount; f++) {
      final filename = _document.files[f].filename;
      slots.add(DiffSlot(
        kind: DiffSlotKind.header,
        key: 'hdr:$filename',
        fileIndex: f,
        offset: _document.offsetOfFile(f),
        height: kFastFileHeaderHeight,
      ));
      if (!_document.isExpanded(f)) {
        continue;
      }
      final raw = _document.structureOf(f);
      if (raw == null) {
        continue;
      }
      final count = _document.lineCountOf(f);

      // The open composer (if any) anchored in this file.
      final composer = _activeComposer?.fileIndex == f ? _activeComposer : null;
      final composerLine = composer?.anchorDisplayLine ?? -1;
      const composerKey = 'composer';

      // Pass A: resolve anchored threads + reserve their heights (and the
      // composer's) so the document's offsetOfLine reflects them before we
      // read slot offsets.
      final serverByAnchor = _serverByAnchor(filename);
      final threadByLine = <int, PrInlineThread>{};
      final blocks = <DiffCommentBlock>[];
      for (var d = 0; d < count; d++) {
        final r = _document.rawIndexOf(f, d);
        final thread = _threadAnchoredAt(raw, r, ctl, filename, serverByAnchor);
        if (thread != null) {
          threadByLine[d] = thread;
          final h = _commentHeights[thread.id] ?? _estimateThreadHeight(thread);
          blocks.add(DiffCommentBlock(key: thread.id, anchorLine: d, height: h));
        }
        if (d == composerLine) {
          blocks.add(DiffCommentBlock(
            key: composerKey,
            anchorLine: d,
            height: _commentHeights[composerKey] ?? _estimateComposerHeight(),
          ));
        }
      }
      _document.setCommentBlocks(f, blocks);

      // Pass B: emit gap + comment + composer slots with now-exact offsets.
      for (var d = 0; d < count; d++) {
        final r = _document.rawIndexOf(f, d);
        if (raw.kindAt(r) == DiffLineKind.expandGap) {
          slots.add(DiffSlot(
            kind: DiffSlotKind.gap,
            key: 'gap:$f:$r',
            fileIndex: f,
            offset: _document.offsetOfLine(f, d),
            height: kDiffLineHeight,
            rawIndex: r,
            anchorDisplayLine: d,
          ));
        }
        var below = _document.offsetOfLine(f, d) + kDiffLineHeight;
        final thread = threadByLine[d];
        if (thread != null && ctl != null) {
          final key = 'thread:${thread.id}';
          threadOut[key] = thread;
          final h = _commentHeights[thread.id] ?? _estimateThreadHeight(thread);
          slots.add(DiffSlot(
            kind: DiffSlotKind.comment,
            key: key,
            fileIndex: f,
            offset: below,
            height: h,
            anchorDisplayLine: d,
          ));
          below += h; // stack the composer under an existing thread
        }
        if (d == composerLine && ctl != null) {
          slots.add(DiffSlot(
            kind: DiffSlotKind.composer,
            key: composerKey,
            fileIndex: f,
            offset: below,
            height: _commentHeights[composerKey] ?? _estimateComposerHeight(),
            anchorDisplayLine: d,
          ));
        }
      }
    }
    return slots;
  }

  double _estimateComposerHeight() =>
      (_activeComposer?.kind == PrInlineThreadKind.suggestion) ? 200 : 64;

  /// Server review comments for [filename] indexed by `"<side>-<anchorLine>"`.
  Map<String, List<PrCodeReviewComment>> _serverByAnchor(String filename) {
    final out = <String, List<PrCodeReviewComment>>{};
    for (final c in widget.serverComments) {
      if (c.path != filename) {
        continue;
      }
      final anchor = c.anchorLine;
      if (anchor == null) {
        continue;
      }
      out.putIfAbsent('${c.side}-$anchor', () => []).add(c);
    }
    return out;
  }

  /// The thread anchored at raw row [rawIndex] (draft preferred, else a
  /// synthesised server thread), or null.
  PrInlineThread? _threadAnchoredAt(
    DiffRawLines raw,
    int rawIndex,
    PrInlineCommentsController? ctl,
    String filename,
    Map<String, List<PrCodeReviewComment>> serverByAnchor,
  ) {
    final kind = raw.kindAt(rawIndex);
    if (kind == DiffLineKind.expandGap || kind == DiffLineKind.hunkHeader) {
      return null;
    }
    final side = kind == DiffLineKind.deletion ? 'LEFT' : 'RIGHT';
    final lineNo =
        side == 'LEFT' ? raw.oldLines[rawIndex] : raw.newLines[rawIndex];
    if (lineNo == null) {
      return null;
    }
    if (ctl != null) {
      final draft = ctl.forAnchor(filePath: filename, line: lineNo, side: side);
      if (draft != null && draft.lineEnd == lineNo) {
        return draft;
      }
    }
    final serverGroup = serverByAnchor['$side-$lineNo'];
    if (serverGroup != null && serverGroup.isNotEmpty) {
      return _synthesizeServerThread(serverGroup, filename, lineNo, side);
    }
    return null;
  }

  PrInlineThread _synthesizeServerThread(
    List<PrCodeReviewComment> comments,
    String filename,
    int line,
    String side,
  ) {
    final sorted = [...comments]..sort((a, b) {
        final ad = a.createdAt;
        final bd = b.createdAt;
        if (ad != null && bd != null) {
          return ad.compareTo(bd);
        }
        return a.id.compareTo(b.id);
      });
    return PrInlineThread(
      id: 'server-${sorted.first.id}',
      filePath: filename,
      line: line,
      side: side,
      kind: PrInlineThreadKind.comment,
      originalCode: '',
      suggestedCode: '',
      serverId: sorted.first.id,
      syncState: PrInlineSyncState.synced,
      entries: [
        for (final c in sorted)
          PrInlineEntry(
            id: 'server-entry-${c.id}',
            author: c.user?.login ?? AppLocalizations.of(context).unknownAuthor,
            authorAvatarUrl: c.user?.avatarUrl,
            body: c.body,
            createdAt: c.createdAt,
          ),
      ],
    );
  }

  double _estimateThreadHeight(PrInlineThread thread) =>
      52 + thread.entries.length * 64 + 44 + 16;

  void _onCommentMeasured(String threadId, double height) {
    final prev = _commentHeights[threadId];
    if (prev != null && (prev - height).abs() < 0.5) {
      return;
    }
    _commentHeights[threadId] = height;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _revision++);
      }
    });
  }

  String _gapLabel(int file, int rawIndex) {
    final raw = _document.structureOf(file);
    if (raw == null) {
      return 'Show lines';
    }
    final oldStart = raw.oldLines[rawIndex] ?? 0;
    final oldEnd = raw.gapOldEnds[rawIndex] ?? oldStart;
    if (oldEnd == kEofGapSentinel) {
      return 'Show end of file';
    }
    final n = (oldEnd - oldStart + 1).clamp(0, 1 << 20);
    return 'Show $n ${n == 1 ? 'line' : 'lines'}';
  }

  IconData _gapIcon(int file, int rawIndex) {
    final raw = _document.structureOf(file);
    if (raw == null) {
      return LucideIcons.chevronsUpDown;
    }
    final oldEnd = raw.gapOldEnds[rawIndex] ?? (raw.oldLines[rawIndex] ?? 0);
    if (oldEnd == kEofGapSentinel) {
      return LucideIcons.chevronDown;
    }
    return LucideIcons.chevronsUpDown;
  }

  @override
  void initState() {
    super.initState();
    _document = PrDiffDocument(
      lineHeight: kDiffLineHeight,
      headerHeight: kFastFileHeaderHeight,
      autoCollapseThreshold: kPrDiffAutoCollapseThreshold,
    )..setFiles(widget.files);
    _store = DiffStructureStore(document: _document, maxTokenFiles: 300);
    _syncViewedFromFiles();
    _ensureExpandedStructures();

    _search = PrDiffSearchController(
      files: widget.files,
      onChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
      fileStateKeys: const {},
      activeScrollPositionGetter: _activeScrollPosition,
      estimatedFileTopGetter: _fileScrollOffset,
      onInsertOverlay: (entry) {
        _search.searchOverlay = entry;
        Overlay.of(context, rootOverlay: true).insert(entry);
      },
      onRemoveOverlay: (entry) => entry.remove(),
    );

    _keyboard = PrDiffKeyboardHandler(
      files: widget.files,
      searchOpenGetter: () => _search.searchOpen,
      activeScrollPositionGetter: _activeScrollPosition,
      estimatedFileTopGetter: _fileScrollOffset,
      fileStateKeys: const {},
      onOpenSearch: _openSearch,
      onCloseSearch: () => _search.closeSearch(),
      onGoToNextMatch: () => _search.goToNextMatch(),
      onGoToPrevMatch: () => _search.goToPrevMatch(),
      onFullRefresh: () {
        if (mounted) {
          setState(() {});
        }
      },
      onToggleViewedForPath: widget.onToggleViewed != null
          ? (path) {
              final i = _document.indexOfFile(path);
              if (i >= 0) {
                _toggleViewed(i);
              }
            }
          : null,
      onToggleCollapseForPath: (path) {
        final i = _document.indexOfFile(path);
        if (i >= 0) {
          _toggleExpanded(i);
        }
      },
      onCopy: _copySelection,
      onClearSelection: _clearSelection,
    );
    HardwareKeyboard.instance.addHandler(_keyboard.handleGlobalKey);
  }

  ScrollPosition? _activeScrollPosition() {
    final ctl = PrimaryScrollController.maybeOf(context);
    return (ctl != null && ctl.hasClients) ? ctl.position : null;
  }

  /// Absolute scroll offset (in the outer scrollable) of file [i]'s top —
  /// exact via the render sliver's Fenwick-backed mapping.
  double _fileScrollOffset(int i) {
    final ro = _sliverKey.currentContext?.findRenderObject();
    if (ro is RenderUnifiedDiffSliver) {
      return ro.scrollOffsetForFile(i);
    }
    return _document.offsetOfFile(i);
  }

  void _openSearch() {
    _search.openSearch();
    if (_search.searchOverlay == null) {
      final entry = OverlayEntry(builder: _buildSearchOverlay);
      _search.onInsertOverlay(entry);
    }
  }

  Widget _buildSearchOverlay(BuildContext _) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final fTheme = context.theme;
    final hasMatches = _search.totalMatches > 0;
    return Positioned(
      top: 16 + MediaQuery.of(context).padding.top,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: fTheme.colors.background,
            border: Border.all(color: fTheme.colors.border),
            borderRadius: BorderRadius.circular(10),
            boxShadow: AppShadows.golden,
          ),
          child: Row(
            children: [
              Icon(LucideIcons.search,
                  size: 16, color: fTheme.colors.mutedForeground),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _search.searchCtrl,
                  focusNode: _search.searchFocus,
                  autofocus: true,
                  style: theme.textTheme.bodyMedium,
                  cursorColor: fTheme.colors.primary,
                  decoration: InputDecoration.collapsed(
                    hintText: l10n.searchInDiffHint,
                  ),
                  onChanged: _search.onSearchChanged,
                  onSubmitted: (_) {
                    if (hasMatches) {
                      _search.goToNextMatch();
                    }
                  },
                ),
              ),
              if (hasMatches) ...[
                Text(
                  '${_search.currentMatchIdx} of ${_search.totalMatches}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: fTheme.colors.mutedForeground,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(width: 4),
                _searchNavButton(
                    LucideIcons.chevronUp, l10n.previousMatch, _search.goToPrevMatch),
                _searchNavButton(
                    LucideIcons.chevronDown, l10n.nextMatch, _search.goToNextMatch),
              ],
              FTooltip(
                tipBuilder: (_, _) => Text(l10n.closeEsc),
                child: FButton.icon(
                  onPress: _search.closeSearch,
                  child: const Icon(LucideIcons.x, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchNavButton(IconData icon, String tip, VoidCallback onPressed) =>
      SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          icon: Icon(icon, size: 16),
          tooltip: tip,
          onPressed: onPressed,
        ),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (brightness != _brightness) {
      _brightness = brightness;
      _store.isDark = brightness == Brightness.dark;
    }
  }

  @override
  void didUpdateWidget(covariant UnifiedDiffView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.files, widget.files)) {
      // Files whose patch changed (e.g. the local-git source filling patches in
      // after the initial empty-patch tree) had their cached structure dropped —
      // invalidate their stale syntax tokens so they re-tokenise from the new
      // patch instead of painting old colour at shifted line indices.
      final repatched = _document.setFiles(widget.files);
      for (final i in repatched) {
        _store.invalidateFile(i);
      }
      _syncViewedFromFiles();
      _ensureExpandedStructures();
      _search.files = widget.files;
      _keyboard.files = widget.files;
      _revision++;
    }
    if (!identical(oldWidget.serverComments, widget.serverComments)) {
      _focusedThreadId = null;
      _revision++;
    }
    // If the PR or controller changed, tear down the review overlay so it
    // re-binds to the new sliver/controller (avoids a stale listener + stale
    // geometry against a replaced render object).
    if (oldWidget.prNumber != widget.prNumber ||
        !identical(
            oldWidget.inlineCommentsController, widget.inlineCommentsController)) {
      _geometry?.removeListener(_onGeometryTick);
      _geometry = null;
      _reviewOverlay?.remove();
      _reviewOverlay = null;
      _hScrollbarOverlay?.remove();
      _hScrollbarOverlay = null;
      _activeComposer = null;
      _hoverRow.value = null;
      _pillDrag = null;
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboard.handleGlobalKey);
    _geometry?.removeListener(_onGeometryTick);
    _reviewOverlay?.remove();
    _reviewOverlay = null;
    _hScrollbarOverlay?.remove();
    _hScrollbarOverlay = null;
    _hoverRow.dispose();
    _search.dispose();
    _store.dispose();
    super.dispose();
  }

  void _syncViewedFromFiles() {
    _viewed
      ..clear()
      ..addAll([
        for (final f in widget.files)
          if (f.viewerViewedState.isViewed) f.filename,
      ]);
  }

  /// Parses structure for every initially-expanded file up front so the scroll
  /// extent is exact from the first frame (no estimate→exact drift) and the
  /// painter never meets an unparsed visible file. Auto-collapsed huge files
  /// are skipped until the user expands them.
  void _ensureExpandedStructures() {
    for (var i = 0; i < _document.fileCount; i++) {
      if (_document.isExpanded(i)) {
        _store.ensureStructure(i);
      }
    }
  }

  void _toggleExpanded(int index) {
    final next = !_document.isExpanded(index);
    _document.setExpanded(index, expanded: next);
    if (next) {
      _store.ensureStructure(index);
    }
    setState(() => _revision++);
  }

  /// Opens an inline composer for a new file-level comment, anchored at the
  /// file's first code row (triggered by the header "+").
  void _openFileComment(int fileIndex) {
    final d = _firstCodeDisplayLine(fileIndex);
    if (d != null) {
      _openComposerForRange(
          fileIndex, d, d, null, null, PrInlineThreadKind.comment);
    }
  }

  int? _firstCodeDisplayLine(int file) {
    final raw = _document.structureOf(file);
    if (raw == null) {
      return null;
    }
    final count = _document.lineCountOf(file);
    for (var d = 0; d < count; d++) {
      if (_isCodeRow(raw, _document.rawIndexOf(file, d))) {
        return d;
      }
    }
    return null;
  }

  bool _isCodeRow(DiffRawLines raw, int rawIndex) {
    if (rawIndex < 0 || rawIndex >= raw.length) {
      return false;
    }
    final k = raw.kindAt(rawIndex);
    return k == DiffLineKind.context ||
        k == DiffLineKind.addition ||
        k == DiffLineKind.deletion;
  }

  /// Opens an inline composer for a new comment on the code row [rawIndex]
  /// (gutter tap). Resolves the display line from the structure index.
  void _addLineComment(int file, int rawIndex) {
    final d = _document.displayLineOfRaw(file, rawIndex);
    if (d >= 0) {
      _openComposerForRange(
          file, d, d, null, null, PrInlineThreadKind.comment);
    }
  }

  /// Opens the inline composer for the active text selection (toolbar action).
  void _openComposerFromSelection(PrInlineThreadKind kind) {
    final ro = _sliverKey.currentContext?.findRenderObject();
    if (ro is! RenderUnifiedDiffSliver) {
      return;
    }
    final r = ro.selectionRange();
    if (r == null) {
      return;
    }
    final single = r.startLine == r.endLine;
    ro.clearSelection();
    _openComposerForRange(
      r.file,
      r.startLine,
      r.endLine,
      single ? r.startCol : null,
      single ? r.endCol : null,
      kind,
    );
  }

  /// Opens the inline composer anchored under display rows `[startLine,
  /// endLine]` of [file], optionally scoped to columns `[startCol, endCol)` on
  /// a single line. The composer is rendered as a `composer` slot.
  void _openComposerForRange(
    int file,
    int startLine,
    int endLine,
    int? startCol,
    int? endCol,
    PrInlineThreadKind kind,
  ) {
    if (widget.inlineCommentsController == null) {
      return;
    }
    final lo = startLine <= endLine ? startLine : endLine;
    final hi = startLine <= endLine ? endLine : startLine;
    final info = _resolveAnchor(file, lo, hi);
    if (info == null) {
      return;
    }
    setState(() {
      _activeComposer = _ComposerRequest(
        fileIndex: file,
        anchorDisplayLine: hi,
        startDisplayLine: lo,
        endDisplayLine: hi,
        startCol: startCol,
        endCol: endCol,
        side: info.side,
        lineNoStart: info.lineNoStart,
        lineNoEnd: info.lineNoEnd,
        originalCode: info.originalCode,
        kind: kind,
      );
      _commentHeights.remove('composer');
      _revision++;
    });
  }

  void _submitComment(_ComposerRequest req, String body) {
    widget.inlineCommentsController?.create(
      filePath: _document.files[req.fileIndex].filename,
      line: req.lineNoStart,
      lineEnd: req.lineNoEnd,
      startCol: req.startCol,
      endCol: req.endCol,
      side: req.side,
      kind: PrInlineThreadKind.comment,
      originalCode: req.originalCode,
      suggestedCode: '',
      authorBody: body,
    );
    _cancelComposer();
  }

  void _submitSuggestion(
    _ComposerRequest req,
    String suggested,
    String comment,
  ) {
    final body = StringBuffer();
    if (comment.trim().isNotEmpty) {
      body
        ..write(comment.trim())
        ..write('\n\n');
    }
    body
      ..write('```suggestion\n')
      ..write(suggested)
      ..write('\n```');
    widget.inlineCommentsController?.create(
      filePath: _document.files[req.fileIndex].filename,
      line: req.lineNoStart,
      lineEnd: req.lineNoEnd,
      startCol: req.startCol,
      endCol: req.endCol,
      side: req.side,
      kind: PrInlineThreadKind.suggestion,
      originalCode: req.originalCode,
      suggestedCode: suggested,
      authorBody: body.toString(),
    );
    _cancelComposer();
  }

  void _cancelComposer() {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeComposer = null;
      _commentHeights.remove('composer');
      _revision++;
    });
  }

  /// Builds the per-`(file, displayLine)` comment-highlight map from posted
  /// threads (draft + server) and the active composer / pill drag range.
  Map<int, Map<int, DiffCommentHighlight>> _computeCommentHighlights() {
    final ctl = widget.inlineCommentsController;
    final out = <int, Map<int, DiffCommentHighlight>>{};

    void put(int file, int line, DiffCommentHighlight hl) {
      (out[file] ??= <int, DiffCommentHighlight>{})[line] = hl;
    }

    for (var f = 0; f < _document.fileCount; f++) {
      if (!_document.isExpanded(f)) {
        continue;
      }
      final raw = _document.structureOf(f);
      if (raw == null) {
        continue;
      }
      final filename = _document.files[f].filename;
      final serverByAnchor = _serverByAnchor(filename);
      final count = _document.lineCountOf(f);
      for (var d = 0; d < count; d++) {
        final r = _document.rawIndexOf(f, d);
        if (!_isCodeRow(raw, r)) {
          continue;
        }
        final side = raw.kindAt(r) == DiffLineKind.deletion ? 'LEFT' : 'RIGHT';
        final lineNo = side == 'LEFT' ? raw.oldLines[r] : raw.newLines[r];
        if (lineNo == null) {
          continue;
        }
        final draft =
            ctl?.forAnchor(filePath: filename, line: lineNo, side: side);
        if (draft != null) {
          put(
            f,
            d,
            DiffCommentHighlight(
              startCol: draft.hasCharRange ? draft.startCol! : 0,
              endCol: draft.hasCharRange ? draft.endCol : null,
              active: draft.id == _focusedThreadId,
            ),
          );
        } else if ((serverByAnchor['$side-$lineNo'] ?? const []).isNotEmpty) {
          put(f, d, const DiffCommentHighlight(startCol: 0));
        }
      }
    }

    // The composer range shows the same highlight while open.
    final req = _activeComposer;
    if (req != null) {
      for (var d = req.startDisplayLine; d <= req.endDisplayLine; d++) {
        final single = req.startDisplayLine == req.endDisplayLine;
        put(
          req.fileIndex,
          d,
          DiffCommentHighlight(
            startCol: single ? (req.startCol ?? 0) : 0,
            endCol: single ? req.endCol : null,
            active: true,
          ),
        );
      }
    }

    // The gutter-pill drag previews its row range as a live highlight (bounds-
    // checked: a gap-expand mid-drag can shift the line count).
    final drag = _pillDrag;
    if (drag != null && _document.isExpanded(drag.$1)) {
      final count = _document.lineCountOf(drag.$1);
      final lo = (drag.$2 <= drag.$3 ? drag.$2 : drag.$3).clamp(0, count - 1);
      final hi = (drag.$2 <= drag.$3 ? drag.$3 : drag.$2).clamp(0, count - 1);
      for (var d = lo; d <= hi; d++) {
        put(drag.$1, d, const DiffCommentHighlight(startCol: 0, active: true));
      }
    }
    return out;
  }

  // ── Review overlay (floating toolbar, gutter pill, commenter avatars) ───

  RenderUnifiedDiffSliver? get _sliver {
    final ro = _sliverKey.currentContext?.findRenderObject();
    return ro is RenderUnifiedDiffSliver ? ro : null;
  }

  void _onSelectionChanged() => _markReviewOverlayDirty();

  void _focusThread(String id) {
    setState(() => _focusedThreadId = _focusedThreadId == id ? null : id);
  }

  /// Inserts the root-overlay review layer once the controller is present.
  void _ensureReviewOverlay() {
    if (_reviewOverlay != null || widget.inlineCommentsController == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _reviewOverlay != null) {
        return;
      }
      final entry = OverlayEntry(builder: _buildReviewOverlay);
      _reviewOverlay = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
      _bindGeometryListener();
    });
  }

  /// Inserts the horizontal scrollbar overlay (independent of the review
  /// overlay, so it works without a comments controller and in split view).
  void _ensureHScrollbarOverlay() {
    if (_hScrollbarOverlay != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hScrollbarOverlay != null) {
        return;
      }
      final entry = OverlayEntry(builder: _buildHScrollbarOverlay);
      _hScrollbarOverlay = entry;
      Overlay.of(context, rootOverlay: true).insert(entry);
      _bindGeometryListener();
    });
  }

  /// A thin draggable horizontal scrollbar pinned at the bottom of the diff
  /// viewport, shown only when the widest line overflows in scroll mode. The
  /// sliver owns the offset; dragging pans it (paint-only).
  Widget _buildHScrollbarOverlay(BuildContext overlayContext) {
    final ro = _sliver;
    final scrollable = Scrollable.maybeOf(context);
    final pos = _activeScrollPosition();
    final box = scrollable?.context.findRenderObject();
    if (ro == null || pos == null || box is! RenderBox || !box.attached) {
      return const SizedBox.shrink();
    }
    final double maxScrollX = ro.maxHorizontalScrollExtent;
    if (maxScrollX <= 0) {
      return const SizedBox.shrink();
    }
    final Offset vpTopLeft = box.localToGlobal(Offset.zero);
    final Size vpSize = box.size;
    final double diffLeft =
        vpTopLeft.dx + math.max(0, vpSize.width - ro.contentCrossAxisExtent);
    final double diffWidth =
        ro.contentCrossAxisExtent > 0 ? ro.contentCrossAxisExtent : vpSize.width;
    // The thumb track spans the scrollable code area (gutter excluded in
    // unified; the whole width in split, where both panes share the offset).
    final double gutter = widget.splitView ? 0.0 : kDiffGutterWidth;
    final double trackLeft = diffLeft + gutter;
    final double trackWidth = math.max(0.0, diffWidth - gutter);
    if (trackWidth <= 16) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: trackLeft,
            width: trackWidth,
            top: vpTopLeft.dy + vpSize.height - 12,
            height: 12,
            child: _DiffHScrollbar(
              offset: ro.horizontalScrollOffset,
              maxOffset: maxScrollX,
              viewportWidth: trackWidth,
              onPan: ro.applyHorizontalPan,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewOverlay(BuildContext overlayContext) {
    final ro = _sliver;
    final ctl = widget.inlineCommentsController;
    final scrollable = Scrollable.maybeOf(context);
    final pos = _activeScrollPosition();
    final box = scrollable?.context.findRenderObject();
    if (ro == null ||
        ctl == null ||
        pos == null ||
        box is! RenderBox ||
        !box.attached ||
        widget.splitView) {
      return const SizedBox.shrink();
    }

    // Map document space → global screen space via the enclosing scrollable's
    // box (robust where the sliver's own paint transform is awkward — it sits
    // inside a SliverMainAxisGroup). A line's absolute scroll position is the
    // preceding slivers' extent + its document offset; on screen that is the
    // scrollable's top + (absolute − scroll pixels).
    final Offset vpTopLeft = box.localToGlobal(Offset.zero);
    final Size vpSize = box.size;
    final double pixels = pos.pixels;
    final double preceding = ro.precedingScrollExtent;
    final double adv = ro.monoAdvanceWidth;
    final double hScroll = ro.horizontalScrollOffset;
    final int cols = ro.colsPerRow;
    final double topInset = StickyHeaderInset.of(context);
    // The diff body is inset from the scrollable's left (e.g. by the file-tree
    // column); its content width is the sliver's cross-axis extent, so the
    // missing width is the left inset. Anchor X to the diff's true left edge.
    final double diffLeft =
        vpTopLeft.dx + math.max(0, vpSize.width - ro.contentCrossAxisExtent);
    final double diffWidth =
        ro.contentCrossAxisExtent > 0 ? ro.contentCrossAxisExtent : vpSize.width;
    // Affordances live below the pinned tab strip and within the diff column.
    final Rect rect = Rect.fromLTWH(
      diffLeft,
      vpTopLeft.dy + topInset,
      diffWidth,
      math.max(0, vpSize.height - topInset),
    );

    double screenYOfLine(int file, int line) =>
        vpTopLeft.dy + preceding + _document.offsetOfLine(file, line) - pixels;
    // Wrap: x is the column within its sub-row (col % cols). Scroll: subtract
    // the live horizontal offset. The colsPerRow sentinel makes `col % cols ==
    // col` in scroll mode, and hScroll is 0 in wrap mode, so one formula serves
    // both.
    double screenXOfCol(int file, int col) =>
        diffLeft + ro.gutterWidthOf(file) + kDiffCodePadLeft +
        (col % cols) * adv -
        hScroll;
    bool visible(double y) => y + kDiffLineHeight > rect.top && y < rect.bottom;
    (int, int)? rowAtGlobalY(double gy) {
      final double docOffset = (gy - vpTopLeft.dy) + pixels - preceding;
      if (docOffset < 0 || docOffset >= _document.totalExtent) {
        return null;
      }
      final f = _document.fileAtOffset(docOffset);
      if (!_document.isExpanded(f)) {
        return null;
      }
      final yLocal = docOffset - _document.offsetOfFile(f);
      if (yLocal < _document.headerHeight) {
        return null;
      }
      return (f, _document.lineAtFileLocalY(f, yLocal));
    }

    final children = <Widget>[
      // Avatars + gutter pill: rebuilt only when the hovered row changes.
      Positioned.fill(
        child: ValueListenableBuilder<(int, int)?>(
          valueListenable: _hoverRow,
          builder: (_, hover, _) {
            final items = <Widget>[];
            // Commenter avatars down the left rail (the hovered row shows the
            // pill instead).
            for (final slot in _slots) {
              if (slot.kind != DiffSlotKind.comment) {
                continue;
              }
              final thread = _threadBySlotKey[slot.key];
              final anchorLine = slot.anchorDisplayLine;
              if (thread == null) {
                continue;
              }
              if (hover?.$1 == slot.fileIndex && hover?.$2 == anchorLine) {
                continue;
              }
              final y = screenYOfLine(slot.fileIndex, anchorLine);
              if (!visible(y)) {
                continue;
              }
              final author =
                  thread.entries.isNotEmpty ? thread.entries.first : null;
              items.add(Positioned(
                left: rect.left + 3,
                top: y + (kDiffLineHeight - 18) / 2,
                width: 18,
                height: 18,
                child: GestureDetector(
                  onTap: () => _focusThread(thread.id),
                  child: GitHubUserAvatar(
                    login: author?.author ?? '?',
                    avatarUrl: author?.authorAvatarUrl,
                    size: 18,
                    showHoverCard: false,
                  ),
                ),
              ));
            }
            // Gutter "+" pill. It sits at the hovered row, and while dragging
            // it tracks the moving end of the range so it follows the cursor.
            final pillDrag = _pillDrag;
            final (int, int)? pillRow =
                pillDrag != null ? (pillDrag.$1, pillDrag.$3) : hover;
            if (pillRow != null && _activeComposer == null) {
              final y = screenYOfLine(pillRow.$1, pillRow.$2);
              if (visible(y)) {
                items.add(Positioned(
                  // Stable key so the pill's gesture recognizer survives the
                  // overlay rebuilds we trigger on every drag step — without it
                  // a shifting child list could swap the element and cancel the
                  // in-flight drag.
                  key: const ValueKey('diff-gutter-add-pill'),
                  left: rect.left + 1,
                  top: y + (kDiffLineHeight - 20) / 2,
                  child: _GutterAddPill(
                    dragging: pillDrag != null,
                    onTap: () => _openComposerForRange(
                        pillRow.$1, pillRow.$2, pillRow.$2, null, null,
                        PrInlineThreadKind.comment),
                    onDragStart: () {
                      setState(
                          () => _pillDrag = (pillRow.$1, pillRow.$2, pillRow.$2));
                      _markReviewOverlayDirty();
                    },
                    onDragUpdate: (globalY) {
                      final r = rowAtGlobalY(globalY);
                      final drag = _pillDrag;
                      if (r != null &&
                          drag != null &&
                          r.$1 == drag.$1 &&
                          r.$2 != drag.$3) {
                        setState(() => _pillDrag = (drag.$1, drag.$2, r.$2));
                        // Reposition the pill (in the overlay) to the new row;
                        // setState alone only repaints the sliver highlight.
                        _markReviewOverlayDirty();
                      }
                    },
                    onDragEnd: () {
                      final drag = _pillDrag;
                      setState(() => _pillDrag = null);
                      _markReviewOverlayDirty();
                      if (drag != null) {
                        _openComposerForRange(drag.$1, drag.$2, drag.$3, null,
                            null, PrInlineThreadKind.comment);
                      }
                    },
                  ),
                ));
              }
            }
            return Stack(clipBehavior: Clip.none, children: items);
          },
        ),
      ),
      // Pass-through hover tracker, painted ABOVE the pill so the opaque pill
      // never knocks it out of the mouse-tracker's hit path (translucent →
      // taps/drags/scroll still fall through to the pill and diff beneath). If
      // it sat below the pill, reaching the pill would hit-test the pill first,
      // drop this region from the path, fire onExit, clear _hoverRow and remove
      // the pill — flicker, and any in-flight drag would be cancelled with it.
      // It updates a ValueNotifier rather than setState, so the region is never
      // itself rebuilt on hover (a rebuild would re-fire enter/exit too).
      Positioned.fromRect(
        rect: rect,
        child: MouseRegion(
          key: _hoverRegionKey,
          opaque: false,
          hitTestBehavior: HitTestBehavior.translucent,
          // Keep the grabbing cursor for the whole drag — the pointer can drift
          // off the small pill as the range grows. Otherwise defer so the code
          // area keeps its normal cursor.
          cursor: _pillDrag != null
              ? SystemMouseCursors.grabbing
              : MouseCursor.defer,
          onHover: (e) {
            if (_pillDrag != null) {
              return; // keep the pill anchored at the drag origin
            }
            final row = rowAtGlobalY(e.position.dy);
            if (row != _hoverRow.value) {
              _hoverRow.value = row;
            }
          },
          onExit: (_) {
            if (_pillDrag == null) {
              _hoverRow.value = null;
            }
          },
        ),
      ),
    ];

    // Floating selection toolbar (comment / suggest / react), anchored below
    // the selection's last line.
    final sel = ro.selectionRange();
    if (sel != null && _activeComposer == null) {
      final single = sel.startLine == sel.endLine;
      // Anchor below the last wrapped sub-row of the selection's end line.
      final int endRows = _document.visualRowsOf(sel.file, sel.endLine);
      final double yBot = screenYOfLine(sel.file, sel.endLine) +
          (endRows - 1) * kDiffLineHeight;
      final double selLeft = screenXOfCol(sel.file, single ? sel.startCol : 0);
      const double toolbarWidth = 132;
      const double toolbarHeight = 44;
      if (yBot + kDiffLineHeight > rect.top && yBot < rect.bottom) {
        children.add(Positioned(
          left: math.max(
              rect.left, math.min(selLeft, rect.right - toolbarWidth)),
          top: math.max(
              rect.top,
              math.min(yBot + kDiffLineHeight + 6, rect.bottom - toolbarHeight)),
          child: PrSelectionToolbar(
            onComment: () =>
                _openComposerFromSelection(PrInlineThreadKind.comment),
            onSuggest: () =>
                _openComposerFromSelection(PrInlineThreadKind.suggestion),
            onReact: () => _reactFromSelection(Rect.fromLTWH(
                selLeft, yBot, toolbarWidth, kDiffLineHeight)),
          ),
        ));
      }
    }

    return Positioned.fill(
      child: Stack(clipBehavior: Clip.none, children: children),
    );
  }

  /// Opens an emoji menu at the selection and posts a one-emoji comment thread
  /// (a lightweight reaction on the code, since GitHub reactions attach to
  /// existing comments, not arbitrary ranges).
  Future<void> _reactFromSelection(Rect anchor) async {
    final ro = _sliver;
    final ctl = widget.inlineCommentsController;
    final r = ro?.selectionRange();
    if (ro == null || ctl == null || r == null) {
      return;
    }
    final info = _resolveAnchor(r.file, r.startLine, r.endLine);
    if (info == null) {
      return;
    }
    final picked = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          anchor.left, anchor.bottom + 6, anchor.left + 1, anchor.bottom + 7),
      items: [
        for (final g in ReactionGroup.supportedReactions)
          PopupMenuItem<String>(
            value: g.emoji,
            height: 38,
            child: Text(g.emoji, style: const TextStyle(fontSize: 20)),
          ),
      ],
    );
    if (picked == null || !mounted) {
      return;
    }
    ro.clearSelection();
    final single = r.startLine == r.endLine;
    ctl.create(
      filePath: _document.files[r.file].filename,
      line: info.lineNoStart,
      lineEnd: info.lineNoEnd,
      startCol: single ? r.startCol : null,
      endCol: single ? r.endCol : null,
      side: info.side,
      kind: PrInlineThreadKind.comment,
      originalCode: info.originalCode,
      suggestedCode: '',
      authorBody: picked,
    );
  }

  /// Resolves the side, GitHub line numbers and original code for display rows
  /// `[lo, hi]` of [file], or null when they aren't both code rows.
  ({String side, int lineNoStart, int lineNoEnd, String originalCode})?
      _resolveAnchor(int file, int lo, int hi) {
    final raw = _document.structureOf(file);
    if (raw == null) {
      return null;
    }
    final rStart = _document.rawIndexOf(file, lo);
    final rEnd = _document.rawIndexOf(file, hi);
    if (!_isCodeRow(raw, rStart) || !_isCodeRow(raw, rEnd)) {
      return null;
    }
    // GitHub multi-line comments must be on a single side. Anchor to the end
    // row's side; if the start row has no line number on that side (a
    // mixed-kind selection — e.g. start is an addition but end is a deletion),
    // collapse to a single-line anchor on the end row rather than post a bad
    // reference.
    final side = raw.kindAt(rEnd) == DiffLineKind.deletion ? 'LEFT' : 'RIGHT';
    int? numOn(int r) => side == 'LEFT' ? raw.oldLines[r] : raw.newLines[r];
    final lineNoEnd = numOn(rEnd);
    var startLo = lo;
    var lineNoStart = numOn(rStart);
    if (lineNoStart == null) {
      startLo = hi;
      lineNoStart = lineNoEnd;
    }
    if (lineNoStart == null || lineNoEnd == null) {
      return null;
    }
    final buf = StringBuffer();
    for (var d = startLo; d <= hi; d++) {
      final r = _document.rawIndexOf(file, d);
      if (!_isCodeRow(raw, r)) {
        continue;
      }
      if (buf.isNotEmpty) {
        buf.write('\n');
      }
      buf.write(raw.contents[r]);
    }
    return (
      side: side,
      lineNoStart: lineNoStart,
      lineNoEnd: lineNoEnd,
      originalCode: buf.toString(),
    );
  }

  void _toggleViewed(int index) {
    final path = _document.files[index].filename;
    final nowViewed = !_viewed.contains(path);
    setState(() {
      if (nowViewed) {
        _viewed.add(path);
      } else {
        _viewed.remove(path);
      }
      // Marking a file viewed collapses its sliver immediately; un-viewing
      // expands it again (and parses its structure if it wasn't loaded yet).
      _document.setExpanded(index, expanded: !nowViewed);
      if (!nowViewed) {
        _store.ensureStructure(index);
      }
      _revision++;
    });
    widget.onToggleViewed?.call(path: path, viewed: nowViewed);
  }

  /// Expands the gap row at [rawIndex] in file [file] by fetching the file
  /// content and splicing the hidden context lines in. Handles both bounded
  /// ("Show N lines") and trailing ("Show end of file") gaps.
  Future<void> _expandGap(int file, int rawIndex) async {
    final fetch = widget.fetchFileContent;
    if (fetch == null) {
      return;
    }
    final key = (file, rawIndex);
    if (_expandingGaps.contains(key)) {
      return;
    }
    final raw = _document.structureOf(file);
    if (raw == null || rawIndex < 0 || rawIndex >= raw.length) {
      return;
    }
    if (raw.kindAt(rawIndex) != DiffLineKind.expandGap) {
      return;
    }
    final newStart = raw.newLines[rawIndex];
    final oldStart = raw.oldLines[rawIndex];
    final newEnd = raw.gapNewEnds[rawIndex];
    if (newStart == null || oldStart == null) {
      return;
    }

    _expandingGaps.add(key);
    String content;
    try {
      content = await fetch(_document.files[file].filename);
    } catch (_) {
      _expandingGaps.remove(key);
      return;
    }
    if (!mounted) {
      return;
    }
    _expandingGaps.remove(key);

    final fileLines = content.split('\n');
    final toEof = newEnd == kEofGapSentinel;
    final fromIdx = (newStart - 1).clamp(0, fileLines.length);
    final toIdx =
        toEof ? fileLines.length : (newEnd ?? newStart).clamp(0, fileLines.length);
    final slice = toIdx > fromIdx ? fileLines.sublist(fromIdx, toIdx) : const <String>[];

    final spliced = _spliceGap(
      raw,
      rawIndex,
      slice,
      oldStart: oldStart,
      newStart: newStart,
    );
    _document.setStructure(file, spliced, augment: false);
    _store.spliceTokens(file, rawIndex, slice.length);
    // Line indices shifted — drop the paragraph cache so stale rows can't be
    // reused, then relayout.
    final ro = _sliverKey.currentContext?.findRenderObject();
    if (ro is RenderUnifiedDiffSliver) {
      ro.clearLineCache();
    }
    setState(() => _revision++);
  }

  /// Returns a copy of [raw] with the single gap row at [gapIndex] replaced by
  /// [slice] as context rows numbered from [oldStart]/[newStart].
  DiffRawLines _spliceGap(
    DiffRawLines raw,
    int gapIndex,
    List<String> slice, {
    required int oldStart,
    required int newStart,
  }) {
    final kinds = List<int>.from(raw.kinds)..removeAt(gapIndex);
    final contents = List<String>.from(raw.contents)..removeAt(gapIndex);
    final oldLines = List<int?>.from(raw.oldLines)..removeAt(gapIndex);
    final newLines = List<int?>.from(raw.newLines)..removeAt(gapIndex);
    final hunkHeaders = List<String?>.from(raw.hunkHeaders)..removeAt(gapIndex);
    final gapOldEnds = List<int?>.from(raw.gapOldEnds)..removeAt(gapIndex);
    final gapNewEnds = List<int?>.from(raw.gapNewEnds)..removeAt(gapIndex);

    for (var k = 0; k < slice.length; k++) {
      kinds.insert(gapIndex + k, DiffLineKind.context.index);
      contents.insert(gapIndex + k, slice[k]);
      oldLines.insert(gapIndex + k, oldStart + k);
      newLines.insert(gapIndex + k, newStart + k);
      hunkHeaders.insert(gapIndex + k, null);
      gapOldEnds.insert(gapIndex + k, null);
      gapNewEnds.insert(gapIndex + k, null);
    }

    var maxChars = raw.maxLineChars;
    for (final line in slice) {
      if (line.length > maxChars) {
        maxChars = line.length;
      }
    }
    return DiffRawLines(
      kinds: kinds,
      contents: contents,
      oldLines: oldLines,
      newLines: newLines,
      hunkHeaders: hunkHeaders,
      gapOldEnds: gapOldEnds,
      gapNewEnds: gapNewEnds,
      maxLineChars: maxChars,
    );
  }

  /// Copies the active diff text selection (raw source, assembled from the
  /// document model) to the clipboard. Returns true if something was copied.
  bool _copySelection() {
    final ro = _sliverKey.currentContext?.findRenderObject();
    if (ro is! RenderUnifiedDiffSliver) {
      return false;
    }
    final text = ro.copySelectionText();
    if (text == null) {
      return false;
    }
    Clipboard.setData(ClipboardData(text: text));
    return true;
  }

  /// Clears the active diff text selection (Escape key). Returns true if there
  /// was a selection to clear.
  bool _clearSelection() {
    final ro = _sliver;
    if (ro == null || !ro.hasSelection) {
      return false;
    }
    ro.clearSelection();
    return true;
  }

  /// Scrolls the host scrollable so file [index]'s header sits at the top.
  Future<void> jumpToFile(int index) async {
    if (index < 0 || index >= _document.fileCount) {
      return;
    }
    final renderObject = _sliverKey.currentContext?.findRenderObject();
    final controller = PrimaryScrollController.maybeOf(context);
    if (renderObject is! RenderUnifiedDiffSliver ||
        controller == null ||
        !controller.hasClients) {
      return;
    }
    final target = renderObject
        .scrollOffsetForFile(index)
        .clamp(0.0, controller.position.maxScrollExtent);
    await controller.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  TextStyle _baseStyle(String codeFont) {
    final theme = Theme.of(context);
    return AppFonts.codeDynamic(
      codeFont,
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 12.5,
        height: 1.5,
        color: context.theme.colors.foreground,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final codeFont = ref.watch(codeFontFamilyProvider);
    final overflowMode = ref.watch(diffOverflowModeProvider);
    _ensureReviewOverlay();
    _ensureHScrollbarOverlay();
    // Rebuild the slot list (recomputing anchored threads) whenever drafts or
    // replies change.
    if (widget.inlineCommentsController != null) {
      ref.listen(
        prInlineCommentsControllerProvider(widget.prNumber),
        (_, _) {
          if (mounted) {
            setState(() => _revision++);
          }
        },
      );
    }
    final colors = context.theme.colors;
    final slots = _ensureSlots();

    var searchFile = -1;
    var searchRawIndex = -1;
    if (_search.totalMatches > 0 &&
        _search.currentMatchIdx >= 1 &&
        _search.currentMatchIdx <= _search.matchLocations.length) {
      final m = _search.matchLocations[_search.currentMatchIdx - 1];
      searchFile = m.fileIndex;
      searchRawIndex = m.lineIndex;
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const commentYellow = Color(0xFFFFD33D);
    final config = UnifiedDiffPaintConfig(
      brightness: Theme.of(context).brightness,
      baseStyle: _baseStyle(codeFont),
      gutterBgColor: colors.background,
      gutterBorderColor: colors.border,
      expandGapBgColor: colors.background,
      expandGapBorderColor: colors.border,
      expandGapTextColor: colors.mutedForeground,
      commentHighlightColor:
          commentYellow.withValues(alpha: isDark ? 0.16 : 0.28),
      commentHighlightActiveColor:
          commentYellow.withValues(alpha: isDark ? 0.32 : 0.46),
      revision: _revision,
      topInset: StickyHeaderInset.of(context),
      overflowMode: overflowMode,
      searchFile: searchFile,
      searchRawIndex: searchRawIndex,
      splitMode: widget.splitView,
    );

    final delegate = SliverChildBuilderDelegate(
      (context, index) {
        if (index >= slots.length) {
          return null;
        }
        final slot = slots[index];
        switch (slot.kind) {
          case DiffSlotKind.header:
            final file = _document.files[slot.fileIndex];
            return FastFileHeader(
              key: ValueKey(slot.key),
              file: file,
              expanded: _document.isExpanded(slot.fileIndex),
              isViewed: _viewed.contains(file.filename),
              onToggleExpanded: () => _toggleExpanded(slot.fileIndex),
              onToggleViewed: widget.onToggleViewed != null
                  ? () => _toggleViewed(slot.fileIndex)
                  : null,
              onAddFileComment: widget.inlineCommentsController != null
                  ? () => _openFileComment(slot.fileIndex)
                  : null,
            );
          case DiffSlotKind.gap:
            return _GapRow(
              key: ValueKey(slot.key),
              label: _gapLabel(slot.fileIndex, slot.rawIndex),
              icon: _gapIcon(slot.fileIndex, slot.rawIndex),
              enabled: widget.fetchFileContent != null,
              onTap: () => _expandGap(slot.fileIndex, slot.rawIndex),
            );
          case DiffSlotKind.comment:
            final thread = _threadBySlotKey[slot.key];
            final ctl = widget.inlineCommentsController;
            if (thread == null || ctl == null) {
              return const SizedBox.shrink();
            }
            // The diff sliver has no ambient Material (forui shell), so wrap —
            // the thread's reply TextField and ink need one.
            return Material(
              key: ValueKey(slot.key),
              type: MaterialType.transparency,
              child: MeasuredInlineThread(
                thread: thread,
                controller: ctl,
                onMeasured: (h) => _onCommentMeasured(thread.id, h),
              ),
            );
          case DiffSlotKind.composer:
            final req = _activeComposer;
            final ctl = widget.inlineCommentsController;
            if (req == null ||
                ctl == null ||
                req.fileIndex != slot.fileIndex) {
              return const SizedBox.shrink();
            }
            // No ambient Material in the forui shell — wrap so the composer's
            // TextField, ink and buttons have one. Height is measured and fed
            // back so the document reserves the exact gap (same path as a
            // thread block).
            return Material(
              key: ValueKey(slot.key),
              type: MaterialType.transparency,
              child: _MeasuredHeight(
                onMeasured: (h) => _onCommentMeasured(slot.key, h),
                child: req.kind == PrInlineThreadKind.suggestion
                    ? SuggestionComposer(
                        originalCode: req.originalCode,
                        baseStyle: _baseStyle(codeFont),
                        onSubmit: (suggested, comment) =>
                            _submitSuggestion(req, suggested, comment),
                        onCancel: _cancelComposer,
                      )
                    : PrCommentComposer(
                        onSubmit: (body) => _submitComment(req, body),
                        onCancel: _cancelComposer,
                      ),
              ),
            );
        }
      },
      childCount: slots.length,
      addAutomaticKeepAlives: false,
      findChildIndexCallback: (key) =>
          _slotIndexByKey[(key as ValueKey).value],
    );

    return UnifiedDiffSliver(
      key: _sliverKey,
      delegate: delegate,
      document: _document,
      store: _store,
      config: config,
      slots: slots,
      commentHighlights: _computeCommentHighlights(),
      onGutterTap:
          widget.inlineCommentsController != null ? _addLineComment : null,
      onSelectionChanged: _onSelectionChanged,
      onLayoutModeChanged: _onLayoutModeChanged,
    );
  }

  /// A width/mode change moved per-line offsets, so rebuild the slot list (and
  /// thus every gap / comment / composer offset) against the new geometry.
  void _onLayoutModeChanged() {
    if (mounted) {
      setState(() => _revision++);
    }
  }
}

/// A clickable "Show N lines" / "Show end of file" expand affordance, rendered
/// as a real widget so it gets native hover + cursor feedback.
class _GapRow extends StatefulWidget {
  const _GapRow({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_GapRow> createState() => _GapRowState();
}

class _GapRowState extends State<_GapRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final tokens = context.designSystem;
    final hoverBg = tokens?.bgPrimaryHover ?? colors.secondary;
    final theme = Theme.of(context);
    return MouseRegion(
      cursor:
          widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          height: kDiffLineHeight,
          padding: const EdgeInsets.only(left: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _hovered ? hoverBg : colors.background,
            border: Border(
              top: BorderSide(color: colors.border, width: 0.5),
              bottom: BorderSide(color: colors.border, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 12,
                color: _hovered
                    ? (tokens?.fgSecondaryHover ?? colors.foreground)
                    : (tokens?.fgTertiary ?? colors.mutedForeground),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _hovered
                      ? (tokens?.textSecondaryHover ?? colors.foreground)
                      : (tokens?.textTertiary ?? colors.mutedForeground),
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An open inline composer request, anchored under display rows
/// `[startDisplayLine, endDisplayLine]` of [fileIndex].
@immutable
class _ComposerRequest {
  const _ComposerRequest({
    required this.fileIndex,
    required this.anchorDisplayLine,
    required this.startDisplayLine,
    required this.endDisplayLine,
    required this.startCol,
    required this.endCol,
    required this.side,
    required this.lineNoStart,
    required this.lineNoEnd,
    required this.originalCode,
    required this.kind,
  });

  final int fileIndex;
  final int anchorDisplayLine;
  final int startDisplayLine;
  final int endDisplayLine;
  final int? startCol;
  final int? endCol;
  final String side;
  final int lineNoStart;
  final int lineNoEnd;
  final String originalCode;
  final PrInlineThreadKind kind;
}

/// Reports its child's laid-out height once per frame via [onMeasured], so the
/// document can reserve an exact gap for an inline composer (mirrors
/// [MeasuredInlineThread] for non-thread children).
class _MeasuredHeight extends StatefulWidget {
  const _MeasuredHeight({required this.child, required this.onMeasured});
  final Widget child;
  final ValueChanged<double> onMeasured;

  @override
  State<_MeasuredHeight> createState() => _MeasuredHeightState();
}

class _MeasuredHeightState extends State<_MeasuredHeight> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _MeasuredHeight oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        widget.onMeasured(box.size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// A thin draggable horizontal scrollbar for the diff's code area (scroll
/// mode). Stateless about the offset — it reads [offset] each build (the
/// overlay rebuilds after every paint) and reports pans via [onPan]; drag delta
/// is accumulated from the drag's start offset to avoid stale-value jitter.
class _DiffHScrollbar extends StatefulWidget {
  const _DiffHScrollbar({
    required this.offset,
    required this.maxOffset,
    required this.viewportWidth,
    required this.onPan,
  });

  /// Current horizontal offset.
  final double offset;

  /// Maximum horizontal offset (content width − viewport width).
  final double maxOffset;

  /// Visible code width (the scrollbar track width).
  final double viewportWidth;

  /// Called with the new absolute offset as the thumb is dragged.
  final ValueChanged<double> onPan;

  @override
  State<_DiffHScrollbar> createState() => _DiffHScrollbarState();
}

class _DiffHScrollbarState extends State<_DiffHScrollbar> {
  double _dragStartOffset = 0;
  double _dragAccum = 0;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final double content = widget.viewportWidth + widget.maxOffset;
    final double thumbW = content <= 0
        ? widget.viewportWidth
        : (widget.viewportWidth / content * widget.viewportWidth)
            .clamp(28.0, widget.viewportWidth);
    final double travel = widget.viewportWidth - thumbW;
    final double thumbLeft = widget.maxOffset <= 0
        ? 0
        : (widget.offset / widget.maxOffset).clamp(0.0, 1.0) * travel;
    final double gain = travel <= 0 ? 0 : widget.maxOffset / travel;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragStartOffset = widget.offset;
          _dragAccum = 0;
        },
        onHorizontalDragUpdate: (d) {
          _dragAccum += d.delta.dx;
          widget.onPan(_dragStartOffset + _dragAccum * gain);
        },
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(left: thumbLeft),
            child: Container(
              width: thumbW,
              height: _hovered ? 8 : 6,
              decoration: BoxDecoration(
                color: colors.mutedForeground
                    .withValues(alpha: _hovered ? 0.6 : 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The circular "+" affordance painted in the gutter rail on row hover. Tapping
/// starts a single-line comment; dragging vertically selects a row range. The
/// cursor reads as an open hand (grab) on hover and a closed hand (grabbing)
/// while a range drag is in progress.
class _GutterAddPill extends StatelessWidget {
  const _GutterAddPill({
    required this.dragging,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final bool dragging;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final ValueChanged<double> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final primary = context.theme.colors.primary;
    // The hover-tracker MouseRegion is painted above this pill (translucent), so
    // a MouseRegion here can no longer steal hover from it or flicker the pill —
    // it's free to set the grab/grabbing cursor. opaque hit-testing makes the
    // whole 20×20 pill — not just the icon glyph — catch taps and the vertical
    // drag-to-select-range; a bare Container defers hit testing to its child (a
    // DecoratedBox doesn't hit-test itself), so without it the pill is barely
    // grabbable and a drag can't start.
    return MouseRegion(
      cursor: dragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onVerticalDragStart: (_) => onDragStart(),
        onVerticalDragUpdate: (d) => onDragUpdate(d.globalPosition.dy),
        onVerticalDragEnd: (_) => onDragEnd(),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: primary,
            borderRadius: BorderRadius.circular(6),
            boxShadow: AppShadows.soft,
          ),
          child: Icon(
            LucideIcons.plus,
            size: 14,
            color: context.theme.colors.primaryForeground,
          ),
        ),
      ),
    );
  }
}
